import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tradex/screens/home_screen.dart';
import 'package:tradex/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090B10),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TradexApp());
}

class TradexApp extends StatelessWidget {
  const TradexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRADEX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
