import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourstory/start.dart';
import 'theme_notifier.dart'; // Ensure this path is correct for your project
import 'splash_screen.dart';
import 'login.dart'; // Import Login screen

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  BoxShadow(
    color: Colors.black.withOpacity(0.35),
    offset: Offset(0, 4),
    blurRadius: 6,
  );

  // Run app
  runApp(const MyApp());
}

// main.dart (inside or below your MyApp class, or in any other common file)
class AppShadows {
  static List<BoxShadow> universalShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        offset: const Offset(0, 4),
        blurRadius: 6,
      ),
    ];
  }
}

class AppShadowsLight {
  static List<BoxShadow> universalShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        offset: const Offset(0, 3),
        blurRadius: 3,
      ),
    ];
  }
}

class AppWidgets {
  /// A reusable “Top Placeholder Header” widget.
  /// [height] sets how tall the header should be;
  /// [assetPath] is an optional image to center (e.g., your logo);
  /// [color] is the background color of the header.
  static Widget buildTopPlaceholder({
    double height = 200,
    String? assetPath,
    Color color = const Color(0xFFFF3355),
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        // Apply your universal shadows here:
        boxShadow: AppShadows.universalShadow(),
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(
          assetPath,
          width: 150,
          height: 150,
        )
            : Container(),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override


  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'LuckiestGuy', // Set the default font for the entire app
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                bodyMedium: TextStyle(
                  fontSize: 18,
                ),
                bodySmall: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            initialRoute: '/splash', // Set initial route to splash
            routes: {
              '/splash': (context) => SplashScreen(),
              '/start': (context) => StartPage(), // Update to LoginPage (since your widget is LoginPage, not Login)
              // Add other routes as needed
            },
          );
        },
      ),
    );
  }
}


