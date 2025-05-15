import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminCinemaPage.dart';
import 'package:my_app/pages/admin_screen/AdminMoviePage.dart';
import 'package:my_app/pages/sign_in_screen.dart';

class AdminHomePage  extends StatefulWidget{
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>{
  String userName='';
  Future<void> _logout(BuildContext context) async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Đăng xuất"),
          content: Text("Bạn có chắc chắn muốn đăng xuất không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Đóng popup, không đăng xuất
              },
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Xác nhận đăng xuất
              },
              child: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // 🟢 Nếu dùng Firebase Authentication
      await FirebaseAuth.instance.signOut();
      // Chuyển về màn hình đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignInScreen(),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          
          children: [
            Icon(Icons.waving_hand, color: Colors.orangeAccent),
            SizedBox(width: 5),
            Text("Hello  ", style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              userName,
              style: TextStyle(color: Colors.orangeAccent, fontSize: 18),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminCinemaPage()),
                );
              },
              child: Text('Manage Cinemas'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminMoviepage()),
                );
              },
              child: Text('Manage Movies'),
            ),
          ],
        ),
      ),
    );
  }
}