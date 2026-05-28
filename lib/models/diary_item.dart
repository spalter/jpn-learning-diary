// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

/// A common interface for items in the diary to allow a unified timeline display.
abstract class DiaryItem {
  /// Unique identifier of the item.
  int? get id;

  /// The timestamp when this item was added.
  DateTime get dateAdded;
}
