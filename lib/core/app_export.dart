import 'package:flutter/material.dart';
import '../presentation/marshall_dashboard/marshall_dashboard.dart';
import '../presentation/event_details_screen/event_details_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/attendance_confirmation/attendance_confirmation.dart';
import '../presentation/student_dashboard/student_dashboard.dart';
export '../theme/app_theme.dart';

class AppRoutes {
  static const String initial = '/';
  static const String marshallDashboard = '/marshall-dashboard';
  static const String eventDetails = '/event-details-screen';
  static const String login = '/login-screen';
  static const String attendanceConfirmation = '/attendance-confirmation';
  static const String barcodeScanner = '/barcode-scanner-screen';
  static const String studentDashboard = '/student-dashboard';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    marshallDashboard: (context) => const MarshallDashboard(),
    eventDetails: (context) => const EventDetailsScreen(),
    login: (context) => const LoginScreen(),
    attendanceConfirmation: (context) => const AttendanceConfirmation(),
    studentDashboard: (context) => const StudentDashboard(),
  };
}
