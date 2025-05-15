import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSeatPage extends StatefulWidget {
  final String cinemaId;
  final String screenId;
  final String showtimeId;

  const AdminSeatPage({Key? key, required this.cinemaId, required this.screenId, required this.showtimeId}) : super(key: key);

  @override
  _AdminSeatPageState createState() => _AdminSeatPageState();
}

class _AdminSeatPageState extends State<AdminSeatPage> {
  // Cập nhật trạng thái ghế (đặt hoặc hủy)
  Future<void> toggleSeat(String seatId, bool isBooked) async {
    await FirebaseFirestore.instance   
        .collection('seats')
        .doc(seatId)
        .update({'isBooked': !isBooked});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Ghế Ngồi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('seats').where("showtimeId",isEqualTo: widget.showtimeId).where("screenId",isEqualTo: widget.screenId).where("cinemaId",isEqualTo: widget.cinemaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var seats = snapshot.data!.docs;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: seats.length,
            itemBuilder: (context, index) {
              var seat = seats[index];
              bool isBooked = seat['isBooked'];

              return GestureDetector(
                onTap: () => toggleSeat(seat.id, isBooked),
                child: Container(
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isBooked ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(child: Text(seat['seatNumber'], style: TextStyle(color: Colors.white))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
