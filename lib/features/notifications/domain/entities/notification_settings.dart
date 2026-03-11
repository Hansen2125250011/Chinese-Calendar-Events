class NotificationSettings {
  final bool enabled;
  final int daysBefore; // e.g. 1 day before, 3 days before
  final String reminderTime; // "09:00"

  const NotificationSettings({
    this.enabled = true,
    this.daysBefore = 1,
    this.reminderTime = "09:00",
  });
}
