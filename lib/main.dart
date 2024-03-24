import 'package:flutter/material.dart';
import 'package:quizlet_final_flutter/authentication/signup.dart';
import 'authentication/login.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.white,
        hintColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white), // Set back button color to white
        ),
        // Add more theme configurations as needed
      ),
      themeMode: ThemeMode.light,
      title: 'QuizPop',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const MainApp(),
        '/login': (context) => const Login(),
        '/signUp': (context) => const SignUp(),
        '/home': (context) => const MainApp(),
      },
    );
  }
}
