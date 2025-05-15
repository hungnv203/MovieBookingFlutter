import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminScreenPage.dart';

class AdminCinemaPage extends StatefulWidget {
  @override
  _AdminCinemaPageState createState() => _AdminCinemaPageState();
}

class _AdminCinemaPageState extends State<AdminCinemaPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  // Thêm rạp phim vào Firestore
  Future<void> addCinema() async {
    await FirebaseFirestore.instance.collection('cinemas').add({
      'name': nameController.text,
      'location': locationController.text,
      'imageUrl': imageUrlController.text,
    });
    nameController.clear();
    locationController.clear();
    imageUrlController.clear();
    setState(() {
      
    });
  }

  // Cập nhật rạp phim
  Future<void> updateCinema(String id, String name, String location, String imageUrl) async {
    await FirebaseFirestore.instance.collection('cinemas').doc(id).update({
      'name': name,
      'location': location,
      'imageUrl': imageUrl,
    });
  }

  // Xóa rạp phim
  Future<void> deleteCinema(String id) async {
    await FirebaseFirestore.instance.collection('cinemas').doc(id).delete();
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Rạp Phim")),
      body: Column(
        children: [
          // Form nhập thông tin rạp phim
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên rạp")),
                TextField(controller: locationController, decoration: InputDecoration(labelText: "Địa điểm")),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addCinema,
                  child: Text("Thêm Rạp"),
                ),
              ],
            ),
          ),

          // Hiển thị danh sách rạp phim từ Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cinemas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var cinemas = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: cinemas.length,
                  itemBuilder: (context, index) {
                    var cinema = cinemas[index];
                    var id = cinema.id;
                    var name = cinema['name'] ?? 'null';
                    var location = cinema['location'] ?? 'null';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminScreenPage(cinemaId: id),
                          ),
                        );
                      },
                      child: ListTile(
                      title: Text(name),
                      subtitle: Text("Địa điểm: $location"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              nameController.text = name;
                              locationController.text = location;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Chỉnh sửa Rạp"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên rạp")),
                                      TextField(controller: locationController, decoration: InputDecoration(labelText: "Địa điểm")),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        updateCinema(id, nameController.text, locationController.text, imageUrlController.text);
                                        Navigator.pop(context);
                                      },
                                      child: Text("Lưu"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCinema(id),
                          ),
                        ],
                      ),
                    )
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