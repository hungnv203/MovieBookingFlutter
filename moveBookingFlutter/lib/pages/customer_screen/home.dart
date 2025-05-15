import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/customer_screen/cinema_detail_page.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userName = "";
  int selectedIndex = 0; // 0: Đang Chiếu, 1: Sắp Chiếu

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: Colors.orangeAccent),
            SizedBox(width: 5),
            Text("Hello  ",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(userName,
                style: TextStyle(color: Colors.orangeAccent, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text("Welcome To,", style: TextStyle(color: Colors.white70)),
            Text(
              "H Cinemas",
              style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Danh sách phim",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ToggleButtons(
                isSelected: [selectedIndex == 0, selectedIndex == 1],
                borderRadius: BorderRadius.circular(10),
                color: Colors.white70,
                selectedColor: Colors.white,
                fillColor: Colors.grey[800],
                onPressed: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Đang Chiếu", style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Sắp Chiếu", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: StreamBuilder(
                stream: _firestore.collection('movies').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("Không có phim nào",
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  var movies = snapshot.data!.docs;
                  DateTime now = DateTime.now();

                  var filteredMovies = movies.where((movie) {
                    var releaseDateString = movie['releaseDate'].trim();
                    DateTime releaseDate =
                        DateFormat("dd/MM/yyyy").parse(releaseDateString);
                    if (selectedIndex == 0) {
                      return releaseDate.isBefore(now) ||
                          releaseDate.isAtSameMomentAs(now);
                    } else {
                      return releaseDate.isAfter(now);
                    }
                  }).toList();

                  if (filteredMovies.isEmpty) {
                    return Center(
                      child: Text(
                        "Không có phim phù hợp",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return FlutterCarousel.builder(
                    itemCount: filteredMovies.length,
                    options: FlutterCarouselOptions(
                      autoPlay: false,
                      enlargeCenterPage: true,
                      viewportFraction: 0.5,
                      showIndicator: false,
                      initialPage: (filteredMovies.length) ~/ 2,
                      enableInfiniteScroll: true,
                    ),
                    itemBuilder: (context, index, realIdx) {
                      var movie = filteredMovies[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailFilmPage(movieId: movie.id),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 150,
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 95, 90, 90)),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: movie['imageUrl'].startsWith('http')
                                        ? Image.network(
                                            movie['imageUrl'],
                                            width: 150,
                                            height: 220,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            movie['imageUrl'],
                                            width: 150,
                                            height: 220,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              child: Text(
                                movie['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Danh sách rạp",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder(
                stream: _firestore.collection("cinemas").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text("Không có rạp nào",
                            style: TextStyle(color: Colors.white)));
                  }
                  var cinemas = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: cinemas.length,
                    itemBuilder: (context, index) {
                      var cinema = cinemas[index];
                      return Card(
                        color: Colors.grey[800],
                        margin: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: Text(
                            cinema['name'],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            cinema['location'],
                            style: TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CinemaDetailPage(cinemaId: cinema.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                })
          ],
        ),
      ),
    );
  }
}
