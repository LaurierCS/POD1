import 'package:flutter/material.dart';
import 'RecordingPage.dart'; //Importing recording page
void main() {
  runApp(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
            body: Padding( // Add padding around the column
              padding: EdgeInsets.only(bottom: 80.0), // Adjust this value as needed to position the items above the bottom bar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Align the children of the column to the end vertically
                children: <Widget>[
                  Container(
                    width: double.infinity, // Make the rectangle take up all available horizontal space
                    height: 150, // Specify the height of the rectangle
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 194, 145, 128), // Background color of the rectangle
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Center(
                      child: Text('Emotion Stats'), // Placeholder text
                    ),
                    margin: EdgeInsets.only(bottom: 20), // Space between the two rectangles
                  ),
                  Container(
                    width: double.infinity, // Make the rectangle take up all available horizontal space
                    height: 150, // Specify the height of the rectangle
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 190, 157, 197), // Background color of the rectangle
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Center(
                      child: Text('Previous Recordings'), // Placeholder text
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Spaces the icons evenly in the row
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.auto_graph),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.home),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.date_range),
                    onPressed: () {},
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecordingPage(title: 'recording page')),
                );
            },
            child: Icon(Icons.add_circle_rounded),
            backgroundColor: const Color.fromARGB(255, 166, 101, 96),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the bar
        ),
      ),
    ),
  );
}
