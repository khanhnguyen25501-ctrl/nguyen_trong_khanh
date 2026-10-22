import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/child_device_model.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'child_detail_screen.dart';
import 'advanced_features_screen.dart';
import 'login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  bool _isLoadingKids = true;
  bool _isGettingGps = false;
  List<ChildDeviceModel> _kids = [];
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadKidsAndAlerts();
  }

  Future<void> _loadKidsAndAlerts() async {
    setState(() => _isLoadingKids = true);
    final userId = _apiService.currentUser?.userId ?? 1;
    final kidsList = await _apiService.getMyKids(userId);
    List<AlertModel> alertsList = [];
    if (kidsList.isNotEmpty) {
      alertsList = await _apiService.getAlertsByDevice(kidsList.first.deviceId);
    }

    setState(() {
      _kids = kidsList;
      _alerts = alertsList;
      _isLoadingKids = false;
    });
  }

  void _showAddChildDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thiết bị trẻ em mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên của bé (vd: Bé An, iPad của Bé)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();

              final userId = _apiService.currentUser?.userId ?? 1;
              final ok = await _apiService.createChild(userId, name);
              if (ok && mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã thêm thiết bị trẻ em mới!')),
                );
                _loadKidsAndAlerts();
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // Hàm xử lý lấy GPS thật trên điện thoại
  Future<void> _handleUpdateLocation(int deviceId) async {
    setState(() => _isGettingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật tính năng GPS trên điện thoại!')),
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
            const SnackBar(content: Text('Quyền định vị bị từ chối trong Cài đặt!')),
          );
        }
        setState(() => _isGettingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final ok = await _apiService.updateLocation(deviceId, position.latitude, position.longitude);
      setState(() => _isGettingGps = false);

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🟢 Đã cập nhật GPS THẬT (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}) lên Server!',
            ),
          ),
        );
        _loadKidsAndAlerts();
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

  Future<void> _handleLogout() async {
    await _apiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Phụ Huynh: ${user?.fullName ?? "Người dùng"}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadKidsAndAlerts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildKidsTab()
          : _currentIndex == 1
          ? _buildGpsTab()
          : _currentIndex == 2
          ? _buildAlertsTab()
          : const AdvancedFeaturesScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care),
            label: 'Thiết bị Trẻ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Vị trí GPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Cảnh báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Tính năng Mở rộng',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _showAddChildDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm trẻ em'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      )
          : null,
    );
  }

  Widget _buildKidsTab() {
    if (_isLoadingKids) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Chưa có thiết bị trẻ em nào'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showAddChildDialog,
              child: const Text('Thêm thiết bị đầu tiên'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kids.length,
      itemBuilder: (context, index) {
        final kid = _kids[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kid.isLocked ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(
                        kid.isLocked ? Icons.lock : Icons.phonelink_setup,
                        color: kid.isLocked ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kid.childName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ID: #${kid.deviceId} | Màn hình: ${kid.isLocked ? "ĐANG KHÓA" : "ĐANG MỞ"}',
                            style: TextStyle(
                              color: kid.isLocked ? Colors.red : Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Wrap để tránh lỗi vỡ tràn giao diện (Overflow)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _isGettingGps ? null : () => _handleUpdateLocation(kid.deviceId),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Cập nhật GPS'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildDetailScreen(child: kid),
                          ),
                        );
                        if (updated == true) {
                          _loadKidsAndAlerts();
                        }
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Quản lý / Lock / AppLimits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGpsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bản đồ Giám sát Vị trí Thời gian thực (GPS Thật)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 80, color: Colors.indigo),
                        const SizedBox(height: 12),
                        const Text(
                          'Tọa độ GPS Thời gian thực từ Điện thoại',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kids.isNotEmpty
                              ? 'Lat: ${_kids.first.latitude ?? 10.762622}, Lng: ${_kids.first.longitude ?? 106.660172}'
                              : 'Lat: 10.762622, Lng: 106.660172',
                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isGettingGps
                              ? null
                              : () {
                            if (_kids.isNotEmpty) {
                              _handleUpdateLocation(_kids.first.deviceId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chưa có thiết bị nào để cập nhật GPS!')),
                              );
                            }
                          },
                          icon: _isGettingGps
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.gps_fixed),
                          label: Text(_isGettingGps ? 'Đang lấy GPS Thật...' : 'Lấy GPS Thật & Gửi lên Backend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🟢 GPS Live Online',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử Cảnh báo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_kids.isNotEmpty) {
                    await _apiService.reportAlert(
                      deviceId: _kids.first.deviceId,
                      alertType: 'Cảnh báo Tiếng ồn vượt ngưỡng 85dB',
                      valueRecorded: 88.5,
                    );
                    _loadKidsAndAlerts();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi cảnh báo mới lên API Backend!')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.warning, size: 16),
                label: const Text('Gửi Cảnh báo Mẫu'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _alerts.isEmpty
                ? const Center(child: Text('Chưa có cảnh báo nào'))
                : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                    ),
                    title: Text(alert.alertType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Ghi nhận: ${alert.valueRecorded} | ${alert.createdAt.hour}:${alert.createdAt.minute} ${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}