import 'package:bradpos/features/main/presentation/pages/main_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ErgoPOSApp());
}

class ErgoPOSApp extends StatelessWidget {
  const ErgoPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BradPOS',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A237E),
      ),
      home: const MainScreen(),
    );
  }
}