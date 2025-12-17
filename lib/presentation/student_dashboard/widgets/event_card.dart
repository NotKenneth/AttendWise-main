import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;
  final VoidCallback onShare;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onViewDetails,
    required this.onShare,
  });

  static const cardColor = Color(0xFF1E2B3E);

  @override
  Widget build(BuildContext context) {
    final eventName = (event['name'] as String?) ?? 'Unknown Event';
    final eventDate = (event['date'] as String?) ?? 'Unknown Date';
    final eventTime = (event['time'] as String?) ?? 'Unknown Time';
    final eventVenue = (event['venue'] as String?) ?? 'Unknown Venue';
    final eventType = (event['type'] as String?) ?? 'General';

    final Color categoryColor =
        (event['color'] as Color?) ?? _getEventTypeColor(eventType);

    return Slidable(
      key: ValueKey(event['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onViewDetails(),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.visibility,
            label: 'Details',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => onShare(),
            backgroundColor: AppTheme.getSuccessColor(true),
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          eventType,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.getSuccessColor(true),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    eventName,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        color: AppTheme.textMediumEmphasisLight,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          '$eventDate • $eventTime',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textDisabledDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.textMediumEmphasisLight,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          eventVenue,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMediumEmphasisLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'seminar':
        return Colors.green;
      case 'academic':
        return Colors.blue;
      case 'conference':
        return AppTheme.getWarningColor(true);
      case 'meeting':
        return AppTheme.getAccentColor(true);
      case 'special event':
      case 'sports':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }
}
