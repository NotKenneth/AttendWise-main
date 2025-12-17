import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppLogoWidget extends StatelessWidget {

  const AppLogoWidget({super.key});


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Container
        Container(

          child: Center(
            child: Image.asset(
              'assets/images/logooo.png',
              // Use fit to ensure the image scales correctly
              fit: BoxFit.fill,
              // Set the image size (reusing the icon size)
              height: 50.w,

              width: 50.w,
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // App Name
        Text(

          'AttendWISE',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            // Light blue color matching the image
            color: const Color(0xFF40C4FF),

            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 0.5.h),


        // Tagline - TEXT AND COLOR MODIFIED TO MATCH IMAGE
        Text(
          'Student Event Attendance System', // 👈 CORRECTED TEXT
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            // Light gray/white color matching the image
            color: const Color(0xFFB0B0B0), 

            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}