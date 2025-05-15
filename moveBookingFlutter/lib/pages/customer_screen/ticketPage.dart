import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/payment_page.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});
  @override
  State<TicketPage> createState() => _TicketPage();
}

class _TicketPage extends State<TicketPage> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Danh sách vé",style: TextStyle(color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 27, 27, 27)
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Bạn chưa đặt vé nào",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          var bookings = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketDetailScreen(
                        bookingId: booking.id,
                      ),
                    ),
                  );
                },
                child: Card(
                color: Colors.blueGrey[900], // Màu card nổi bật hơn
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking["movieName"],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event_seat, color: Colors.white54),
                          SizedBox(width: 5),
                          Text("Ghế: ${booking["seats"]}",
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.white54),
                          SizedBox(width: 5),
                          Text("Số tiền: ${booking["totalPrice"].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND",
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white54),
                          SizedBox(width: 5),
                          Text(
                            "Thời gian: ${booking["showtime"]} ${booking["showDate"]}",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${booking["paymentStatus"]}",
                            style: TextStyle(
                              color: booking["paymentStatus"] ==
                                      "Chưa thanh toán"
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          booking['paymentStatus'] == "Chưa thanh toán"
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TicketDetailScreen(
                                          bookingId: booking.id,
                                    
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text("Thanh toán"),
                                )
                              : Icon(Icons.check_circle,
                                  color: Colors.green, size: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}
