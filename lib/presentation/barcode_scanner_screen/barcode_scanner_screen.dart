import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import './widgets/scanning_reticle_widget.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  const BarcodeScannerScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController _scannerController;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isControllerInitialized = false;
  bool _isScanning = true;
  bool _isProcessing = false;
  bool _isFlashlightOn = false;
  int _sessionScanCount = 0;

  String _marshallName = "Loading...";
  late String _dbEventTitle;

  Map<String, String?> _eventTimeSettings = {};

  @override
  void initState() {
    super.initState();
    _dbEventTitle = widget.eventName;
    _initScanner();
    _fetchMarshallInfo();
  }

  Future<void> _fetchMarshallInfo() async {
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        debugPrint("--- FETCHING MARSHALL & EVENT INFO ---");
        final data = await _supabase
            .from('event_marshalls')
            .select('''
              profiles(first_name, last_name), 
              events(
                title, 
                time_in_start, 
                time_in_end, 
                time_out_start, 
                time_out_end
              )
            ''')
            .eq('event_id', widget.eventId)
            .eq('user_id', user.id)
            .maybeSingle();

        debugPrint("Raw Data from DB: $data");

        if (mounted) {
          if (data != null) {
            if (data['profiles'] != null) {
              final profile = data['profiles'];
              setState(() {
                _marshallName =
                    "${profile['first_name']} ${profile['last_name']}";
              });
            }

            if (data['events'] != null) {
              final eventData = data['events'];
              setState(() {
                _dbEventTitle = eventData['title'] ?? widget.eventName;
                _eventTimeSettings = {
                  'in_start': eventData['time_in_start'],
                  'in_end': eventData['time_in_end'],
                  'out_start': eventData['time_out_start'],
                  'out_end': eventData['time_out_end'],
                };
              });
              debugPrint("Success: Pulled title and time settings from DB");
            }
          } else {
            setState(() => _marshallName = "Not Assigned");
            debugPrint(
                "No link found between User ${user.id} and Event ${widget.eventId}");
          }
        }
      } catch (e) {
        debugPrint("Error fetching info: $e");
      }
    }
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
      );
      setState(() => _isControllerInitialized = true);
    }
  }

  @override
  void dispose() {
    if (_isControllerInitialized) _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processScan(String scannedCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    HapticFeedback.mediumImpact();

    try {
      String lookupId = scannedCode.trim();
      if (lookupId.toUpperCase().startsWith('D') ||
          lookupId.toUpperCase().startsWith('S')) {
        lookupId = lookupId.substring(1);
      }
      debugPrint("🔍 Processing Scan for Student ID: $lookupId");

      final profileData = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('student_id', lookupId)
          .maybeSingle();

      if (profileData == null) {
        debugPrint("❌ Profile not found for ID: $lookupId");
        if (mounted) {
          await _showResultDialog(
              false, "Student ID '$lookupId' not found in profiles.");
        }
        return;
      }

      final String targetUserId = profileData['id'];
      final String studentName =
          "${profileData['first_name']} ${profileData['last_name']}";
      debugPrint("✅ Found Profile: $studentName (UUID: $targetUserId)");

      final registration = await _supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', widget.eventId)
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (registration == null) {
        if (mounted) {
          await _showResultDialog(
              false, "$studentName is NOT registered for this event.");
        }
        return;
      }

      final existingLog = await _supabase
          .from('attendance_logs')
          .select()
          .eq('event_id', widget.eventId)
          .eq('user_id', targetUserId)
          .maybeSingle();

      final now = TimeOfDay.now();

      if (existingLog == null) {
        if (!_isWithinTimeWindow(now, _eventTimeSettings['in_start'],
            _eventTimeSettings['in_end'])) {
          if (mounted) {
            await _showResultDialog(false,
                "Time-In is CLOSED.\nAllowed: ${_formatTime(_eventTimeSettings['in_start'])} - ${_formatTime(_eventTimeSettings['in_end'])}");
          }
          return;
        }

        debugPrint("🚀 Inserting Attendance Log (Time In)...");
        await _supabase.from('attendance_logs').insert({
          'event_id': widget.eventId,
          'user_id': targetUserId,
          'time_in': DateTime.now().toIso8601String(),
          'status': 'Present',
          'scanned_by': _supabase.auth.currentUser?.id,
        });

        _sessionScanCount++;
        if (mounted) {
          await _showResultDialog(true, "Time-In Success: $studentName");
        }
      } else if (existingLog['time_out'] == null) {
        if (!_isWithinTimeWindow(now, _eventTimeSettings['out_start'],
            _eventTimeSettings['out_end'])) {
          if (mounted) {
            await _showResultDialog(false,
                "Time-Out is CLOSED.\nAllowed: ${_formatTime(_eventTimeSettings['out_start'])} - ${_formatTime(_eventTimeSettings['out_end'])}");
          }
          return;
        }

        debugPrint("🚀 Updating Attendance Log (Time Out)...");
        await _supabase.from('attendance_logs').update({
          'time_out': DateTime.now().toIso8601String(),
        }).eq('id', existingLog['id']);

        if (mounted) {
          await _showResultDialog(true, "Time-Out Success: $studentName");
        }
      } else {
        if (mounted) {
          await _showResultDialog(
              false, "$studentName has already completed attendance.");
        }
      }
    } catch (e) {
      debugPrint("🔥 CRITICAL ERROR: $e");
      if (mounted) {
        await _showResultDialog(false, "System Error: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScanning = true;
        });
      }
    }
  }

  // --- TIME VALIDATION HELPERS ---
  bool _isWithinTimeWindow(TimeOfDay now, String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return true;

    try {
      final start = _parseTime(startStr);
      final end = _parseTime(endStr);
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } catch (e) {
      debugPrint("Time parsing error: $e");
      return true;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "N/A";
    try {
      final time = _parseTime(timeStr);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _showResultDialog(bool isSuccess, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isSuccess ? Colors.green[50] : Colors.red[50],
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 2.w),
              Text(
                isSuccess ? "Success" : "Alert",
                style: TextStyle(
                  color: isSuccess ? Colors.green[900] : Colors.red[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content:
              Text(message, style: AppTheme.lightTheme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Next Scan",
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isControllerInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (!_isScanning || _isProcessing) return;
                    if (capture.barcodes.isEmpty) return;
                    final code = capture.barcodes.first.rawValue;
                    if (code != null && code.isNotEmpty) _processScan(code);
                  },
                  fit: BoxFit.cover,
                ),
                if (_isScanning) const ScanningReticleWidget(isScanning: true),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 20,
                      left: 20,
                      right: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _marshallName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _dbEventTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFlashlightOn
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await _scannerController.toggleTorch();
                                setState(
                                    () => _isFlashlightOn = !_isFlashlightOn);
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        "Scanned in Session: $_sessionScanCount",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
    );
  }
}
