// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// A widget that displays dictionary content from Takoboto for Japanese words.
///
/// This viewer fetches definitions from the Takoboto online dictionary and
/// renders them in a styled popup dialog. It bridges the native app UI with
/// external web content, injecting theme colors for a seamless integration.
///
/// * [text]: The Japanese word or phrase to look up.
class TakobotoViewer extends StatefulWidget {
  /// The Japanese text to look up.
  final String text;

  /// Creates a Takoboto viewer widget.
  const TakobotoViewer({super.key, required this.text});

  /// Displays a modal dialog containing the Takoboto definition for [word].
  ///
  /// This is a convenience method for showing the viewer as a popup without
  /// manually constructing the dialog and constraints.
  static void showPopup(BuildContext context, String word) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: TakobotoViewer(text: word),
        ),
      ),
    );
  }

  @override
  State<TakobotoViewer> createState() => _TakobotoViewerState();
}

/// Internal state for [TakobotoViewer] managing content fetching and animations.
///
/// Handles the async HTTP request to Takoboto's AJAX endpoint and manages a
/// loading animation while content is being retrieved.
class _TakobotoViewerState extends State<TakobotoViewer>
    with SingleTickerProviderStateMixin {
  /// Future that resolves to the HTML content from Takoboto.
  late Future<String> _htmlFuture;

  /// Animation controller for the rotating loading indicator.
  late AnimationController _loadingController;

  /// Base URL for fetching HTML content via AJAX.
  static const String _ajaxBaseUrl = 'https://takoboto.jp/?ajax=1&ajaxq=';

  /// Base URL for Takoboto word pages.
  static const String _pageBaseUrl = 'https://takoboto.jp/?q=';

  /// Initializes the loading animation and triggers the initial content fetch.
  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _fetchHtml();
  }

  /// Refetches content when the search text changes.
  @override
  void didUpdateWidget(TakobotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _fetchHtml();
    }
  }

  /// Cleans up the animation controller to prevent memory leaks.
  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  /// Triggers a new fetch request and updates the future.
  void _fetchHtml() {
    _htmlFuture = _fetchHtmlContent();
  }

  /// Fetches HTML content from Takoboto's AJAX endpoint.
  ///
  /// Returns the decoded UTF-8 response body, which contains Japanese text
  /// and HTML markup for the word definition.
  Future<String> _fetchHtmlContent() async {
    final url = '$_ajaxBaseUrl${Uri.encodeComponent(widget.text)}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Decode as UTF-8 to properly handle Japanese characters
      return utf8.decode(response.bodyBytes);
    } else {
      throw HttpException(
        'Failed to load content: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Builds the viewer UI based on the current fetch state.
  ///
  /// Shows a loading spinner while fetching, an error message with retry
  /// button on failure, or the styled HTML content on success.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(context);
        }

        if (snapshot.hasError) {
          return _buildError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return _buildHtmlContent(context, snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Builds a centered loading indicator with a rotating gradient spinner.
  Widget _buildLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _loadingController,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(100),
                    width: 3,
                  ),
                  gradient: SweepGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(50),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an error display with the error message and a retry button.
  Widget _buildError(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _fetchHtml();
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds the HTML content view with themed styling applied.
  ///
  /// Replaces Takoboto's default orange accent color with the app's primary
  /// color and removes underlines from links for a cleaner appearance.
  Widget _buildHtmlContent(BuildContext context, String html) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryHex =
        '#${colorScheme.primary.toARGB32().toRadixString(16).substring(2)}';
    final mutedPrimaryColor = Color.alphaBlend(
      colorScheme.onSurface.withAlpha(128),
      colorScheme.primary,
    );
    final mutedPrimaryHex =
        '#${mutedPrimaryColor.toARGB32().toRadixString(16).substring(2)}';
    final mutedColor = Color.alphaBlend(
      colorScheme.onSurface.withAlpha(128),
      colorScheme.surface,
    );
    final mutedHex = '#${mutedColor.toARGB32().toRadixString(16).substring(2)}';

    // Replace Takoboto's orange color with our primary color, and light grey with muted onSurface
    final styledHtml = html
        .replaceAll('#FF6020', primaryHex)
        .replaceAll('#A0A0A0', mutedPrimaryHex)
        .replaceAll('#C0C0C0', mutedHex)
        .replaceAll('#606060', mutedHex);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 70.0),
                child: Text(
                  'Data from takoboto.jp',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(150),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              HtmlWidget(
                styledHtml,
                textStyle: TextStyle(color: colorScheme.onSurface),
                customStylesBuilder: (element) {
                  // Remove underline from links
                  if (element.localName == 'a') {
                    return {'text-decoration': 'none'};
                  }
                  return null;
                },
                onTapUrl: (url) {
                  _openInBrowser();
                  return true;
                },
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: _openInBrowser,
                tooltip: 'Open in Browser',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the current word's Takoboto page in the external browser.
  void _openInBrowser() {
    final url = '$_pageBaseUrl${Uri.encodeComponent(widget.text)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// A simple exception class for HTTP request failures.
///
/// Captures both the error message and HTTP status code to provide meaningful
/// feedback when dictionary lookups fail.
class HttpException implements Exception {
  /// The human-readable error message describing what went wrong.
  final String message;

  /// The HTTP status code returned by the server.
  final int statusCode;

  /// Creates an HTTP exception.
  HttpException(this.message, this.statusCode);

  @override
  String toString() => message;
}
