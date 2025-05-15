import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminCinemaPage.dart';
import 'package:my_app/pages/admin_screen/AdminHomePage.dart';
import 'package:my_app/pages/customer_screen/bottomnav.dart';
import 'package:my_app/service/auth_services.dart';
import 'sign_up_screen.dart'; // Import màn hình đăng ký

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email và mật khẩu không được để trống.")),
        );
      }
      return;
    }

    final result = await _authService.signInWithEmail(email, password);
    if (mounted) _handleSignIn(result);
  }

  Future<void> _signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (mounted) _handleSignIn(result);
  }

  void _handleSignIn(Map<String, dynamic>? result) {
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thất bại. Vui lòng thử lại.")),
        );
      }
      return;
    }

    final String role = result['role'];
    if (!mounted) return;

    Widget nextScreen = role == 'admin' ? AdminHomePage() : Bottomnav();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
          (Route<dynamic> route) => false, // Xóa toàn bộ stack trước đó
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hình nền
          Positioned.fill(
            child: Image.asset(
              'images/signin.png',  // Đảm bảo file ảnh đúng vị trí
              fit: BoxFit.cover,
            ),
          ),

          // Nội dung đăng nhập
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.9 * 255).toInt()), // Nền mờ
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Đăng nhập",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Ô nhập email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Colors.black, // Màu chữ đậm hơn
                          fontWeight: FontWeight.bold, // Chữ đậm hơn
                        ),
                        filled: true, // Bật chế độ màu nền
                        fillColor: Colors.white, // Màu nền khác biệt với nền tổng thể
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.purple, width: 2), // Viền màu khác
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ô nhập mật khẩu
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: TextStyle(
                          color: Colors.black, // Màu chữ đậm hơn
                          fontWeight: FontWeight.bold, // Chữ đậm hơn
                        ),
                        filled: true,
                        fillColor: Colors.white, // Màu nền khác biệt
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.purple, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nút đăng nhập
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _signIn,
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Nút đăng nhập bằng Google
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Màu nền trắng cho nút
                        side: BorderSide(color: Colors.blueAccent, width: 2), // Viền màu xanh
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _signInWithGoogle,
                      icon: Image.asset(
                        'images/wave.png',
                        width: 24,
                        height: 24,
                        color: Colors.white, // Màu trùng với nền
                        colorBlendMode: BlendMode.modulate,
                      ),
                      label: const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Màu chữ đen cho độ tương phản cao
                        ),
                      ),
                    ),


                    // Chuyển sang màn hình đăng ký
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()), // Điều hướng sang màn hình đăng ký
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Chưa có tài khoản? ",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            TextSpan(
                              text: "Đăng ký ngay",
                              style: TextStyle(
                                fontSize: 16, // Chữ to hơn một chút
                                color: Colors.red,
                                fontWeight: FontWeight.bold, // Chữ đậm
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}