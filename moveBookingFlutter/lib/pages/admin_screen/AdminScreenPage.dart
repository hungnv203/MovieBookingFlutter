import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminShowtimePage.dart';

class AdminScreenPage extends StatefulWidget {
  final String cinemaId; // Nhận ID của rạp phim
  const AdminScreenPage({Key? key, required this.cinemaId}) : super(key: key);

  @override
  _AdminScreenPageState createState() => _AdminScreenPageState();
}

class _AdminScreenPageState extends State<AdminScreenPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();

  // Thêm phòng chiếu mới vào rạp phim
  Future<void> addScreen() async {
    await FirebaseFirestore.instance
        .collection('screens')
        .add({
      'cinemaId':widget.cinemaId,
      'name': nameController.text,
      'seats': int.tryParse(seatsController.text) ?? 50,
      'isAvailable': true, // Mặc định phòng khả dụng
    });

    nameController.clear();
    seatsController.clear();
    setState(() {
      
    });
  }

  // Cập nhật thông tin phòng chiếu
  Future<void> updateScreen(String screenId, String name, int seats, bool isAvailable) async {
    await FirebaseFirestore.instance
        .collection('screens')
        .doc(screenId)
        .update({
      'cinemaId':widget.cinemaId,
      'name': name,
      'seats': seats,
      'isAvailable': isAvailable,
    });
  }

  // Xóa phòng chiếu
  Future<void> deleteScreen(String screenId) async {
    await FirebaseFirestore.instance
        .collection('screens')
        .doc(screenId)
        .delete();
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Phòng Chiếu")),
      body: Column(
        children: [
          // Form nhập thông tin phòng chiếu
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên phòng")),
                TextField(controller: seatsController, decoration: InputDecoration(labelText: "Số ghế"), keyboardType: TextInputType.number),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addScreen,
                  child: Text("Thêm Phòng Chiếu"),
                ),
              ],
            ),
          ),

          // Hiển thị danh sách phòng chiếu theo rạp phim
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('screens').where('cinemaId', isEqualTo: widget.cinemaId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var screens = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: screens.length,
                  itemBuilder: (context, index) {
                    var screen = screens[index];
                    var id = screen.id;
                    var name = screen['name'];
                    var seats = screen['seats'];
                    var isAvailable = screen['isAvailable'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminShowtimePage(cinemaId: widget.cinemaId, screenId: id),
                          ),
                        );
                      },
                      child: ListTile(
                      title: Text(name),
                      subtitle: Text("Số ghế: $seats"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              nameController.text = name;
                              seatsController.text = seats.toString();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Chỉnh sửa Phòng Chiếu"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên phòng")),
                                      TextField(controller: seatsController, decoration: InputDecoration(labelText: "Số ghế"), keyboardType: TextInputType.number),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        updateScreen(id, nameController.text, int.parse(seatsController.text), isAvailable);
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
                            onPressed: () => deleteScreen(id),
                          ),
                        ],
                      ),
                    ),
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
