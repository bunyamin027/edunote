import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';


import '../../presentation/canvas/engine/page_model.dart';

/// Service for persisting canvas pages to Hive.
class CanvasStorageService {
  final Box _pagesBox;
  final _uuid = const Uuid();

  CanvasStorageService(this._pagesBox);

  /// Key prefix for pages: "pages_{notebookId}"
  String _pagesKey(String notebookId) => 'pages_$notebookId';

  /// Load all pages for a notebook.
  List<PageModel> loadPages(String notebookId) {
    final key = _pagesKey(notebookId);
    final data = _pagesBox.get(key);

    if (data == null) {
      // Create default first page
      final firstPage = _createPage(1);
      savePages(notebookId, [firstPage]);
      return [firstPage];
    }

    final list = (data as List).cast<Map>();
    final pages = list
        .map((e) => PageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    if (pages.isEmpty) {
      final firstPage = _createPage(1);
      savePages(notebookId, [firstPage]);
      return [firstPage];
    }

    return pages;
  }

  /// Save all pages for a notebook.
  Future<void> savePages(String notebookId, List<PageModel> pages) async {
    final key = _pagesKey(notebookId);
    final data = pages.map((p) => p.toJson()).toList();
    await _pagesBox.put(key, data);
  }

  /// Save a single page (update in place).
  Future<void> savePage(String notebookId, PageModel page) async {
    final pages = loadPages(notebookId);
    final index = pages.indexWhere((p) => p.id == page.id);

    if (index >= 0) {
      pages[index] = page;
    } else {
      pages.add(page);
    }

    await savePages(notebookId, pages);
  }

  /// Add a new page to a notebook.
  Future<PageModel> addPage(String notebookId) async {
    final pages = loadPages(notebookId);
    final newPageNumber = pages.length + 1;
    final newPage = _createPage(newPageNumber);

    pages.add(newPage);
    await savePages(notebookId, pages);

    return newPage;
  }

  /// Delete a page from a notebook.
  Future<void> deletePage(String notebookId, String pageId) async {
    final pages = loadPages(notebookId);
    pages.removeWhere((p) => p.id == pageId);

    // Re-number remaining pages
    for (int i = 0; i < pages.length; i++) {
      pages[i] = pages[i].copyWith(pageNumber: i + 1);
    }

    await savePages(notebookId, pages);
  }

  /// Delete all pages for a notebook.
  Future<void> deleteNotebookPages(String notebookId) async {
    final key = _pagesKey(notebookId);
    await _pagesBox.delete(key);
  }

  /// Create a blank page.
  PageModel _createPage(int pageNumber) {
    final now = DateTime.now();
    return PageModel(
      id: _uuid.v4(),
      pageNumber: pageNumber,
      createdAt: now,
      updatedAt: now,
    );
  }
}
