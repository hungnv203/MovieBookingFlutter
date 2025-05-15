import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class TicketDetailScreen extends StatefulWidget {
  final String bookingId;
  const TicketDetailScreen({super.key, required this.bookingId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingLink(uri);
      }
    });

    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        _handleIncomingLink(uri);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'my_app') {
      if (uri.host == 'success') {
        _updatePaymentStatus('Đã thanh toán');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thanh toán thành công!')),
        );
      } else if (uri.host == 'cancel') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hủy thanh toán')),
        );
      }
    }
  }

  Future<void> _updatePaymentStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'paymentStatus': status});
  }

  Future<void> createPaymentLink(double amount) async {
    try {
      final priceInt = amount.toInt();
      final response = await http.post(
        Uri.parse('https://2c94-2402-800-7d0c-c656-20ff-bfab-7ea-3718.ngrok-free.app/Payment/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'productName': 'Đặt vé phim',
          'price': priceInt,
          'description': widget.bookingId,
          'cancelUrl': 'my_app://cancel',
          'returnUrl': 'my_app://success',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final paymentUrl = data['data']['checkoutUrl'];
          if (!await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          )) {
            throw Exception('Could not launch payment URL');
          }
        } else {
          throw Exception('API response error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Chi tiết vé', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final double totalPrice = data['totalPrice'] ?? 0.0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              data['movieName'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(color: Colors.grey),
                          _buildInfoRow('Rạp:', data['cinemaName'], Icons.movie),
                          _buildInfoRow('Phòng:', data['screenName'], Icons.meeting_room),
                          _buildInfoRow('Ngày chiếu:', data['showDate'], Icons.calendar_today),
                          _buildInfoRow('Giờ chiếu:', data['showtime'], Icons.access_time),
                          _buildInfoRow('Ghế:', data['seats'].join(', '), Icons.event_seat),
                          Divider(color: Colors.grey),
                          _buildInfoRow(
                            'Tổng tiền:',
                            '${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND',
                            Icons.attach_money,
                            valueColor: Colors.greenAccent,
                          ),
                          _buildInfoRow(
                            'Trạng thái:',
                            data['paymentStatus'],
                            Icons.payment,
                            valueColor: data['paymentStatus'] == 'Đã thanh toán' 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (data['paymentStatus'] == 'Chưa thanh toán')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () => createPaymentLink(totalPrice),
                      child: Text(
                        'Thanh toán ngay',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text('$label ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}