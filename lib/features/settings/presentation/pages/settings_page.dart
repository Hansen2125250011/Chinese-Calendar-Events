import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/core/providers/locale_provider.dart';
import 'package:chinese_calendar/l10n/app_localizations.dart';
import 'package:chinese_calendar/core/providers/theme_provider.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/core/providers/reminder_settings_provider.dart';
import 'package:chinese_calendar/features/notifications/domain/entities/notification_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Language Switcher
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(currentLocale.languageCode)),
            onTap: () => _showLanguageDialog(),
          ),
          const Divider(),

          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(ref.watch(themeProvider) == ThemeMode.system
                ? 'System Default'
                : (ref.watch(themeProvider) == ThemeMode.dark
                    ? 'Dark'
                    : 'Light')),
            leading: const Icon(Icons.brightness_auto),
            onTap: () => _showThemeDialog(),
          ),

          ListTile(
            title: Text(l10n.notifications),
            subtitle: const Text('Check permissions'),
            leading: const Icon(Icons.notifications),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final granted = await ref
                  .read(notificationServiceProvider)
                  .requestPermissions();
              
              if (mounted) {
                messenger.showSnackBar(
                    SnackBar(content: Text('Permissions granted: $granted')));
              }
            },
          ),
          const Divider(),

          // Notification Settings Section
          Consumer(builder: (context, ref, _) {
            final settings = ref.watch(reminderSettingsProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Notification Preferences',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  title: const Text('Traditional Festival Reminders'),
                  subtitle: const Text('Get notified for lunar festivals'),
                  value: settings.enableTraditionalReminders,
                  onChanged: (val) {
                    ref
                        .read(reminderSettingsProvider.notifier)
                        .toggleTraditional(val);
                    _syncNotifications();
                  },
                ),
                ListTile(
                  title: const Text('Default Reminder Delay'),
                  subtitle: Text(settings.defaultDaysBefore == 0
                      ? 'On the day'
                      : '${settings.defaultDaysBefore} days before'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDaysBeforeDialog(),
                ),
                ListTile(
                  title: const Text('Default Reminder Time'),
                  subtitle: Text(settings.defaultTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: settings.defaultTime,
                    );
                    if (time != null) {
                      ref.read(reminderSettingsProvider.notifier).setTime(time);
                      _syncNotifications();
                    }
                  },
                ),
              ],
            );
          }),
          const Divider(),
          // About Removed
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'id':
        return 'Bahasa Indonesia';
      case 'zh':
        return '中文 (Chinese)';
      default:
        return code;
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.language),
        children: [
          _LanguageOption(
            label: 'English',
            code: 'en',
            selected: ref.read(localeProvider).languageCode == 'en',
            onSelect: () =>
                ref.read(localeProvider.notifier).state = const Locale('en'),
          ),
          _LanguageOption(
            label: 'Bahasa Indonesia',
            code: 'id',
            selected: ref.read(localeProvider).languageCode == 'id',
            onSelect: () =>
                ref.read(localeProvider.notifier).state = const Locale('id'),
          ),
          _LanguageOption(
            label: '中文',
            code: 'zh',
            selected: ref.read(localeProvider).languageCode == 'zh',
            onSelect: () =>
                ref.read(localeProvider.notifier).state = const Locale('zh'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.theme),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(ThemeMode.system);
              Navigator.pop(context);
            },
            child: const Text('System Default'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(ThemeMode.light);
              Navigator.pop(context);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }

  void _showDaysBeforeDialog() {
    final notifier = ref.read(reminderSettingsProvider.notifier);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Days Before'),
        children: [
          _option(0, 'On the day', notifier),
          _option(1, '1 day before', notifier),
          _option(3, '3 days before', notifier),
          _option(7, '1 week before', notifier),
        ],
      ),
    );
  }

  Widget _option(int value, String label, ReminderSettingsNotifier notifier) {
    return SimpleDialogOption(
      onPressed: () {
        notifier.setDaysBefore(value);
        Navigator.pop(context);
        _syncNotifications();
      },
      child: Text(label),
    );
  }

  Future<void> _syncNotifications() async {
    final settings = ref.read(reminderSettingsProvider);
    final eventRepo = ref.read(eventRepositoryProvider);
    final notificationRepo = ref.read(notificationRepositoryProvider);

    final allEvents = await eventRepo.getAllTraditionalEvents();
    await notificationRepo.scheduleTraditionalEvents(
      allEvents,
      settings.enableTraditionalReminders,
      NotificationSettings(
        enabled: true,
        daysBefore: settings.defaultDaysBefore,
        reminderTime: settings.reminderTimeStr,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications synchronized'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onSelect;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () {
        onSelect();
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (selected) const Icon(Icons.check, color: Colors.blue),
        ],
      ),
    );
  }
}
