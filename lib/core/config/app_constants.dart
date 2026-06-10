/// Application-wide constants and configuration values.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'EduNoteAI';
  static const String appVersion = '1.0.0';

  // API Keys (TODO: Move to .env in production)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Hive Box Names
  static const String notebooksBox = 'notebooks';
  static const String foldersBox = 'folders';
  static const String tagsBox = 'tags';
  static const String settingsBox = 'settings';
  static const String strokesBox = 'strokes';
  static const String pagesBox = 'pages';
  static const String filesBox = 'files';

  // Canvas Defaults
  static const double defaultStrokeWidth = 2.0;
  static const double minStrokeWidth = 0.5;
  static const double maxStrokeWidth = 12.0;
  static const double highlighterOpacity = 0.35;
  static const int undoHistoryLimit = 50;
  static const int autoSaveIntervalMs = 3000;

  // Folder Hierarchy
  static const int maxFolderDepth = 3;

  // Performance
  static const int pagePreloadCount = 2;
  static const int maxCanvasPointsBeforeSimplify = 5000;

  // Freemium Limits (free tier)
  static const int freeMonthlyFileUploads = 3;
  static const int freeAiSummariesPerMonth = 1;
  static const int freeMaxFileSizeMb = 20;
  static const int proMaxFileSizeMb = 200;
}
