import 'package:flutter/material.dart';

void main() {
runApp(
    const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment:
      Alignment.bottomCenter,
          child: Icon(
            Icons.add_circle_rounded,
            color: Colors.red,
            size: 100.0,
          )
        )
      )
    )
  );
}