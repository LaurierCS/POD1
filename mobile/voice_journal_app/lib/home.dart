import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Container(), //
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Spaces the icons evenly in the row
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.auto_graph),
                onPressed: () {
                  // Handles the button press
                },
              ),
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  // Handles the button press
                },
              ),
              IconButton(
                icon: Icon(Icons.date_range),
                onPressed: () {
                  // Handles the button press
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Handles the button press
          },
          child: Icon(Icons.add_circle_rounded),
          backgroundColor: const Color.fromARGB(255, 166, 101, 96),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the bar
      ),
    ),
  );
}
