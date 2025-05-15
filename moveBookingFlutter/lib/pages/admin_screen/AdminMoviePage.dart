import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';

class AdminMoviepage extends StatefulWidget {
  @override
  State<AdminMoviepage> createState() => _AdminMoviePageState();
}

class _AdminMoviePageState extends State<AdminMoviepage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController releaseDate = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController genreController = TextEditingController();

  String searchQuery = "";

  // Thêm phim vào Firestore
  Future<void> addMovie() async {
    await FirebaseFirestore.instance.collection('movies').add({
      'name': nameController.text,
      'releaseDate': releaseDate.text,
      'duration': durationController.text,
      'imageUrl': imageUrlController.text,
      'genre': genreController.text,
      'fullDescription': descriptionController.text,
    });
    nameController.clear();
    durationController.clear();
    imageUrlController.clear();
    releaseDate.clear();
    genreController.clear();
    descriptionController.clear();
    Navigator.pop(context);
  }

  // Xóa phim
  Future<void> deleteMovie(String id) async {
    await FirebaseFirestore.instance.collection('movies').doc(id).delete();
  }

  // Mở dialog thêm phim
  void showAddMovieDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thêm Phim"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên phim")),
              TextField(controller: releaseDate, decoration: InputDecoration(labelText: "Ngày ra mắt")),
              TextField(controller: durationController, decoration: InputDecoration(labelText: "Thời lượng")),
              TextField(controller: genreController, decoration: InputDecoration(labelText: "Thể loại")),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: "Mô tả")),
              TextField(controller: imageUrlController, decoration: InputDecoration(labelText: "Link ảnh")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(onPressed: addMovie, child: Text("Lưu")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Phim")),
      body: Column(
        children: [
          // Thanh tìm kiếm và nút "Thêm Phim"
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm phim...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: showAddMovieDialog,
                  icon: Icon(Icons.add),
                  label: Text("Thêm"),
                ),
              ],
            ),
          ),

          // Danh sách phim từ Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('movies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var movies = snapshot.data!.docs.where((doc) {
                  var name = doc['name'].toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    var movie = movies[index];
                    var id = movie.id;
                    var name = movie['name'];
                    var duration = movie['duration'];
                    var genre = movie['genre'];

                    return ListTile(
                      title: Text(name),
                      subtitle: Text("Thời lượng: $duration - Thể loại: $genre"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteMovie(id)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailFilmPage(movieId: id)));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
