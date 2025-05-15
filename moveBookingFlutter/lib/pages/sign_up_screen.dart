import 'package:flutter/material.dart';
import 'package:my_app/service/auth_services.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Mật khẩu xác nhận không khớp.");
      return;
    }

    final result = await _authService.signUpWithEmail(email, password);
    if (mounted) {
      if (result == null) {
        _showMessage("Đăng ký thất bại. Vui lòng thử lại.");
      } else {
        _showMessage("Đăng ký thành công! Hãy đăng nhập.", isSuccess: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          }
        });

      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
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
              'images/signin.png', // Đảm bảo ảnh đúng vị trí
              fit: BoxFit.cover,
            ),
          ),

          // Nội dung đăng ký
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
                      "Đăng ký",
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
                          fontWeight: FontWeight.bold, // Chữ đậm để dễ nhìn hơn
                        ),
                        filled: true,
                        fillColor: Colors.white, // Màu nền khác biệt
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.purple, width: 2), // Viền màu xanh
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
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: Colors.white, // Màu nền khác biệt
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.purple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

// Ô nhập lại mật khẩu
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        labelStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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


                    // Nút đăng ký
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _signUp,
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Chuyển sang màn hình đăng nhập
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Đã có tài khoản? ",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            TextSpan(
                              text: "Đăng nhập ngay",
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