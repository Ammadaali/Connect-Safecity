import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/admin/SliderDetail.dart';
import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({Key? key}) : super(key: key);

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final CollectionReference imagesRef =
      FirebaseFirestore.instance.collection('images');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: imagesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No images available.'));
        }

        List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

        return CarouselSlider(
          items: documents.map((document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;

            String imageUrl = data['image'] ?? '';
            String title = data['name'] ?? 'Title not available';

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SliderDetail(document.id),
                ));
              },
              child: Container(
                padding: EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          width: 290,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          title,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 255,
            enableInfiniteScroll: true,
            autoPlay: true,
            enlargeCenterPage: true,
          ),
        );
      },
    );
  }
}
