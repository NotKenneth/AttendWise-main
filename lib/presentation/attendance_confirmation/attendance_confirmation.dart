import 'package:attendancetracker/theme/app_theme.dart';
import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/attendance_status_card.dart';
import './widgets/duplicate_detection_card.dart';
import './widgets/registration_form.dart';
import './widgets/student_info_card.dart';

class AttendanceConfirmation extends StatefulWidget {
  const AttendanceConfirmation({super.key});

  @override
  State<AttendanceConfirmation> createState() => _AttendanceConfirmationState();
}

class _AttendanceConfirmationState extends State<AttendanceConfirmation> {
  bool _isLoading = false;
  bool _isNewStudent = false;
  bool _isDuplicate = false;
  bool _showRegistrationForm = false;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _previousAttendance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Attendance Confirmation',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showHelpDialog,
            icon: CustomIconWidget(
              iconName: 'help_outline',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    _buildStatusIcon(),
                    SizedBox(height: 2.h),
                    if (_studentData != null) ...[
                      StudentInfoCard(studentData: _studentData!),
                      SizedBox(height: 1.h),
                      if (_attendanceData != null)
                        AttendanceStatusCard(
                          attendanceData: _attendanceData!,
                          isNewStudent: _isNewStudent,
                        ),
                      if (_isDuplicate && _previousAttendance != null) ...[
                        SizedBox(height: 1.h),
                        DuplicateDetectionCard(
                          previousAttendance: _previousAttendance!,
                          onOverride: _handleOverride,
                        ),
                      ],
                      if (_showRegistrationForm && _isNewStudent) ...[
                        SizedBox(height: 1.h),
                        RegistrationForm(
                          onRegistrationComplete: _handleRegistrationComplete,
                        ),
                      ],
                      if (!_showRegistrationForm && !_isDuplicate) ...[
                        SizedBox(height: 3.h),
                        _buildActionButtons(),
                      ],
                    ],
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Processing attendance...',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color iconColor;
    String iconName;
    Color backgroundColor;

    if (_isDuplicate) {
      iconColor = AppTheme.getWarningColor(true);
      iconName = 'warning';
      backgroundColor = AppTheme.getWarningColor(true).withValues(alpha: 0.1);
    } else if (_isNewStudent) {
      iconColor = AppTheme.getWarningColor(true);
      iconName = 'person_add';
      backgroundColor = AppTheme.getWarningColor(true).withValues(alpha: 0.1);
    } else {
      iconColor = AppTheme.getSuccessColor(true);
      iconName = 'check_circle';
      backgroundColor = AppTheme.getSuccessColor(true).withValues(alpha: 0.1);
    }

    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: iconName,
          color: iconColor,
          size: 10.w,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _handleMarkPresent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'check',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Mark Present',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: OutlinedButton(
              onPressed: _handleCancel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Cancel',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMarkPresent() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedback.lightImpact();
        _showSuccessDialog();
      }
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOverride() {
    setState(() {
      _isDuplicate = false;
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
        _showSuccessDialog();
      }
    });
  }

  void _handleRegistrationComplete(Map<String, dynamic> registrationData) {
    setState(() {
      _isLoading = true;
      _showRegistrationForm = false;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNewStudent = false;
        });
        HapticFeedback.lightImpact();
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: AppTheme.getSuccessColor(true).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.getSuccessColor(true),
                  size: 8.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Success!',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.getSuccessColor(true),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Attendance has been recorded successfully.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'help',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Help',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Confirmation Guide:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '• Green checkmark: Student successfully scanned\n'
              '• Yellow warning: New student registration required\n'
              '• Orange warning: Duplicate attendance detected\n'
              '• Complete all required fields for new students\n'
              '• Override duplicates only for legitimate re-entries',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
