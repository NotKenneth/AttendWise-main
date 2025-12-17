import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

import './widgets/event_description_widget.dart';
import './widgets/event_header_widget.dart';
import './widgets/event_statistics_widget.dart';
import './widgets/related_events_widget.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _selectedEvent;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('events')
          .select('*, attendance_logs(count)')
          .order('event_date', ascending: true);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response);
          _isLoading = false;

          if (_events.isNotEmpty && _selectedEvent == null) {
            final endedEvent = _events.lastWhere(
              (event) {
                final status = (event['status'] ?? '').toString().toLowerCase();
                return status == 'completed' ||
                    status == 'closed' ||
                    status == 'ended';
              },
              orElse: () => _events.last,
            );

            _selectedEvent = endedEvent;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading events: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_events.isEmpty) {
      return Center(child: Text("No events found."));
    }

    int attendanceCount = 0;
    if (_selectedEvent != null && _selectedEvent!['attendance_logs'] != null) {
      final logs = _selectedEvent!['attendance_logs'] as List;
      if (logs.isNotEmpty) {
        attendanceCount = logs[0]['count'] ?? 0;
      }
    }

    final statisticsData = {
      "capacity": _selectedEvent?['capacity'] ?? 0,
      "status": _selectedEvent?['status'] ?? "Unknown",
      "category": _selectedEvent?['category'] ?? "General",
      "attendanceCount": attendanceCount,
    };

    return RefreshIndicator(
      onRefresh: _fetchEvents,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: false,
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            title: Text(
              'Event Details',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showMoreOptions(context),
                icon: CustomIconWidget(
                  iconName: 'more_vert',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 2.h),
                EventHeaderWidget(
                  availableEvents: _events,
                  selectedEvent: _selectedEvent,
                  onEventChanged: (newValue) {
                    setState(() {
                      _selectedEvent = newValue;
                    });
                  },
                ),
                SizedBox(height: 3.h),
                if (_selectedEvent != null)
                  EventDescriptionWidget(
                    eventId: _selectedEvent!['id'],
                  ),
                SizedBox(height: 3.h),
                EventStatisticsWidget(statisticsData: statisticsData),
                SizedBox(height: 3.h),
                RelatedEventsWidget(
                  relatedEvents: _events
                      .where((e) => e['id'] != _selectedEvent?['id'])
                      .toList(),
                ),
                SizedBox(height: 4.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'calendar_today',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Add to Calendar',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _addToCalendar();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Report Issue',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportIssue();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Event added to calendar successfully!',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _reportIssue() {
    // ... (Keep your report issue logic here)
  }
}
