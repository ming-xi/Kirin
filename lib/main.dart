import 'package:flutter/material.dart';
import 'package:kirin/home.dart';
import 'package:kirin/preferences.dart';

void main() async {
  runApp(const MyApp());
  await preferences.init();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kirin Sketch Palette Extractor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
