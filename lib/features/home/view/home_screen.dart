import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: kTextStyle.copyWith()),
        // backgroundColor: const Color(0xFFF7F7FA),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),

      // backgroundColor: const Color(0xFFF7F7FA),
      body: Center(
        child: Text(
          'Home',
          style: kTextStyle.copyWith(),
        ),
      ),
    );
  }
}
