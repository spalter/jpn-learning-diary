import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// A widget that displays Takoboto dictionary content for a Japanese word.
///
/// Shows a popup dialog with the word's definition fetched from Takoboto.
/// Handles links within the content by opening new popups for Takoboto links
/// or launching external URLs in the browser.
class TakobotoViewer extends StatefulWidget {
  /// The Japanese text to look up.
  final String text;

  /// Creates a Takoboto viewer widget.
  const TakobotoViewer({super.key, required this.text});

  /// Shows a Takoboto popup dialog for the given word.
  static void showPopup(BuildContext context, String word) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: SingleChildScrollView(child: TakobotoViewer(text: word)),
        ),
      ),
    );
  }

  @override
  State<TakobotoViewer> createState() => _TakobotoViewerState();
}

class _TakobotoViewerState extends State<TakobotoViewer>
    with SingleTickerProviderStateMixin {
  late Future<String> _htmlFuture;
  late AnimationController _loadingController;

  /// Base URL for fetching HTML content via AJAX.
  static const String _ajaxBaseUrl = 'https://takoboto.jp/?ajax=1&ajaxq=';

  /// Base URL for Takoboto word pages.
  static const String _pageBaseUrl = 'https://takoboto.jp/?q=';

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _fetchHtml();
  }

  @override
  void didUpdateWidget(TakobotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _fetchHtml();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _fetchHtml() {
    _htmlFuture = _fetchHtmlContent();
  }

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

  Widget _buildHtmlContent(BuildContext context, String html) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryHex = '#${colorScheme.primary.value.toRadixString(16).substring(2)}';
    
    // Replace Takoboto's orange color with our primary color
    final styledHtml = html.replaceAll('#FF6020', primaryHex);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Data from takoboto.jp',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(150),
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 12),
          HtmlWidget(
            styledHtml,
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
    );
  }

  /// Opens the current word's Takoboto page in the external browser.
  void _openInBrowser() {
    final url = '$_pageBaseUrl${Uri.encodeComponent(widget.text)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// A simple HTTP exception class.
class HttpException implements Exception {
  /// The error message.
  final String message;

  /// The HTTP status code.
  final int statusCode;

  /// Creates an HTTP exception.
  HttpException(this.message, this.statusCode);

  @override
  String toString() => message;
}
