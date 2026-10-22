import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'face_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'phuhuynh@gmail.com');
  final _passwordController = TextEditingController(text: '123456');
  final _serverUrlController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _apiService.initSession();
    _serverUrlController.text = _apiService.baseUrl;
  }

  void _showServerConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình Backend API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập địa chỉ Backend Server (HTTPS / HTTP):'),
            const SizedBox(height: 12),
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'API Base URL',
                hintText: 'https://10.0.2.2:7225',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Cáp USB (localhost)'),
                  selected: _serverUrlController.text.contains('localhost'),
                  onSelected: (_) {
                    setState(() {
                      _serverUrlController.text = 'https://localhost:7225';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Wi-Fi IP (192.168.1.8)'),
                  selected: _serverUrlController.text.contains('192.168.1.8'),
                  onSelected: (_) {
                    setState(() {
                      _serverUrlController.text = 'https://192.168.1.8:7225';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Giả lập (10.0.2.2)'),
                  selected: _serverUrlController.text.contains('10.0.2.2'),
                  onSelected: (_) {
                    setState(() {
                      _serverUrlController.text = 'https://10.0.2.2:7225';
                    });
                  },
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _apiService.setBaseUrl(_serverUrlController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã cập nhật Server URL: ${_apiService.baseUrl}')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Email và Mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.login(email: email, password: password);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đã gửi mã OTP')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            demoOtp: res['otp'] ?? '123456',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đăng nhập thất bại')),
      );
    }
  }

  // Open Real Camera Face ID Login (Requirement 5a)
  void _handleFaceIdLogin() {
    final email = _emailController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceLoginScreen(
          email: email.isNotEmpty ? email : 'phuhuynh@gmail.com',
        ),
      ),
    );
  }

  void _fillQuickDemo(String email, String pass) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('An toàn Trẻ em - Đăng nhập'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            tooltip: 'Cấu hình URL Server',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 64,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Child Safety Platform',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Text(
              'Quản lý điện thoại & Bảo vệ trẻ em thông minh',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email / Tên đăng nhập',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'ĐĂNG NHẬP (Gửi mã OTP)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleFaceIdLogin,
              icon: const Icon(Icons.face_retouching_natural, color: Colors.indigo),
              label: const Text(
                'Đăng nhập bằng Khuôn mặt (Face ID)',
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.indigo, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản? '),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            const Text(
              'Đăng nhập nhanh theo vai trò (Demo/Kiểm tra):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: const Text('Phụ huynh'),
                  onPressed: () => _fillQuickDemo('phuhuynh@gmail.com', '123456'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.support_agent, size: 16),
                  label: const Text('Nhân viên (Staff)'),
                  onPressed: () => _fillQuickDemo('staff@gmail.com', '123456'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text('Quản trị (Admin)'),
                  onPressed: () => _fillQuickDemo('admin@gmail.com', '123456'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
