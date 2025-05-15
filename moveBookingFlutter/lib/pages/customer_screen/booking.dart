import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/customer_screen/selected_seat.dart';

class BookingScreen extends StatefulWidget {
  final String movieId;

  const BookingScreen({super.key, required this.movieId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedDate;
  String? selectedCinema;
  String? selectedShowtime;
  List<String> availableDates = [];
  Map<String, List<Map<String, dynamic>>> cinemaShowtimes = {};
  String movieName = "Đang tải...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
    fetchMovieName();
  }

  Future<void> fetchMovieName() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movieId)
          .get();
      if (doc.exists) {
        setState(() {
          movieName = doc["name"];
        });
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu: $e");
    }
  }

  Future<void> _loadShowtimes() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Truy vấn toàn bộ showtimes của movie
      final showtimeSnapshot = await FirebaseFirestore.instance
          .collection("showtimes")
          .where("movieId", isEqualTo: widget.movieId)
          .get();

      final showtimeDocs = showtimeSnapshot.docs;

      if (showtimeDocs.isEmpty) {
        setState(() {
          availableDates = [];
          cinemaShowtimes = {};
        });
        return;
      }

      // 2. Gom các screenId
      final screenIds =
          showtimeDocs.map((doc) => doc["screenId"] as String).toSet();

      // 3. Truy vấn toàn bộ screens
      final screenSnapshot = await FirebaseFirestore.instance
          .collection("screens")
          .where(FieldPath.documentId, whereIn: screenIds.toList())
          .get();

      final screenDataMap = {
        for (var doc in screenSnapshot.docs) doc.id: doc.data()
      };

      // 4. Gom các cinemaId
      final cinemaIds =
          screenDataMap.values.map((e) => e["cinemaId"] as String).toSet();

      // 5. Truy vấn toàn bộ cinemas
      final cinemaSnapshot = await FirebaseFirestore.instance
          .collection("cinemas")
          .where(FieldPath.documentId, whereIn: cinemaIds.toList())
          .get();

      final cinemaDataMap = {
        for (var doc in cinemaSnapshot.docs) doc.id: doc.data()
      };

      // 6. Xử lý dữ liệu
      Set<String> dates = {};
      Map<String, List<Map<String, dynamic>>> showtimeMap = {};

      for (var showtime in showtimeDocs) {
        final data = showtime.data();
        final dateStr = data["date"];
        final timeStr = data["time"];
        final screenId = data["screenId"];
        final screenData = screenDataMap[screenId];
        final cinemaId = screenData?["cinemaId"];
        final cinemaData = cinemaDataMap[cinemaId];

        if (cinemaData == null) continue;

        try {
          final parsedDate = DateFormat("d/M/yyyy").parse(dateStr);
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);

          if (parsedDate.isBefore(todayDateOnly)) continue;
        } catch (e) {
          print("Lỗi khi parse ngày: $e");
          continue;
        }

        dates.add(dateStr);
        showtimeMap.putIfAbsent(dateStr, () => []);
        showtimeMap[dateStr]!.add({
          "cinemaId": cinemaId,
          "cinemaName": cinemaData["name"],
          "location": cinemaData["location"],
          "showtimeId": showtime.id,
          "time": timeStr,
          "screenId": screenId,
        });
      }

      setState(() {
        availableDates = dates.toList()..sort();
        cinemaShowtimes = showtimeMap;
      });
    } catch (e) {
      print("Lỗi khi load showtimes: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(movieName, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : availableDates.isEmpty
              ? Center(
                  child: Text(
                    "Không có suất chiếu nào",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Danh sách ngày chiếu
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableDates.length,
                        itemBuilder: (context, index) {
                          String date = availableDates[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDate = date;
                                selectedCinema = null;
                                selectedShowtime = null;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedDate == date
                                    ? Colors.blueAccent
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                date,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Danh sách rạp chiếu theo ngày

                    if (selectedDate != null)
                      Expanded(
                        child: ListView(
                          children: cinemaShowtimes[selectedDate]!
                              .map((cinema) => Card(
                                    color: Colors.grey[850],
                                    margin: EdgeInsets.all(8),
                                    child: ExpansionTile(
                                      title: Text(
                                        cinema["cinemaName"],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        cinema["location"],
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      iconColor: Colors.white,
                                      collapsedIconColor: Colors.white,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: cinemaShowtimes[
                                                  selectedDate]!
                                              .where((item) =>
                                                  item["cinemaId"] ==
                                                  cinema["cinemaId"])
                                              .map((showtime) => ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blueAccent,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 10),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SeatSelectionScreen(
                                                            cinemaId: showtime[
                                                                "cinemaId"],
                                                            screenId: showtime[
                                                                "screenId"],
                                                            showtimeId: showtime[
                                                                "showtimeId"],
                                                            movieId:
                                                                widget.movieId,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                        showtime["time"],
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ))
                                              .toList(),
                                        ),
                                        SizedBox(
                                            height: 10), // Tạo khoảng cách dưới
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
    );
  }
}
