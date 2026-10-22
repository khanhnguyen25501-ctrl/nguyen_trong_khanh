import 'package:flutter/material.dart';
import '../models/child_device_model.dart';
import '../services/api_service.dart';
import 'app_limits_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final ChildDeviceModel child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final ApiService _apiService = ApiService();
  late bool _isLocked;
  bool _isLoading = false;
  Map<String, dynamic>? _latestLoc;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.child.isLocked;
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await _apiService.getLatestLocation(widget.child.deviceId);
    if (mounted) {
      setState(() => _latestLoc = loc);
    }
  }

  Future<void> _handleToggleLock() async {
    setState(() => _isLoading = true);
    final success = await _apiService.toggleLock(widget.child.deviceId);
    setState(() {
      _isLoading = false;
      if (success) {
        _isLocked = !_isLocked;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLocked
                ? 'Đã KHÓA màn hình thiết bị ${widget.child.childName}'
                : 'Đã MỞ KHÓA thiết bị ${widget.child.childName}',
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thiết bị trẻ em'),
        content: Text('Bạn có chắc chắn muốn xóa thiết bị ${widget.child.childName} khỏi danh sách?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _apiService.deleteChild(widget.child.deviceId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thiết bị thành công')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Chi tiết: ${widget.child.childName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Xóa thiết bị',
            onPressed: _handleDeleteDevice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _isLocked ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(
                        _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 40,
                        color: _isLocked ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.child.childName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID Thiết bị: #${widget.child.deviceId}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isLocked ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isLocked ? Colors.red : Colors.green),
                      ),
                      child: Text(
                        _isLocked ? 'Trạng thái: Màn hình đang bị KHÓA' : 'Trạng thái: Đang MỞ / Hoạt động',
                        style: TextStyle(
                          color: _isLocked ? Colors.red.shade900 : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleToggleLock,
                        icon: Icon(_isLocked ? Icons.lock_open : Icons.lock),
                        label: Text(_isLocked ? 'MỞ KHÓA MÀN HÌNH' : 'KHÓA MÀN HÌNH KHẨN CẤP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLocked ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Vị trí GPS mới nhất',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Vĩ độ (Lat): ${_latestLoc?['latitude'] ?? widget.child.latitude ?? 10.762622}'),
                    Text('Kinh độ (Lng): ${_latestLoc?['longitude'] ?? widget.child.longitude ?? 106.660172}'),
                    Text('Thời gian ghi nhận: ${_latestLoc?['recordedAt'] ?? "Vừa xong"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppLimitsScreen(deviceId: widget.child.deviceId),
                  ),
                );
              },
              icon: const Icon(Icons.apps_outage),
              label: const Text('QUẢN LÝ GIỚI HẠN ỨNG DỤNG (CRUD AppLimits)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
