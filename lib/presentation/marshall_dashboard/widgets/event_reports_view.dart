import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';

class EventReportsView extends StatefulWidget {
  final int eventId;

  const EventReportsView({super.key, required this.eventId});

  @override
  State<EventReportsView> createState() => _EventReportsViewState();
}

class _EventReportsViewState extends State<EventReportsView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _searchQuery = "";
  List<Map<String, dynamic>> _reportData = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      setState(() => _isLoading = true);

      final List<dynamic> registrations = await _supabase
          .from('event_registrations')
          .select('user_id, profiles(first_name, last_name, student_id)')
          .eq('event_id', widget.eventId);

      final List<dynamic> logs = await _supabase
          .from('attendance_logs')
          .select('user_id, time_in, time_out')
          .eq('event_id', widget.eventId);

      List<Map<String, dynamic>> processedReport = [];

      for (var reg in registrations) {
        final profile = reg['profiles'];
        final userId = reg['user_id'];

        if (profile != null && userId != null) {
          final matchingLogs = logs.where((log) => log['user_id'] == userId);
          final logEntry = matchingLogs.isNotEmpty ? matchingLogs.first : null;

          String status = 'Absent';

          if (logEntry != null) {
            final timeIn = logEntry['time_in'];
            final timeOut = logEntry['time_out'];

            if (timeIn != null && timeOut != null) {
              status = 'Present';
            } else if (timeIn != null || timeOut != null) {
              status = 'Incomplete';
            }
          }

          processedReport.add({
            'name': "${profile['first_name']} ${profile['last_name']}",
            'student_id': profile['student_id'] ?? 'N/A',
            'status': status,
          });
        }
      }

      processedReport.sort((a, b) {
        const priority = {'Incomplete': 0, 'Present': 1, 'Absent': 2};
        return (priority[a['status']] ?? 3)
            .compareTo(priority[b['status']] ?? 3);
      });

      if (mounted) {
        setState(() {
          _reportData = processedReport;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching report: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Incomplete':
        return Colors.orange;
      case 'Absent':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _reportData.where((student) {
      final query = _searchQuery.toLowerCase();
      return student['name'].toString().toLowerCase().contains(query) ||
          student['student_id'].toString().toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search Name or ID...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 0, horizontal: 2.w),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryChip('Present', Colors.green,
                  _reportData.where((e) => e['status'] == 'Present').length),
              _buildSummaryChip('Incomplete', Colors.orange,
                  _reportData.where((e) => e['status'] == 'Incomplete').length),
              _buildSummaryChip('Absent', Colors.red,
                  _reportData.where((e) => e['status'] == 'Absent').length),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayedList.isEmpty
                  ? const Center(child: Text("No students found."))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: displayedList.length,
                      itemBuilder: (context, index) {
                        final student = displayedList[index];
                        final statusColor = _getStatusColor(student['status']);

                        return Container(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: statusColor.withOpacity(0.1),
                                child: Text(
                                  student['name'].isNotEmpty
                                      ? student['name'][0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'],
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      student['student_id'],
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 3.w, vertical: 0.6.h),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  student['status'],
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.5.w),
        Text(
          "$count $label",
          style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white),
        ),
      ],
    );
  }
}
