import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EventDescriptionWidget extends StatefulWidget {
  final int eventId;

  const EventDescriptionWidget({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDescriptionWidget> createState() => _EventDescriptionWidgetState();
}

class _EventDescriptionWidgetState extends State<EventDescriptionWidget> {
  bool _isExpanded = false;
  final int _maxLines = 3;

  String? _description;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDescription();
  }

  @override
  void didUpdateWidget(covariant EventDescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId != oldWidget.eventId) {
      _fetchDescription();
    }
  }

  Future<void> _fetchDescription() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('events')
          .select('description')
          .eq('id', widget.eventId)
          .single();

      if (mounted) {
        setState(() {
          _description = response['description'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching description: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                iconName: 'description',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Event Description',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            _buildLoadingShim()
          else if (_hasError || _description == null || _description!.isEmpty)
            Text(
              "No description available.",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            _buildDescriptionText(),
        ],
      ),
    );
  }

  Widget _buildDescriptionText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            _description!,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            _description!,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        if (_description!.length > 150) ...[
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? 'Read Less' : 'Read More',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: _isExpanded ? 'expand_less' : 'expand_more',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingShim() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: double.infinity, height: 1.5.h, color: Colors.grey[200]),
        SizedBox(height: 1.h),
        Container(width: 80.w, height: 1.5.h, color: Colors.grey[200]),
        SizedBox(height: 1.h),
        Container(width: 60.w, height: 1.5.h, color: Colors.grey[200]),
      ],
    );
  }
}
