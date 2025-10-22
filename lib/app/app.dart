import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

class CineTvApp extends StatelessWidget {
  CineTvApp({super.key}) : _router = createRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CineTv',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
