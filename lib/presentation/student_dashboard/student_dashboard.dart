import 'dart:ui';
import 'package:attendancetracker/widgets/custom_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_export.dart';
import './widgets/attendance_stats_card.dart';
import './widgets/dashboard_header.dart';
import './widgets/empty_state_widget.dart';
import './widgets/event_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  int _currentTabIndex = 0;
  bool _isLoading = true;
  bool _isOffline = false;
  DateTime _lastUpdated = DateTime.now();
  Map<String, dynamic>? _userProfile;

  int _totalEventsCount = 0;
  int _attendedCount = 0;
  double _attendanceRate = 0.0;
  List<Map<String, dynamic>> _dashboardEventList = [];

  // Theme Constants
  static const darkBlueBackground = Color(0xFF0F1A2A);
  static const primaryAccentColor = Color(0xFF3393FF);
  static const lightTextColor = Color(0xFFE0E0E0);
  static const mediumTextColor = Color(0xFF9E9E9E);
  static const cardColor = Color(0xFF1E2B3E);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUserProfile(),
      _fetchDashboardStats(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final response = await _supabase.from('profiles').select().eq('id', user.id).single();
      final String firstName = response['first_name'] ?? '';
      final String lastName = response['last_name'] ?? '';
      final String fullName = '$firstName $lastName'.trim();

      final profileData = {
        'full_name': fullName.isEmpty ? 'Student' : fullName,
        'email': response['email'] ?? user.email,
        'role': response['role'] ?? 'student',
        'avatar_url': response['avatar_url'],
        'bio': response['bio'],
        'student_id_number': response['student_id'],
        'course': response['program'],
        'year_level': response['year_level'],
        'phone_number': response['phone'],
        'address': response['address'],
        'semester': '1st Semester',
      };

      if (mounted) {
        setState(() {
          _userProfile = profileData;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isOffline = true);
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final totalSystemEventsResponse = await _supabase.from('events').count(CountOption.exact);
      final int totalSystemEvents = totalSystemEventsResponse;

      final completedEventsResponse = await _supabase
          .from('attendance_logs')
          .count(CountOption.exact)
          .eq('user_id', user.id)
          .not('time_in', 'is', null)
          .not('time_out', 'is', null);

      final int completedCount = completedEventsResponse;
      double rate = totalSystemEvents > 0 ? (completedCount / totalSystemEvents) * 100 : 0.0;

      final registrationResponse = await _supabase
          .from('event_registrations')
          .select('events(*)')
          .eq('user_id', user.id);

      final List<Map<String, dynamic>> tempList = [];
      for (var reg in registrationResponse) {
        final event = reg['events'];
        if (event != null) {
          final String statusRaw = (event['status'] ?? 'Upcoming').toString();
          final bool isRelevant = !['completed', 'ended', 'closed', 'cancelled']
              .contains(statusRaw.toLowerCase());

          if (isRelevant) {
            String category = event['category'] ?? "General";
            String displayStatus = ['ongoing', 'open', 'live'].contains(statusRaw.toLowerCase()) ? "Live" : "Upcoming";

            tempList.add({
              "id": event['id'],
              "name": event['title'] ?? "Unknown Event",
              "type": category,
              "color": _getCategoryColor(category),
              "date": _formatDate(event['event_date']),
              "time": _formatTime(event['time_start']),
              "venue": event['location'] ?? "TBD",
              "status": displayStatus,
              "raw_date": DateTime.parse(event['event_date'] ?? DateTime.now().toIso8601String()),
            });
          }
        }
      }

      tempList.sort((a, b) {
        if (a['status'] == 'Live' && b['status'] != 'Live') return -1;
        if (a['status'] != 'Live' && b['status'] == 'Live') return 1;
        return (a['raw_date'] as DateTime).compareTo(b['raw_date'] as DateTime);
      });

      if (mounted) {
        setState(() {
          _totalEventsCount = completedCount;
          _attendedCount = completedCount;
          _attendanceRate = rate;
          _dashboardEventList = tempList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard stats: $e");
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'seminar': return Colors.green;
      case 'academic': return Colors.blue;
      case 'special event':
      case 'sports': return Colors.orange;
      default: return Colors.white;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Date TBD";
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (e) { return dateStr; }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "Time TBD";
    try {
      final time = DateFormat("HH:mm:ss").parse(timeStr);
      return DateFormat("h:mm a").format(time);
    } catch (e) { return timeStr; }
  }

  // --- UI Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: darkBlueBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset(
              'assets/images/Background_shooting_star.json',
              fit: BoxFit.cover,
              repeat: true,
              animate: true,
            ),
          ),
          _buildBody(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20, 
            child: _buildFloatingNavbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavbar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      height: 72,
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: _handleTabChange,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: primaryAccentColor,
            unselectedItemColor: mediumTextColor.withOpacity(0.5),
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            items: [
              _buildNavItem('dashboard', 'Home', 0),
              _buildNavItem('person', 'Profile', 1),
              _buildNavItem('settings', 'Settings', 2),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: CustomIconWidget(
          iconName: icon,
          color: _currentTabIndex == index ? primaryAccentColor : mediumTextColor,
          size: 26,
        ),
      ),
      label: label,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _userProfile == null) return _buildLoadingState();
    switch (_currentTabIndex) {
      case 0: return _buildDashboardTab();
      case 1: return _isLoading ? _buildLoadingState() : _buildProfileTab();
      case 2: return _buildSettingsTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SizedBox.expand(
      child: RefreshIndicator(
        onRefresh: _loadAllData,
        color: primaryAccentColor,
        child: Column(
          children: [
            Stack(
              children: [
                DashboardHeader(
                  studentName: (_userProfile?['full_name'] as String?) ?? 'Student',
                  currentSemester: (_userProfile?['semester'] as String?) ?? 'Current Semester',
                  nameColor: primaryAccentColor,
                ),
                Positioned(
                  top: 11.h,
                  right: 4.w,
                  child: _buildNotificationIcon(),
                ),
              ],
            ),
            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          AttendanceStatsCard(
            totalEvents: _totalEventsCount,
            attendancePercentage: _attendanceRate,
            recentActivityCount: _attendedCount,
          ),
          if (_isOffline) _buildOfflineIndicator(),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  "Ongoing & Upcoming Events",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          if (_dashboardEventList.isEmpty && !_isLoading)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text("No Upcoming or Live Events", style: TextStyle(color: mediumTextColor, fontSize: 12.sp)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dashboardEventList.length,
              itemBuilder: (context, index) {
                final event = _dashboardEventList[index];
                return EventCard(
                  event: event,
                  onTap: () => _handleEventTap(event),
                  onViewDetails: () => _handleViewDetails(event),
                  onShare: () => _handleShareAttendance(event),
                );
              },
            ),
          SizedBox(height: 14.h), 
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    String initials = "ST";
    if (_userProfile?['full_name'] != null) {
      List<String> names = (_userProfile!['full_name'] as String).split(" ");
      initials = names.length >= 2 ? "${names.first[0]}${names.last[0]}" : names[0][0];
    }
    return SizedBox.expand(
      child: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        color: primaryAccentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              SizedBox(height: 8.h),
              CircleAvatar(
                radius: 15.w,
                backgroundColor: primaryAccentColor.withOpacity(0.1),
                backgroundImage: _userProfile?['avatar_url'] != null ? NetworkImage(_userProfile!['avatar_url']) : null,
                child: _userProfile?['avatar_url'] == null ? Text(initials.toUpperCase(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryAccentColor)) : null,
              ),
              SizedBox(height: 2.h),
              Text(_userProfile?['full_name'] ?? 'Loading...', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: lightTextColor)),
              SizedBox(height: 4.h),
              if (_userProfile != null) ...[
                _buildInfoSectionCard(title: "Academic Information", items: [
                  {'label': 'Student ID', 'value': _userProfile!['student_id_number']},
                  {'label': 'Course', 'value': _userProfile!['course']},
                  {'label': 'Year Level', 'value': _userProfile!['year_level']},
                ]),
                SizedBox(height: 2.h),
                _buildInfoSectionCard(title: "Personal Information", items: [
                  {'label': 'Address', 'value': _userProfile!['address']},
                  {'label': 'Contact No.', 'value': _userProfile!['phone_number']},
                ]),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            Text('Settings', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: lightTextColor)),
            SizedBox(height: 4.h),
            _buildSettingsCard(),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSettingsItem('Notifications', 'Manage alerts', 'notifications', () {}),
          _buildSettingsItem('Privacy', 'Data settings', 'privacy_tip', () {}),
          _buildSettingsItem('Logout', 'Sign out', 'logout', () => _showLogoutConfirmation(), isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, String sub, String icon, VoidCallback tap, {bool isDestructive = false}) {
    return ListTile(
      leading: CustomIconWidget(iconName: icon, color: isDestructive ? Colors.redAccent : primaryAccentColor),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : lightTextColor)),
      subtitle: Text(sub, style: TextStyle(color: mediumTextColor)),
      trailing: const Icon(Icons.chevron_right, color: mediumTextColor),
      onTap: tap,
    );
  }

  Widget _buildInfoSectionCard({required String title, required List<Map<String, dynamic>> items}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryAccentColor)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item['label'], style: const TextStyle(color: mediumTextColor)),
              Text(item['value']?.toString() ?? 'N/A', style: const TextStyle(color: lightTextColor, fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined, color: lightTextColor),
      onPressed: () {},
    );
  }

  Widget _buildLoadingState() => const Center(child: CircularProgressIndicator(color: primaryAccentColor));

  Widget _buildOfflineIndicator() => Container(
    padding: const EdgeInsets.all(10),
    color: Colors.orange.withOpacity(0.1),
    child: const Text("Offline Mode", style: TextStyle(color: Colors.orange)),
  );

  void _handleTabChange(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentTabIndex = index);
  }

  void _handleEventTap(Map<String, dynamic> e) => Navigator.pushNamed(context, '/event-details-screen', arguments: e);
  void _handleViewDetails(Map<String, dynamic> e) => Navigator.pushNamed(context, '/event-details-screen', arguments: e);
  void _handleShareAttendance(Map<String, dynamic> e) {}

  // --- Logout Logic ---

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Logout", style: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold)),
            content: const Text("Are you sure you want to sign out?", style: TextStyle(color: mediumTextColor)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: mediumTextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
                child: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login-screen');
  }
}