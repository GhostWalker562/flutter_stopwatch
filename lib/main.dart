import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stopwatch/utils/utils.dart';
import 'stopwatch/views/stopwatch_page.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch',
      scrollBehavior: const CustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF18331D),
          onPrimary: Color(0xFF61FF7A),
          secondary: Color(0xFF2D0F0D),
          onSecondary: Color(0xFFEB4D44),
          surface: Color(0xFF313131),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: Typography.whiteCupertino,
      ),
      home: const StopwatchPage(),
    );
  }
}
