import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:attendancetracker/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StudentInfoOverlayWidget extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const StudentInfoOverlayWidget({
    super.key,
    required this.studentData,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final String name = studentData['name'] as String? ?? 'Unknown Student';
    final String studentId = studentData['studentId'] as String? ?? 'N/A';
    final String? photoUrl = studentData['photo'] as String?;
    final String status =
        studentData['attendanceStatus'] as String? ?? 'Present';
    final bool isNewStudent = studentData['isNewStudent'] as bool? ?? false;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: 85.w,
          constraints: BoxConstraints(maxHeight: 70.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isNewStudent
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: isNewStudent ? 'person_add' : 'check_circle',
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        isNewStudent
                            ? 'New Student Registration'
                            : 'Student Scanned',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl != null
                            ? CustomImageWidget(
                                imageUrl: photoUrl,
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.cover,
                                semanticLabel: "Profile photo of $name",
                              )
                            : Container(
                                color: AppTheme.lightTheme.colorScheme
                                    .surfaceContainerHighest,
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: 'person',
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    size: 32,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _buildDetailRow('Name', name),
                    SizedBox(height: 2.h),
                    _buildDetailRow('Student ID', studentId),
                    SizedBox(height: 2.h),
                    _buildDetailRow('Status', status),
                    if (isNewStudent) ...[
                      SizedBox(height: 2.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .lightTheme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'info',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                'This student will be registered automatically upon confirmation.',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              backgroundColor: isNewStudent
                                  ? AppTheme.lightTheme.colorScheme.secondary
                                  : AppTheme.lightTheme.colorScheme.primary,
                            ),
                            child: Text(
                              isNewStudent ? 'Register' : 'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 25.w,
          child: Text(
            '$label:',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
