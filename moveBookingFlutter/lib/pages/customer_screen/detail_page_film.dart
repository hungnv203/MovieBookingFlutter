import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/customer_screen/booking.dart';
import 'package:my_app/pages/customer_screen/bottomnav.dart';

class DetailFilmPage extends StatefulWidget {
  final String movieId;
  const DetailFilmPage({super.key, required this.movieId});

  @override
  State<DetailFilmPage> createState() => _DetailFilmPage();
}

class _DetailFilmPage extends State<DetailFilmPage> {
  int selectedTimeIndex = 0;
  int selectedDateIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? movieData;
  List<String> selectedSeats = [];
  List<String> bookedSeats = [];

  @override
  void initState() {
    super.initState();
    fetchMoiveDatas();
  }

  Future<void> fetchMoiveDatas() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movieId)
          .get();
      if (doc.exists) {
        setState(() {
          movieData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      print("lỗi khi lấy dữ liệu : $e");
    }
  }

  List<String> getFormatDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EE d');
    return List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return formatter.format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              child: Stack(
                children: [
                  Image.network(
                    movieData?['imageUrl'] ?? '', // Ảnh từ Firestore
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Ảnh đã tải xong
                      }
                      return Center(
                        child:
                            CircularProgressIndicator(), // Hiển thị loading khi ảnh chưa tải xong
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => Bottomnav()));
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      margin: EdgeInsets.only(top: 30, left: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Positioned(
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.only(top: 10, left: 20, right: 20),
                      margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height / 2 - 20),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 21, 21, 21),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30))),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movieData?['name'] ?? 'Unknown Movie',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Text(
                                  movieData?['genre'] ?? 'No Genre',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.timer_sharp,
                                  color: Colors.grey,
                                ),
                                
                                Text(
                                  movieData?['duration'] ?? "",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text("Description",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              movieData?['fullDescription'] ??
                                  'No description available',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: MaterialButton(
                                color: Colors.green,
                                child: Text('Đặt vé',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => BookingScreen(
                                              movieId: widget.movieId)));
                                }),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
