import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_event_providers.g.dart';

@riverpod
Future<List<CustomEvent>> customEvents(CustomEventsRef ref) async {
  final repo = ref.watch(customEventRepositoryProvider);
  return repo.getAllEvents();
}
