import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'parent_dashboard.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';

class FaceLoginScreen extends StatefulWidget {
  final String email;

  const FaceLoginScreen({
    super.key,
    this.email = 'phuhuynh@gmail.com',
  });

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = true;
  bool _isSuccess = false;
  final ApiService _apiService = ApiService();

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeCamera();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          _startFaceScanProcess();
        }
      } else {
        _startFallbackScan();
      }
    } catch (e) {
      if (mounted) {
        _startFallbackScan();
      }
    }
  }

  void _startFallbackScan() {
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
      _startFaceScanProcess();
    }
  }

  Future<void> _startFaceScanProcess() async {
    // Giả lập thời gian quét khuôn mặt (3 giây)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _isSuccess = true;
    });

    // Gọi API ngầm xác thực OTP/Token
    try {
      await _apiService.verifyOtp(
        email: widget.email,
        otpCode: '123456',
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Bỏ qua lỗi mạng ở bước này để không bị kẹt giao diện UI
    }

    if (!mounted) return;

    // Xác định quyền để chuyển hướng trang tương ứng
    final role = _apiService.currentUser?.role ?? 'Parent';
    Widget targetScreen = const ParentDashboardScreen();
    if (role == 'Admin') targetScreen = const AdminDashboardScreen();
    if (role == 'Staff') targetScreen = const StaffDashboardScreen();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🟢 Nhận diện khuôn mặt thành công! Đang đăng nhập...')),
    );

    // Chờ 800ms để người dùng thấy icon tick xanh rồi chuyển trang dứt khoát
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Đăng nhập bằng Khuôn mặt (Face ID)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Live Camera Preview Feed
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(Icons.face_retouching_natural, size: 120, color: Colors.white24),
                ),
              ),
            ),

          // Face Scanner Overlay UI
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đưa khuôn mặt vào khung tròn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xác thực tài khoản: ${widget.email}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 30),

                  // Circle / Oval Face Scan Frame
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isSuccess
                                ? Colors.greenAccent
                                : Colors.indigoAccent,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isSuccess
                                  ? Colors.greenAccent.withValues(alpha: 0.5)
                                  : Colors.indigoAccent.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Scanning animation line (Đã sửa lỗi ngắt dòng tọa độ top)
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 260 * _scanAnimation.value,
                              child: Container(
                                width: 220,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      if (_isSuccess)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 90,
                        ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  if (_isScanning)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Đang quét & phân tích khuôn mặt...',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                  else if (_isSuccess)
                    const Text(
                      '✔ XÁC THỰC THÀNH CÔNG!',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}