import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/courses_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/persistence_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/study_groups_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await PersistenceService().init();
  await NotificationService().init();
  
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();
  
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, CoursesProvider>(
          create: (_) => CoursesProvider(),
          update: (_, auth, courses) => courses!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StudyGroupsProvider>(
          create: (_) => StudyGroupsProvider(),
          update: (_, auth, groups) => groups!..updateToken(auth.token),
        ),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return MaterialApp(
      title: 'Study Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // No dark mode
      themeMode: ThemeMode.light,
      initialRoute: '/',
      locale: Locale(settings.language ?? 'en'),
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScaleFactor),
          ),
          child: child!,
        );
      },
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/auth': (ctx) => const AuthWrapper(),
        '/home': (ctx) => const MainScreen(),
      },
    );
  }
}

// Wrapper to handle auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.isAuthenticated) {
      // Already authenticated, go to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return const LoginScreen();
  }
}
