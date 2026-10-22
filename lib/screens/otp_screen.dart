import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'parent_dashboard.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String demoOtp;

  const OtpScreen({
    super.key,
    required this.email,
    this.demoOtp = '123456',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _handleVerifyOtp() async {
    final otpCode = _otpController.text.trim();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP gồm 6 chữ số')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.verifyOtp(
      email: widget.email,
      otpCode: otpCode,
    );
    setState(() => _isLoading = false);

    if (res['success'] == true && mounted) {
      final role = _apiService.currentUser?.role ?? 'Parent';

      Widget targetScreen = const ParentDashboardScreen();
      if (role == 'Admin') {
        targetScreen = const AdminDashboardScreen();
      } else if (role == 'Staff') {
        targetScreen = const StaffDashboardScreen();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thành công với vai trò: $role')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Mã OTP không đúng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Xác thực OTP'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.mark_email_read_outlined,
              size: 72,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập mã OTP 6 chữ số',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã xác thực đã được gửi đến email:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mã OTP mặc định cho kiểm tra: ${widget.demoOtp}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 12,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOtp,
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
                      'XÁC NHẬN OTP & VÀO APP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
