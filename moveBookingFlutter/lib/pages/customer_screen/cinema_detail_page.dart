import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';

class CinemaDetailPage extends StatefulWidget {
  final String cinemaId;

  const CinemaDetailPage({
    Key? key,
    required this.cinemaId,
  }) : super(key: key);

  @override
  State<CinemaDetailPage> createState() => _CinemaDetailPageState();
}

class _CinemaDetailPageState extends State<CinemaDetailPage> {
  bool isLoading = true;
  List<String> availableDates = [];
  String selectedDate = "";
  List<String> showtimeHours = [];
  String selectedHour = "";
  List<Map<String, dynamic>> moviesList = [];
  String cinemaName = "Đang tải...";

  @override
  void initState() {
    super.initState();
    fetchData(); // 🔹 Gọi hàm tải dữ liệu song song
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // 🔹 Tải dữ liệu song song
      final cinemaFuture = FirebaseFirestore.instance
          .collection('cinemas')
          .doc(widget.cinemaId)
          .get();
      final showtimesFuture = FirebaseFirestore.instance
          .collection('showtimes')
          .where('cinemaId', isEqualTo: widget.cinemaId)
          .get();

      final results = await Future.wait([cinemaFuture, showtimesFuture]); // tải dữ liệu song song bằng Future.wait

      // kiểm tra xem dữ liệu có tồn tại không
      final cinemaDoc = results[0] as DocumentSnapshot;
      if (cinemaDoc.exists) {
        cinemaName = cinemaDoc["name"];
      }

      // 🔹 Xử lý dữ liệu showtimes
      final showtimesSnapshot = results[1] as QuerySnapshot;
      Set<String> dates = {};
      List<Map<String, dynamic>> tempMovies = [];

      for (var showtime in showtimesSnapshot.docs) {
        var data = showtime.data();
        var date = (data as Map<String, dynamic>)['date'] ?? '';
        var hour = (data as Map<String, dynamic>)['time'] ?? '';
        var movieId = (data as Map<String, dynamic>)['movieId'] ?? '';

        if (date.isEmpty || hour.isEmpty || movieId.isEmpty) {
          print("Dữ liệu thiếu: ${showtime.id}");
          continue;
        }

        dates.add(date);

        // 🔹 Chỉ lấy các trường cần thiết từ Firestore
        var movieDoc = await FirebaseFirestore.instance
            .collection('movies')
            .doc(movieId)
            .get();

        if (movieDoc.exists) {
          var movieData = movieDoc.data() ?? {};
          tempMovies.add({
            'showtimeId': showtime.id,
            'time': hour,
            'date': date,
            'movieId': movieId,
            'movieName': movieData['name'] ?? 'Không rõ',
            'posterUrl': movieData['imageUrl'] ?? '',
          });
        }
      }

      setState(() {
        availableDates = dates.toList()..sort();
        selectedDate = availableDates.isNotEmpty ? availableDates.first : "";
        moviesList = tempMovies;
        updateShowtimes();
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải dữ liệu: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateShowtimes() {
    setState(() {
      showtimeHours = moviesList
          .where((movie) => movie['date'] == selectedDate)
          .map((movie) => movie['time'] as String)
          .toSet()
          .toList()
        ..sort();
      selectedHour = showtimeHours.isNotEmpty ? showtimeHours.first : "";
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredMovies = moviesList
        .where((movie) =>
            movie['date'] == selectedDate && movie['time'] == selectedHour)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black, // 🌙 Màu nền đen toàn bộ trang
      appBar: AppBar(
        title: Text(cinemaName, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Danh sách ngày chiếu
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
                            updateShowtimes();
                          });
                        },
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedDate == date
                                ? Colors.blueAccent
                                : Colors.grey[850], // 🌙 Giữ màu tối
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              date,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 10),

                // 🔹 Danh sách khung giờ
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: showtimeHours.length,
                    itemBuilder: (context, index) {
                      String hour = showtimeHours[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedHour = hour;
                          });
                        },
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedHour == hour
                                ? Colors.redAccent
                                : Colors.grey[850], // 🌙 Màu tối cho nút không chọn
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              hour,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 10),

                // 🔹 Danh sách phim theo ngày & giờ
                Expanded(
                  child: filteredMovies.isEmpty
                      ? Center(
                          child: Text(
                            "Không có phim nào",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredMovies.length,
                          itemBuilder: (context, index) {
                            var movie = filteredMovies[index];
                            return Card(
                              color: Colors.grey[900], // 🌙 Màu nền tối cho card
                              margin: EdgeInsets.all(10),
                              child: ListTile(
                                leading: Image.network(
                                  movie['posterUrl'],
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white));
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey);
                                  },
                                ),
                                title: Text(
                                  movie['movieName'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  "Giờ: ${movie['time']} - Ngày: ${movie['date']}",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: Icon(Icons.arrow_forward,
                                    color: Colors.white),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailFilmPage(
                                          movieId: movie['movieId']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
