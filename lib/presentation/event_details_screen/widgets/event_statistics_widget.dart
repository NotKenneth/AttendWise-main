import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EventStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statisticsData;

  const EventStatisticsWidget({
    super.key,
    required this.statisticsData,
  });

  @override
  Widget build(BuildContext context) {
    final String capacityStr = (statisticsData['capacity'] ?? '0').toString();
    final String status = (statisticsData['status'] ?? 'Unknown').toString();
    final String category =
        (statisticsData['category'] ?? 'General').toString();

    final int capacityMax = int.tryParse(capacityStr) ?? 0;

    final int attendanceCurrent =
        int.tryParse((statisticsData['attendanceCount'] ?? '0').toString()) ??
            0;

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
            children: [
              CustomIconWidget(
                iconName: 'analytics',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Event Details',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          Row(
            children: [
              // 1. Capacity (Dynamic Color based on fullness)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Capacity',
                  '$attendanceCurrent / $capacityMax',
                  'group',
                  _getCapacityColor(attendanceCurrent, capacityMax),
                ),
              ),
              SizedBox(width: 3.w),

              // 2. Status (Custom Colors)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Status',
                  status,
                  'info',
                  _getStatusColor(status),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // --- Row 2: Category (Full Width) ---
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Category',
                  category,
                  'category',
                  _getCategoryColor(category),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String iconName,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 28,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getCapacityColor(int current, int max) {
    if (max == 0) return Colors.red;

    double percentage = current / max;

    if (percentage >= 0.7) {
      return Colors.green;
    } else if (percentage >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // 2. Category Color Logic
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'sports':
        return Colors.deepOrange;
      case 'seminar':
        return Colors.purple;
      case 'special event':
        return Colors.pink;
      case 'academic':
        return Colors.indigo;
      case 'general':
      default:
        return Colors.teal;
    }
  }

  // 3. Status Color Logic
  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed':
      case 'closed':
        return Colors.green;

      case 'live':
      case 'ongoing':
      case 'open':
        return Colors.red;

      case 'upcoming':
        return Colors.blue;

      case 'cancelled':
        return Colors.grey;

      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
