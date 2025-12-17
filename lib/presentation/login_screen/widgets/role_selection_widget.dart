import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RoleSelectionWidget extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const RoleSelectionWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });


  // Define the common colors for the glass/dark theme
  final Color darkContainerColor = const Color(0xFF1C2D43);
  final Color selectedColor = const Color(0xFF1D87D8); // Primary blue
  final Color unselectedTextColor = const Color(0xFFB0B0B0); // Light gray/white

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Text (Added to match the image: "Select your role")
        Text(
          'Select your role',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: unselectedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),

        // Role Selection Toggle
        Container(
          width: 85.w,
          decoration: BoxDecoration(
            // 1. Base Container Color for Glass Effect
            color: darkContainerColor,
            borderRadius: BorderRadius.circular(12),
            // 2. Removed border to simplify the look
            border: Border.all(
              color: Colors.transparent, // Making border transparent
              width: 0,
            ),
          ),
          child: Row(
            children: [
              // --- STUDENT BUTTON ---
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('Student'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      // 3. Selected Color (Blue)
                      color: selectedRole == 'Student'
                          ? selectedColor
                          : darkContainerColor, // Use dark color for unselected
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        // Only round the active corner for the selected button
                        topRight: selectedRole == 'Student' ? Radius.circular(0) : Radius.circular(12), 
                        bottomRight: selectedRole == 'Student' ? Radius.circular(0) : Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Student',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          // White text when selected, light gray when unselected
                          color: selectedRole == 'Student'
                              ? Colors.white 
                              : unselectedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // --- MARSHALL BUTTON ---
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('Marshall'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      // 3. Selected Color (Blue)
                      color: selectedRole == 'Marshall'
                          ? selectedColor
                          : darkContainerColor, // Use dark color for unselected
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        // Only round the active corner for the selected button
                        topLeft: selectedRole == 'Marshall' ? Radius.circular(0) : Radius.circular(12),
                        bottomLeft: selectedRole == 'Marshall' ? Radius.circular(0) : Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Marshall',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          // White text when selected, light gray when unselected
                          color: selectedRole == 'Marshall'
                              ? Colors.white
                              : unselectedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }
}

