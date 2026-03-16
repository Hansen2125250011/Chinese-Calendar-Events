import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';
import 'package:chinese_calendar/features/events/presentation/providers/custom_event_providers.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chinese_calendar/core/providers/reminder_settings_provider.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  final CustomEvent? event;
  final DateTime? initialDate;
  const AddEventDialog({super.key, this.event, this.initialDate});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late bool _isLunar;
  late bool _isAnnual;
  bool _enableReminder = false;
  late int _reminderDaysBefore;
  late TimeOfDay _reminderTime;
  String _lunarDateSummary = '';

  @override
  void initState() {
    super.initState();

    // Get defaults from provider
    final defaultSettings = ref.read(reminderSettingsProvider);
    _reminderDaysBefore = defaultSettings.defaultDaysBefore;
    _reminderTime = defaultSettings.defaultTime;
    _enableReminder = defaultSettings.enableTraditionalReminders;
    final e = widget.event;
    if (e != null) {
      _nameController = TextEditingController(text: e.name);
      _isLunar = e.isLunar;
      _isAnnual = e.year == null;
      _selectedDate = DateTime.now(); // Default fallback

      if (!e.isLunar && e.year != null) {
        _selectedDate = DateTime(e.year!, e.month, e.day);
      } else if (!e.isLunar && e.year == null) {
        _selectedDate = DateTime(DateTime.now().year, e.month, e.day);
      } else {
        // Lunar: need to find solar date for these month/day
        // We do it after frame to keep initState clean or just use a Future
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final repo = ref.read(lunarRepositoryProvider);
          final solar = await repo.getSolarDate(
            year: e.year ?? DateTime.now().year,
            month: e.month,
            day: e.day,
            isLeapMonth: e.isLeap,
          );
          if (mounted) {
            setState(() => _selectedDate = solar);
          }
        });
      }
    } else {
      _nameController = TextEditingController();
      _selectedDate = widget.initialDate ?? DateTime.now();
      _isLunar = true;
      _isAnnual = true;
    }
    _updateLunarSummary();
  }

  Future<void> _updateLunarSummary() async {
    if (!_isLunar) {
      setState(() => _lunarDateSummary = '');
      return;
    }
    final repo = ref.read(lunarRepositoryProvider);
    final lunar = await repo.getLunarDate(_selectedDate);
    if (mounted) {
      setState(() {
        _lunarDateSummary = 'Lunar: Month ${lunar.month}, Day ${lunar.day}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.event != null ? 'Edit Event' : 'Add Custom Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat.yMMMd().format(_selectedDate)),
                    if (_isLunar && _lunarDateSummary.isNotEmpty)
                      Text(_lunarDateSummary,
                          style: TextStyle(
                              color: theme.colorScheme.primary, fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    _updateLunarSummary();
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Use Lunar Date'),
                subtitle: const Text('Celebrated based on Lunar Calendar'),
                value: _isLunar,
                onChanged: (val) {
                  setState(() => _isLunar = val);
                  _updateLunarSummary();
                },
              ),
              SwitchListTile(
                title: const Text('Annual Repeat'),
                value: _isAnnual,
                onChanged: (val) => setState(() => _isAnnual = val),
              ),
              const Divider(), // Added
              SwitchListTile(
                // Added
                title: const Text('Enable Reminder'),
                value: _enableReminder,
                onChanged: (val) => setState(() => _enableReminder = val),
              ),
              if (_enableReminder) ...[
                DropdownButtonFormField<int>(
                  initialValue: _reminderDaysBefore,
                  decoration: const InputDecoration(labelText: 'Remind me'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('On the day')),
                    DropdownMenuItem(value: 1, child: Text('1 day before')),
                    DropdownMenuItem(value: 3, child: Text('3 days before')),
                    DropdownMenuItem(value: 7, child: Text('1 week before')),
                  ],
                  onChanged: (val) =>
                      setState(() => _reminderDaysBefore = val!),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Reminder Time'),
                  subtitle: Text(_reminderTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (time != null) {
                      setState(() => _reminderTime = time);
                    }
                  },
                ),
                _buildReminderSummary(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saveEvent,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildReminderSummary() {
    final reminderDate =
        _selectedDate.subtract(Duration(days: _reminderDaysBefore));
    final scheduledTime = DateTime(reminderDate.year, reminderDate.month,
        reminderDate.day, _reminderTime.hour, _reminderTime.minute);
    final now = DateTime.now();
    final isPast = scheduledTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        isPast
            ? '⚠️ This reminder time has passed for this year. It will be scheduled for next year.'
            : '🔔 Reminder set for: ${DateFormat.yMMMd().format(scheduledTime)} at ${_reminderTime.format(context)}',
        style: TextStyle(
          fontSize: 12,
          color: isPast ? Colors.orange : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    int month;
    int day;
    bool isLeap = false;
    int? year = _isAnnual ? null : _selectedDate.year;

    if (_isLunar) {
      // Convert selected gregorian date to lunar to get month/day
      final lunarRepo = ref.read(lunarRepositoryProvider);
      final lunarDate = await lunarRepo.getLunarDate(_selectedDate);
      month = lunarDate.month;
      day = lunarDate.day;
      isLeap = lunarDate.isLeapMonth;
      if (!_isAnnual) year = lunarDate.year;
    } else {
      month = _selectedDate.month;
      day = _selectedDate.day;
    }

    final event = CustomEvent(
      id: widget.event?.id ?? 0,
      name: _nameController.text,
      isLunar: _isLunar,
      year: year,
      month: month,
      day: day,
      isLeap: isLeap,
    );

    try {
      int id;
      if (widget.event != null) {
        await ref.read(customEventRepositoryProvider).updateEvent(event);
        id = event.id;
      } else {
        id = await ref.read(customEventRepositoryProvider).addEvent(event);
      }

      if (_enableReminder) {
        await ref.read(eventRepositoryProvider).saveUserReminder(
              'custom_$id',
              _reminderDaysBefore,
              '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
            );
        await ref.read(notificationRepositoryProvider).scheduleCustomEvent(
              id,
              event.name,
              event.isLunar,
              event.month,
              event.day,
              event.year,
              event.isLeap,
              _reminderDaysBefore,
              _reminderTime.hour,
              _reminderTime.minute,
            );
      }

      // Refresh list (invalidate provider)
      ref.invalidate(customEventsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
