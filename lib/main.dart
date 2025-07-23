import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import 'package:rive_animation/services/user_service.dart';
import 'package:rive_animation/services/chat_session_service.dart';
import 'package:rive_animation/services/performance_service.dart';
import 'package:rive_animation/services/supabase_service.dart';
import 'package:rive_animation/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    // Supabase initialized successfully
  } catch (e) {
    // Supabase initialization failed: $e
    // Please check your Supabase credentials in lib/config/supabase_config.dart
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserService()),
        ChangeNotifierProvider(create: (context) => ChatSessionService()),
        ChangeNotifierProvider(create: (context) => PerformanceService()),
      ],
      child: MaterialApp(
        title: 'Emcie - Math Learning Assistant',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFEEF1F8),
          primarySwatch: Colors.blue,
          fontFamily: "Intel",
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            errorStyle: TextStyle(height: 0),
            border: defaultInputBorder,
            enabledBorder: defaultInputBorder,
            focusedBorder: defaultInputBorder,
            errorBorder: defaultInputBorder,
          ),
        ),
        home: const OnbodingScreen(),
      ),
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
