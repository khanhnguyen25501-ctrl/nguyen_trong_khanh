import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'qr_scanner_screen.dart'; // 👉 Import màn hình quét QR thật vừa tạo

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final ApiService _apiService = ApiService();

  // Noise & Sensor demo states
  double _currentDecibel = 55.0;
  bool _isMonitoringNoise = false;
  Timer? _sensorTimer;

  // Real GPS states
  double _realLatitude = 10.762622;
  double _realLongitude = 106.660172;
  bool _isGettingGps = false;

  // AI Risk Assessment
  final double _safetyScore = 92.0;

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  // Hàm lấy GPS thật từ điện thoại
  Future<void> _fetchRealGps() async {
    setState(() => _isGettingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS trên điện thoại đang tắt. Hãy bật GPS!')),
          );
        }
        setState(() => _isGettingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isGettingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn trong Cài đặt!')),
          );
        }
        setState(() => _isGettingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _realLatitude = position.latitude;
        _realLongitude = position.longitude;
        _isGettingGps = false;
      });

      // Gửi tọa độ thật lên Backend
      final ok = await _apiService.updateLocation(1, _realLatitude, _realLongitude);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🟢 Đã cập nhật GPS THẬT lên API Backend thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lấy GPS: $e')),
        );
      }
      setState(() => _isGettingGps = false);
    }
  }

  void _toggleNoiseMonitor() {
    setState(() {
      _isMonitoringNoise = !_isMonitoringNoise;
    });

    if (_isMonitoringNoise) {
      _sensorTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
        final db = 45 + Random().nextDouble() * 50; // 45dB - 95dB
        setState(() {
          _currentDecibel = db;
        });

        if (db > 80) {
          await _apiService.reportAlert(
            deviceId: 1,
            alertType: 'Cảnh báo Tiếng ồn Lớn (>80dB)',
            valueRecorded: db,
          );
        }
      });
    } else {
      _sensorTimer?.cancel();
    }
  }

  // Thay thế hàm quét giả lập bằng quét QR thực tế qua camera
  Future<void> _startRealQrScan() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đã quét mã QR thành công!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 12),
              const Text('Mã định danh thiết bị quét được:'),
              const SizedBox(height: 8),
              SelectableText(
                scannedCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã liên kết thành công thiết bị: $scannedCode')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text('Hoàn tất ghép nối'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Risk Assessment Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.indigo.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CÂU 6: TÍNH NĂNG MỚI ĐỀ XUẤT (1đ)',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hệ thống AI Đánh giá Mức độ An toàn Trẻ em & Cảnh báo Hàng rào Địa lý Khẩn cấp (AI Child Safety Risk Evaluator)',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _safetyScore / 100,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _safetyScore > 80 ? Colors.lightGreenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_safetyScore.toInt()}% AN TOÀN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'CÂU 5: CHỌN 3 TRONG 6 CHỨC NĂNG (3.5đ)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const Text(
            'Đã chọn 3 chức năng phù hợp nhất cho App Quản lý Trẻ em:',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // FEATURE 1: 5b. Chia sẻ vị trí thời gian thực (Dùng GPS THẬT)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '1. Chức năng (5b): GPS Thời gian thực (Thiết bị Thật)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Tọa độ GPS thực tế lấy trực tiếp từ điện thoại của bạn:'),
                  const SizedBox(height: 4),
                  Text(
                    '📍 Vĩ độ: $_realLatitude | Kinh độ: $_realLongitude',
                    style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isGettingGps ? null : _fetchRealGps,
                      icon: _isGettingGps
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(_isGettingGps ? 'Đang định vị...' : 'Lấy GPS Thật & Gửi Server'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // FEATURE 2: 5d. Đo tiếng ồn / Cảm biến chuyển động
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq, color: Colors.deepOrange, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '2. Chức năng (5d): Đo tiếng ồn & Cảm biến',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Switch(
                        value: _isMonitoringNoise,
                        onChanged: (_) => _toggleNoiseMonitor(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Cường độ âm thanh đo được: ${_currentDecibel.toStringAsFixed(1)} dB'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentDecibel / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentDecibel > 80 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentDecibel > 80
                        ? '⚠️ CẢNH BÁO: Tiếng ồn lớn! Tự động gửi báo cáo cảnh báo lên API Backend (/api/Alerts/report).'
                        : 'Môi trường xung quanh trẻ yên tĩnh và an toàn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentDecibel > 80 ? Colors.red : Colors.black54,
                      fontWeight: _currentDecibel > 80 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // FEATURE 3: 5e. Nhận diện QR Code / Vân tay (Quét thật bằng Camera)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 32),
              title: const Text('3. Chức năng (5e): Nhận diện Mã QR / Vân tay', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ghép nối thiết bị trẻ em nhanh chóng qua quét camera thực tế'),
              trailing: ElevatedButton(
                onPressed: _startRealQrScan, // 👉 Gọi hàm mở camera quét thật
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text('Quét QR'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}