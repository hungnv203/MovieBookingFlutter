import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/payment_page.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String cinemaId;
  final String screenId;
  final String showtimeId;
  final String movieId;
  const SeatSelectionScreen(
      {super.key,
      required this.cinemaId,
      required this.screenId,
      required this.showtimeId,
      required this.movieId});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<Map<String, dynamic>> seats = [];
  Set<String> selectedSeats = {}; // Ghế được chọn
  double totalPrice = 0.0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    var seatDocs = await FirebaseFirestore.instance
        .collection("seats")
        .where('showtimeId', isEqualTo: widget.showtimeId)
        .get();

    List<Map<String, dynamic>> loadedSeats = seatDocs.docs.map((doc) {
      return {
        "seatId": doc.id,
        "seatNumber": doc["seatNumber"], // Ex: "A1", "B2"
        "isBooked": doc["isBooked"],
      };
    }).toList();

    // 🔹 **Sắp xếp ghế theo hàng và số**
    loadedSeats.sort((a, b) {
      String seatA = a["seatNumber"];
      String seatB = b["seatNumber"];

      String rowA = seatA.substring(0, 1); // Lấy chữ cái đầu (A, B, C...)
      String rowB = seatB.substring(0, 1);

      int numA = int.parse(seatA.substring(1)); // Lấy số ghế (1, 2, 3...)
      int numB = int.parse(seatB.substring(1));

      if (rowA == rowB) {
        return numA.compareTo(numB); // Nếu cùng hàng, sắp xếp theo số
      }
      return rowA.compareTo(rowB); // Sắp xếp theo chữ cái
    });

    setState(() {
      seats = loadedSeats;
    });
  }

  void _toggleSeatSelection(String seatId) async {
    var seatdocs =
        await FirebaseFirestore.instance.collection('seats').doc(seatId).get();
    double seatPrice = seatdocs["price"];
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
        totalPrice -= seatPrice;
      } else {
        totalPrice += seatPrice;
        selectedSeats.add(seatId);
      }
    });
  }

  void _confirmBooking() async {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất một ghế!")),
      );
      return;
    }
    setState(() {
      isProcessing = true;
    });

    try {
      var firestore = FirebaseFirestore.instance;

      // 🔹 Lấy thông tin chi tiết về rạp, phòng, suất chiếu, phim trong một lần
      var cinemaFuture =
          firestore.collection("cinemas").doc(widget.cinemaId).get();
      var screenFuture =
          firestore.collection("screens").doc(widget.screenId).get();
      var showtimeFuture =
          firestore.collection("showtimes").doc(widget.showtimeId).get();
      var movieFuture =
          firestore.collection("movies").doc(widget.movieId).get();

      var results = await Future.wait([
        cinemaFuture,
        screenFuture,
        showtimeFuture,
        movieFuture,
      ]);

      var cinemaDoc = results[0];
      var screenDoc = results[1];
      var showtimeDoc = results[2];
      var movieDoc = results[3];

      String movieName = movieDoc["name"];
      String cinemaName = cinemaDoc["name"];
      String screenName = screenDoc["name"];
      String showtime = showtimeDoc["time"];
      String showDate = showtimeDoc["date"];

      // 🔹 Lấy thông tin số ghế trong một lần truy vấn
      var seatDocs = await firestore
          .collection("seats")
          .where(FieldPath.documentId, whereIn: selectedSeats.toList())
          .get();

      List<String> selectedSeatNumbers =
          seatDocs.docs.map((doc) => doc["seatNumber"] as String).toList();

      // 🔹 Sử dụng batch để cập nhật trạng thái ghế
      WriteBatch batch = firestore.batch();
      for (var seatDoc in seatDocs.docs) {
        batch.update(seatDoc.reference, {"isBooked": true});
      }

      // 🔹 Lưu thông tin đặt vé vào Firestore
      final bookingRef = firestore.collection("bookings").doc();
      batch.set(bookingRef, {
        "movieName": movieName,
        "cinemaName": cinemaName,
        "screenName": screenName,
        "showtime": showtime,
        "showDate": showDate,
        "seats": selectedSeatNumbers,
        "totalPrice": totalPrice,
        "paymentStatus": "Chưa thanh toán",
        "userId": FirebaseAuth.instance.currentUser!.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 🔹 Thực hiện batch write
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đặt vé thành công!")),
      );

      // 🔹 Chuyển hướng sau khi đặt vé
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TicketDetailScreen(bookingId: bookingRef.id)));
      await _loadSeats(); // Tải lại ghế sau khi đặt vé
      setState(() {
        selectedSeats.clear();
        totalPrice = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xảy ra lỗi: $e")),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      appBar: AppBar(
        title: Text(
          "Chọn ghế",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: seats.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      "MÀN HÌNH",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 150, left: 5, right: 5),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10, // Số ghế mỗi hàng
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: seats.length,
                    itemBuilder: (context, index) {
                      var seat = seats[index];
                      bool isBooked = seat["isBooked"];
                      bool isSelected = selectedSeats.contains(seat["seatId"]);

                      return GestureDetector(
                        onTap: isBooked
                            ? null
                            : () => _toggleSeatSelection(seat["seatId"]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked
                                ? const Color.fromARGB(255, 175, 8, 8)
                                : (isSelected
                                    ? Colors.green
                                    : const Color.fromARGB(255, 56, 60, 62)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            seat["seatNumber"],
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                    child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tổng tiền:",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                          Text(
                              "${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND",
                              style: TextStyle(
                                  color: Colors.orangeAccent, fontSize: 18)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (selectedSeats.isEmpty || isProcessing)
                          ? null
                          : _confirmBooking,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey; // Màu xám khi chưa chọn ghế
                            }
                            return Colors
                                .green; // Màu xanh lá khi có ghế được chọn
                          },
                        ),
                      ),
                      child: isProcessing
                          ? CircularProgressIndicator()
                          : Text(
                              "Xác nhận đặt vé",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                )),
              ],
            ),
    );
  }
}
