import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LoginFormWidget extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const LoginFormWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    this.emailError,
    this.passwordError,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  bool _isPasswordVisible = false;

  // Define the common Glass Style properties
  final Color inputFillColor = const Color(0xFF1C2D43); // Dark background for the fields
  final Color inputBorderColor = const Color(0xFF40C4FF); // Light blue accent for focused border
  final double borderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field
        SizedBox(
          width: 85.w,
          child: TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !widget.isLoading,

            style: const TextStyle(color: Colors.white), // White text for dark field
            
            decoration: InputDecoration(
              labelText: 'Username or Email', 
              hintText: 'Enter your email address',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 13.sp),
              labelStyle: TextStyle(color: Colors.white70, fontSize: 13.sp),
              
              // 🚨 NEW: Style for the error text
              errorStyle: const TextStyle(color: Colors.redAccent),
              
              // GLASS EFFECT COLOR
              filled: true,
              fillColor: inputFillColor, 
              
              // ICONS
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'mail', 
                  color: Colors.white, 
                  size: 20,
                ),
              ),
              
              // BORDER STYLING
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: inputBorderColor, width: 1.5), 
              ),


              errorText: widget.emailError,
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Password Field
        SizedBox(
          width: 85.w,
          child: TextFormField(
            controller: widget.passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !widget.isLoading,

            style: const TextStyle(color: Colors.white), 

            decoration: InputDecoration(
              labelText: 'Your Password', 
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 13.sp),
              labelStyle: TextStyle(color: Colors.white70, fontSize: 13.sp),

              // 🚨 NEW: Style for the error text
              errorStyle: const TextStyle(color: Colors.redAccent),
              
              // GLASS EFFECT COLOR
              filled: true,
              fillColor: inputFillColor, 
              
              // ICONS

              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'lock',

                  color: Colors.white, 

                  size: 20,
                ),
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName:
                        _isPasswordVisible ? 'visibility' : 'visibility_off',

                    color: Colors.white, 

                    size: 20,
                  ),
                ),
              ),

              
              // BORDER STYLING
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: inputBorderColor, width: 1.5), 
              ),


              errorText: widget.passwordError,
            ),
          ),
        ),
        SizedBox(height: 1.h),

        // Forgot Password Link
        Container(
          width: 85.w,
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onForgotPassword,
            child: Text(

              'Forgot your password?', 
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith( 

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),


        // Login Button Container
        Container(
          width: 85.w,
          height: 7.h,
          decoration: BoxDecoration(
            color: inputFillColor, 
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color(0xFF1D87D8).withOpacity(0.5), 
              width: 1,
            ),
          ),

          child: ElevatedButton(
            onPressed: widget.isLoading ||
                    widget.emailController.text.isEmpty ||
                    widget.passwordController.text.isEmpty
                ? null
                : widget.onLogin,

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D87D8), 
              padding: EdgeInsets.zero, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? const SizedBox(

                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(

                        Colors.white, 

                      ),
                    ),
                  )
                : Text(
                    'Login',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(

                      color: Colors.white, 

                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

}

