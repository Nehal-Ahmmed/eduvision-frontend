import 'package:academic_project/domain/event.dart';
import 'package:academic_project/presentation/events/provider/events_provider.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Upcoming', 'Today', 'Past'];

  List<Event> _filterEvents(List<Event> events) {
    switch (_selectedFilter) {
      case 1:
        return events.where((e) => e.isUpcoming).toList();
      case 2:
        return events.where((e) => e.isToday).toList();
      case 3:
        return events.where((e) => !e.isToday && !e.isUpcoming).toList();
      default:
        return events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Container(
      color: AppColors.gray50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.indigo600,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Events',
                              style: AppTextStyles.sectionHeading.copyWith(
                                color: AppColors.gray900,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(DateTime.now()),
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showEventDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Event'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo600,
                        side: const BorderSide(color: AppColors.indigo600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isSelected = _selectedFilter == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.indigo600
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.indigo600
                                  : AppColors.gray400,
                            ),
                          ),
                          child: Text(
                            _filters[i],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.gray600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.red500),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load events',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray700),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.read(eventsProvider.notifier).fetchAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                final filtered = _filterEvents(events)
                  ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _buildEventCard(context, filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 56, color: AppColors.gray400),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter == 0 ? 'Tap "Add Event" to create one' : 'Try a different filter',
            style: AppTextStyles.small.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final typeConfig = _getTypeConfig(event.type);

    return GestureDetector(
      onTap: () => _showEventDialog(context, event: event),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: typeConfig.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: typeConfig.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          typeConfig.icon,
                          color: typeConfig.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                ),
                                if (event.isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xFF6EE7B7),
                                      ),
                                    ),
                                    child: const Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _confirmDelete(event),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                            if (event.description != null && event.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                event.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                _infoChip(
                                  Icons.calendar_today_outlined,
                                  event.formattedDate,
                                ),
                                if (event.startTime != null)
                                  _infoChip(
                                    Icons.access_time_outlined,
                                    _formatTime(event.startTime!),
                                  ),
                                if (event.location != null && event.location!.isNotEmpty)
                                  _infoChip(
                                    Icons.place_outlined,
                                    event.location!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    try {
      final parsed = DateFormat('HH:mm:ss').parse(time);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('HH:mm').parse(time);
        return DateFormat('h:mm a').format(parsed);
      } catch (_) {
        return time;
      }
    }
  }

  _TypeConfig _getTypeConfig(EventType type) {
    switch (type) {
      case EventType.EXAM:
        return _TypeConfig(
          color: const Color(0xFFDC2626),
          icon: Icons.quiz_outlined,
        );
      case EventType.DEADLINE:
        return _TypeConfig(
          color: const Color(0xFFD97706),
          icon: Icons.assignment_late_outlined,
        );
      case EventType.LECTURE:
        return _TypeConfig(
          color: AppColors.indigo600,
          icon: Icons.school_outlined,
        );
      case EventType.GROUP:
        return _TypeConfig(
          color: const Color(0xFF0891B2),
          icon: Icons.group_outlined,
        );
      case EventType.OTHER:
        return _TypeConfig(
          color: AppColors.gray500,
          icon: Icons.event_note_outlined,
        );
    }
  }

  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(eventsProvider.notifier).removeEvent(event.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red600),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(BuildContext context, {Event? event}) {
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final descCtrl = TextEditingController(text: event?.description ?? '');
    final locationCtrl = TextEditingController(text: event?.location ?? '');

    DateTime selectedDate = event?.eventDate ?? DateTime.now();
    TimeOfDay? selectedStartTime = event?.startTime != null
        ? _parseTime(event!.startTime!)
        : null;
    TimeOfDay? selectedEndTime = event?.endTime != null
        ? _parseTime(event!.endTime!)
        : null;
    EventType selectedType = event?.type ?? EventType.OTHER;

    final isEditing = event != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Text(
                isEditing ? 'Edit Event' : 'Add New Event',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course / Details',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedStartTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedStartTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: Icon(Icons.access_time, size: 20),
                              ),
                              child: Text(
                                selectedStartTime != null
                                    ? selectedStartTime!.format(context)
                                    : 'Not set',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedEndTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedEndTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                prefixIcon: Icon(Icons.access_time, size: 20),
                              ),
                              child: Text(
                                selectedEndTime != null
                                    ? selectedEndTime!.format(context)
                                    : 'Not set',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<EventType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: EventType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedType = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                    final startStr = selectedStartTime != null
                        ? '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}:00'
                        : null;
                    final endStr = selectedEndTime != null
                        ? '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}:00'
                        : null;

                    if (isEditing) {
                      ref.read(eventsProvider.notifier).editEvent(
                        event.id,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        eventDate: dateStr,
                        startTime: startStr,
                        endTime: endStr,
                        location: locationCtrl.text.trim().isEmpty
                            ? null
                            : locationCtrl.text.trim(),
                        type: selectedType.name,
                      );
                    } else {
                      ref.read(eventsProvider.notifier).addEvent(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        eventDate: dateStr,
                        startTime: startStr,
                        endTime: endStr,
                        location: locationCtrl.text.trim().isEmpty
                            ? null
                            : locationCtrl.text.trim(),
                        type: selectedType.name,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _typeLabel(EventType type) {
    switch (type) {
      case EventType.EXAM:
        return 'Exam';
      case EventType.DEADLINE:
        return 'Deadline';
      case EventType.LECTURE:
        return 'Lecture';
      case EventType.GROUP:
        return 'Group';
      case EventType.OTHER:
        return 'Other';
    }
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parsed = DateFormat('HH:mm:ss').parse(time);
      return TimeOfDay.fromDateTime(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('HH:mm').parse(time);
        return TimeOfDay.fromDateTime(parsed);
      } catch (_) {
        return null;
      }
    }
  }
}

class _TypeConfig {
  final Color color;
  final IconData icon;
  _TypeConfig({required this.color, required this.icon});
}
