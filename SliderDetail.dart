import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SliderDetail extends StatelessWidget {
  final String itemId;

  SliderDetail(this.itemId);

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Slider Details',
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('images').doc(itemId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Image not found.'));
          }

          final itemData = snapshot.data!.data() as Map<String, dynamic>;

          final itemName = itemData['name'] as String? ?? 'Name not available';
          final itemDescription =
              itemData['description'] as String? ?? 'Description not available';
          final itemImage = itemData['image'] as String? ?? '';

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          39), // Adjust the radius as needed
                      child: Image.network(
                        itemImage,
                        width: 270,
                        height: 270,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                    child: Text(
                      itemDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700], // Adjust the color as needed
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
