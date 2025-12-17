import 'dart:ui'; // Required for Glassmorphism blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_export.dart';
import 'widgets/attendance_stats_card.dart';
import 'widgets/event_header_card.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_scan_item.dart';
import 'widgets/event_reports_view.dart';
import '../../widgets/custom_icon_widget.dart';
import '../barcode_scanner_screen/barcode_scanner_screen.dart';

class MarshallDashboard extends StatefulWidget {
  const MarshallDashboard({super.key});

  @override
  State<MarshallDashboard> createState() => _MarshallDashboardState();
}

class _MarshallDashboardState extends State<MarshallDashboard>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _currentTabIndex = 1;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  RealtimeChannel? _marshallRevokeSubscription;
  RealtimeChannel? _attendanceSubscription;

  final List<Map<String, dynamic>> _recentScans = [];
  List<Map<String, dynamic>> _filteredScans = [];

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _currentEvent;
  Map<String, String?> _eventTimeSettings = {};

  int _totalScannedCount = 0;
  String _capacityUtilization = "0%";
  String _scanRate = "0%";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _fetchDashboardData(refreshStats: true);
    _subscribeToRevocation();
  }

  @override
  void dispose() {
    if (_marshallRevokeSubscription != null) {
      _supabase.removeChannel(_marshallRevokeSubscription!);
    }
    if (_attendanceSubscription != null) {
      _supabase.removeChannel(_attendanceSubscription!);
    }
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _subscribeToRevocation() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _marshallRevokeSubscription = _supabase
        .channel('public:event_marshalls:revocation:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'event_marshalls',
          callback: (payload) {
            if (payload.oldRecord['user_id'] == user.id) {
              if (mounted) _handleAccessRevoked();
            }
          },
        )
        .subscribe();
  }

  void _subscribeToAttendanceStream(int eventId) {
    if (_attendanceSubscription != null) return;
    _attendanceSubscription = _supabase
        .channel('public:attendance_logs:event:$eventId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (payload) {
            _fetchDashboardData(refreshStats: true, isBackgroundUpdate: true);
          },
        )
        .subscribe();
  }

  Future<void> _handleAccessRevoked() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Your access has been revoked."),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login-screen', (route) => false);
    }
  }

  Future<void> _fetchDashboardData(
      {bool refreshStats = true, bool isBackgroundUpdate = false}) async {
    if (!mounted) return;
    if (_recentScans.isEmpty && !isBackgroundUpdate)
      setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final marshallData = await _supabase.from('event_marshalls').select('''
              event_id, 
              events (
                title, location, event_date, time_start, time_end, capacity,
                category, status, time_in_start, time_in_end, 
                time_out_start, time_out_end
              )
            ''').eq('user_id', user.id).maybeSingle();

      if (marshallData == null) {
        if (mounted) _handleAccessRevoked();
        return;
      }

      final eventRaw = marshallData['events'];
      final int eventId = marshallData['event_id'];
      final int capacity = eventRaw['capacity'] ?? 0;

      _subscribeToAttendanceStream(eventId);

      final registrations = await _supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', eventId);
      final int totalRegistered = (registrations as List).length;

      final logsResponse = await _supabase
          .from('attendance_logs')
          .select(
              '*, profiles!attendance_logs_user_id_fkey(first_name, last_name, student_id)')
          .eq('event_id', eventId)
          .order('time_in', ascending: false);

      final List<dynamic> logs = logsResponse as List<dynamic>;
      final int totalScanned = logs.length;

      List<Map<String, dynamic>> loadedScans = [];
      for (var log in logs) {
        final timeIn = DateTime.parse(log['time_in']).toLocal();
        final profile = log['profiles'];
        final bool hasLeft = log['time_out'] != null;

        loadedScans.add({
          'id': log['id'],
          'studentName': profile != null
              ? "${profile['first_name']} ${profile['last_name']}"
              : "Unknown Student",
          'studentId':
              profile != null ? (profile['student_id'] ?? "N/A") : "No ID",
          'timestamp': DateFormat('h:mm a').format(timeIn),
          'status': hasLeft ? 'Out' : 'In',
        });
      }

      if (mounted) {
        setState(() {
          _currentEvent = {
            'eventId': eventId,
            'eventName': eventRaw['title'] ?? 'Untitled Event',
            'eventDate': _formatEventDate(eventRaw['event_date'],
                eventRaw['time_start'], eventRaw['time_end']),
            'location': eventRaw['location'] ?? 'Venue TBD',
            'attendanceCount': totalScanned,
            'capacity': capacity,
            'category': eventRaw['category'] ?? 'General',
            'status': eventRaw['status'] ?? 'Upcoming',
          };
          _eventTimeSettings = {
            'in_start': eventRaw['time_in_start'],
            'in_end': eventRaw['time_in_end'],
            'out_start': eventRaw['time_out_start'],
            'out_end': eventRaw['time_out_end'],
          };
          _totalScannedCount = totalScanned;
          _capacityUtilization = capacity > 0
              ? "${((totalScanned / capacity) * 100).toStringAsFixed(1)}%"
              : "0%";
          _scanRate = totalRegistered > 0
              ? "${((totalScanned / totalRegistered) * 100).toStringAsFixed(1)}%"
              : "0%";
          _recentScans.clear();
          _recentScans.addAll(loadedScans);
          _filterScans(_searchController.text);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading data";
        });
    }
  }

  void _filterScans(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredScans = List.from(_recentScans);
      } else {
        _filteredScans = _recentScans.where((scan) {
          return scan['studentName']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              scan['studentId'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatEventDate(String? dateStr, String? startStr, String? endStr) {
    if (dateStr == null) return "Date TBD";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _startScanning() async {
    if (_currentEvent == null) return;
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          eventId: _currentEvent!['eventId'],
          eventName: _currentEvent!['eventName'],
        ),
        fullscreenDialog: true,
      ),
    );
    _fetchDashboardData(refreshStats: true);
  }

  Widget _buildStartScanningButton() {
    bool isDisabled = _isLoading || _currentEvent == null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 10),
          child: InkWell(
            onTap: isDisabled ? null : _startScanning,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryVariantDark,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.black.withOpacity(0.2), width: 1),
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                            iconName: 'qr_code_scanner',
                            color: Colors.white,
                            size: 6.w),
                        SizedBox(width: 3.w),
                        Text('Start Scanning',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final List<Map<String, dynamic>> attendanceStats = [
      {
        'title': 'Utilization %',
        'value': _capacityUtilization,
        'subtitle': 'Of Venue',
        'backgroundColor': const Color(0xFF2563EB),
        'textColor': Colors.white
      },
      {
        'title': 'Total Scanned',
        'value': _totalScannedCount.toString(),
        'subtitle': 'Present',
        'backgroundColor': const Color(0xFF059669),
        'textColor': Colors.white
      },
      {
        'title': 'Scan Rate',
        'value': _scanRate,
        'subtitle': 'Of Registered',
        'backgroundColor': const Color(0xFFF59E0B),
        'textColor': Colors.white
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Text('Attendance Statistics',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.white)),
        ),
        SizedBox(height: 1.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: attendanceStats
                .map((stat) => Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: AttendanceStatsCard(
                        title: stat['title'],
                        value: stat['value'],
                        subtitle: stat['subtitle'],
                        backgroundColor: stat['backgroundColor'],
                        textColor: stat['textColor'],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    if (_currentTabIndex == 2 && _currentEvent != null) {
      return EventReportsView(eventId: _currentEvent!['eventId']);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content space below the app bar
          SizedBox(height: 2.h),
          if (_currentEvent != null) EventHeaderCard(eventData: _currentEvent!),
          SizedBox(height: 2.h),
          _buildStartScanningButton(),
          SizedBox(height: 3.h),
          _buildAttendanceStats(),
          SizedBox(height: 3.h),
          _buildQuickActions(),
          SizedBox(height: 3.h),
          _buildRecentScansList(),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 7.w),
          child: Text('Quick Actions',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.white)),
        ),
        SizedBox(height: 1.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            children: [
              QuickActionButton(
                  title: 'Manual',
                  iconName: 'edit',
                  onTap: () => _showManualEntryDialog()),
              SizedBox(width: 3.w),
              QuickActionButton(
                  title: 'Event',
                  iconName: 'settings',
                  onTap: () => Navigator.pushNamed(
                      context, '/event-details-screen',
                      arguments: _currentEvent!['eventId'])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScansList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Scans',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: Colors.white)),
              Text('${_filteredScans.length} entries',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        _filteredScans.isEmpty
            ? SizedBox(
                height: 20.h,
                child: const Center(
                    child: Text("No scans found.",
                        style: TextStyle(color: Colors.white70))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredScans.length,
                itemBuilder: (context, index) => RecentScanItem(
                    scanData: _filteredScans[index], onUndo: () {}),
              ),
      ],
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Student ID')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentTabIndex == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentTabIndex = 1;
          _tabController.animateTo(1);
        });
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          // Increased height to allow for top padding above title
          preferredSize: const Size.fromHeight(kToolbarHeight + 82),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: AppBar(
                elevation: 0,
                centerTitle: true,
                // Increase toolbar height to shift title down
                toolbarHeight: kToolbarHeight + 30,
                backgroundColor: Colors.white.withOpacity(0.01),
                title: Padding(
                  // ADDED: Specific top padding for the title text
                  padding: EdgeInsets.only(top: 4.h),
                  child: const Text('Marshall Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 23
                      )),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    _buildTab('Scanner', 'qr_code_scanner', 0),
                    _buildTab('Dashboard', 'dashboard', 1),
                    _buildTab('Reports', 'analytics', 2),
                  ],
                  onTap: (index) {
                    setState(() => _currentTabIndex = index);
                    if (index == 0) _startScanning();
                  },
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset('assets/images/Background_shooting_star.json',
                  fit: BoxFit.cover),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: _isLoading && _currentEvent == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBodyContent(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _supabase.auth.signOut().then(
              (_) => Navigator.pushReplacementNamed(context, '/login-screen')),
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.logout, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTab(String label, String icon, int index) {
    bool isSelected = _currentTabIndex == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
              iconName: icon,
              size: 4.w,
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : Colors.white60),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.white : Colors.white60)),
        ],
      ),
    );
  }
}