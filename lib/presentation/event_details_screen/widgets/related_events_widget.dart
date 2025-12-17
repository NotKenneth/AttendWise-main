import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:attendancetracker/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RelatedEventsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> relatedEvents;

  const RelatedEventsWidget({
    super.key,
    required this.relatedEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (relatedEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'event',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Upcoming Events',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: relatedEvents.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final event = relatedEvents[index];
                return _buildEventCard(context, event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final String title = event['title'] ?? 'Untitled Event';
    final String? imageUrl = event['image_url'];

    String dateString = event['event_date'] ?? 'Date TBA';
    try {
      final DateTime date = DateTime.parse(dateString);
      dateString = DateFormat('MMM d, y').format(date);
    } catch (_) {}

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 60.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CustomImageWidget(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: title,
                      )
                    : Container(
                        color: AppTheme
                            .lightTheme.colorScheme.surfaceContainerHighest,
                        width: double.infinity,
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'image',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calendar_today',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            dateString,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
