class TraditionalEvent {
  final String id;
  final String
      name; // Stored as JSON string in DB, but let's keep it string here and parse in UI or Repo?
  // Ideally repo parses it. But keeping it string is easier for Drift compatibility if we mapped 1:1.
  // Let's make this domain entity smart or have localized fields.
  final Map<String, dynamic> localizedNames;
  final Map<String, dynamic> localizedDescriptions;
  final int lunarMonth;
  final int lunarDay;
  final bool isMajor;
  final bool notificationsEnabled;

  const TraditionalEvent({
    required this.id,
    required this.name, // Fallback or raw JSON
    required this.localizedNames,
    required this.localizedDescriptions,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isMajor,
    this.notificationsEnabled = true,
  });

  String getName(String languageCode) {
    return localizedNames[languageCode] ?? localizedNames['en'] ?? name;
  }

  String getDescription(String languageCode) {
    return localizedDescriptions[languageCode] ??
        localizedDescriptions['en'] ??
        '';
  }
}
