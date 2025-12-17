import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EventHeaderWidget extends StatelessWidget {
  final List<Map<String, dynamic>> availableEvents;
  final Map<String, dynamic>? selectedEvent;
  final ValueChanged<Map<String, dynamic>?> onEventChanged;

  const EventHeaderWidget({
    super.key,
    required this.availableEvents,
    required this.selectedEvent,
    required this.onEventChanged,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? dropdownValue = selectedEvent;

    if (availableEvents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: _boxDecoration(),
        child: const Center(child: Text("No events available")),
      );
    }

    if (dropdownValue != null) {
      try {
        dropdownValue = availableEvents.firstWhere(
          (element) => element['id'] == dropdownValue!['id'],
          orElse: () => availableEvents.first,
        );
      } catch (_) {
        dropdownValue = null;
      }
    }

    final String title = dropdownValue?['title'] ?? 'Select an Event';
    final String category = dropdownValue?['category'] ?? 'General';
    final String location = dropdownValue?['location'] ?? 'TBA';

    String dateString = dropdownValue?['event_date'] ?? '';
    if (dateString.isNotEmpty) {
      try {
        final DateTime date = DateTime.parse(dateString);
        dateString = DateFormat('MMMM d, y').format(date);
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                hint: const Text('Choose an event...'),
                value: dropdownValue,
                icon: Icon(Icons.arrow_drop_down_circle,
                    color: AppTheme.lightTheme.colorScheme.primary),
                onChanged: onEventChanged,
                items: availableEvents.map((event) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: event,
                    child: Text(
                      event['title'] ?? 'Untitled',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // INFO DISPLAY
          Text(title,
              style: AppTheme.lightTheme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInfoRow('calendar_today', dateString),
          const SizedBox(height: 8),
          _buildInfoRow('location_on', location),
          const SizedBox(height: 8),
          _buildInfoRow('category', category),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppTheme.lightTheme.colorScheme.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Row(
      children: [
        CustomIconWidget(
            iconName: icon,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 20),
        SizedBox(width: 2.w),
        Expanded(
            child: Text(text, style: AppTheme.lightTheme.textTheme.bodyMedium)),
      ],
    );
  }
}
