import 'package:flutter/material.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding for white space
        child: Container(
          padding: const EdgeInsets.only(bottom: 60.0, top: 90.0), // Adjusted to accommodate FAB and title
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Aligns children to the bottom
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches children horizontally to match the column width
            children: <Widget>[
              Text(
                'Emoz',
                textAlign: TextAlign.center, //
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black, 
                ),
              ),
              SizedBox(height: 20), // Adds space between the title and the first container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor, // Background color
                  borderRadius: BorderRadius.circular(10), // Rounds corners
                ),
                child: Center(child: Text('Emotion Stats')), // Placeholder text
                margin: EdgeInsets.only(bottom: 20, top: 20), // Space between the rectangles and additional top padding
              ),
              Expanded( // 
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor, // Background color of the rectangle
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: ListView.builder( 
                    itemCount: 10, // Number of items in the list, for demonstration
                    itemBuilder: (context, index) => ListTile(
                      title: Text('Item $index'), // Example list item
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Spaces icons evenly
          children: <Widget>[
            IconButton(icon: Icon(Icons.auto_graph), onPressed: () {}),
            IconButton(icon: Icon(Icons.home), onPressed: () {}),
            IconButton(icon: Icon(Icons.date_range), onPressed: () {}),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add_circle_rounded),
        backgroundColor: AppColors.accentColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, 
    );
  }
}
