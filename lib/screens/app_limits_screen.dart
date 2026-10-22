import 'package:flutter/material.dart';
import '../models/app_limit_model.dart';
import '../services/api_service.dart';

class AppLimitsScreen extends StatefulWidget {
  final int deviceId;

  const AppLimitsScreen({super.key, required this.deviceId});

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<AppLimitModel> _limits = [];

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    setState(() => _isLoading = true);
    final list = await _apiService.getAppLimits(widget.deviceId);
    setState(() {
      _limits = list;
      _isLoading = false;
    });
  }

  void _showAddLimitDialog() {
    final appNameController = TextEditingController();
    final packageNameController = TextEditingController();
    final minutesController = TextEditingController(text: '60');
    bool isBlocked = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thêm giới hạn ứng dụng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: appNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ứng dụng (vd: YouTube, TikTok)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: packageNameController,
                  decoration: const InputDecoration(
                    labelText: 'Mã Package (vd: com.google.youtube)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời lượng cho phép (Phút/Ngày)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Chặn hoàn toàn'),
                  value: isBlocked,
                  onChanged: (val) => setModalState(() => isBlocked = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final appName = appNameController.text.trim();
                final pkg = packageNameController.text.trim();
                final mins = int.tryParse(minutesController.text.trim()) ?? 60;

                if (appName.isEmpty) return;

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();

                final ok = await _apiService.createAppLimit(
                  deviceId: widget.deviceId,
                  appName: appName,
                  packageName: pkg.isNotEmpty ? pkg : 'com.app.$appName',
                  allowedMinutesPerDay: mins,
                  isBlocked: isBlocked,
                );

                if (ok && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã thêm giới hạn ứng dụng mới!')),
                  );
                  _loadLimits();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLimitDialog(AppLimitModel limit) {
    final minutesController = TextEditingController(text: limit.allowedMinutesPerDay.toString());
    bool isBlocked = limit.isBlocked;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Chỉnh sửa: ${limit.appName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Thời gian tối đa (Phút/ngày)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Chặn hoàn toàn app này'),
                value: isBlocked,
                onChanged: (val) => setModalState(() => isBlocked = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mins = int.tryParse(minutesController.text.trim()) ?? 30;
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();

                final ok = await _apiService.updateAppLimit(
                  limitId: limit.limitId,
                  allowedMinutesPerDay: mins,
                  isBlocked: isBlocked,
                );

                if (ok && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật giới hạn thành công!')),
                  );
                  _loadLimits();
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteLimit(int limitId) async {
    final ok = await _apiService.deleteAppLimit(limitId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa giới hạn app')),
      );
      _loadLimits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Giới Hạn Ứng Dụng (Device #${widget.deviceId})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm app cần giới hạn',
            onPressed: _showAddLimitDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _limits.isEmpty
              ? const Center(child: Text('Chưa có ứng dụng nào bị đặt giới hạn'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _limits.length,
                  itemBuilder: (context, index) {
                    final item = _limits[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isBlocked ? Colors.red.shade100 : Colors.indigo.shade100,
                          child: Icon(
                            item.isBlocked ? Icons.block : Icons.timer,
                            color: item.isBlocked ? Colors.red : Colors.indigo,
                          ),
                        ),
                        title: Text(
                          item.appName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          item.isBlocked
                              ? 'Trạng thái: Bị CHẶN HOÀN TOÀN\nPackage: ${item.packageName}'
                              : 'Cho phép: ${item.allowedMinutesPerDay} phút/ngày\nPackage: ${item.packageName}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditLimitDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _handleDeleteLimit(item.limitId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLimitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giới hạn App'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
