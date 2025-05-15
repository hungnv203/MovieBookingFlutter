import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/bottomnav.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/pages/customer_screen/payment_page.dart';
import 'package:my_app/pages/customer_screen/ticketPage.dart';
import 'package:my_app/pages/sign_in_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInScreen(),
      routes: {
        '/ticket': (context) => TicketPage(),
        '/payment': (context) => TicketDetailScreen(bookingId: ''),
      },
    );
  }
}

