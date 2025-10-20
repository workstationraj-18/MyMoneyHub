import 'package:expense_tracker/pages/add_entry_page.dart';
import 'package:expense_tracker/pages/entry_details_page.dart';
import 'package:expense_tracker/pages/ledger_page.dart';
import 'package:expense_tracker/pages/onboarding_page.dart';
import 'package:expense_tracker/pages/registration_confirmation_page.dart';
import 'package:expense_tracker/pages/view_entries_page.dart';
import 'package:expense_tracker/pages/view_parties_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme_controller.dart';
import 'pages/login_page.dart';
import 'pages/registration_page.dart';
import 'pages/home_page.dart';
import 'pages/add_party_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _determineStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (!keepLoggedIn) return const LoginPage();
    if (!seenOnboarding) return const OnboardingPage(userId: '');

    final userId = prefs.getString('userId') ?? 'User';
    return HomePage(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'MyMoneyHub',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurple),
      ),
      home: FutureBuilder<Widget>(
        future: _determineStartPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          return snapshot.data ?? const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/registrationConfirmation': (context) =>
        const RegistrationConfirmationPage(fullName: '', email: '', phone: ''),
        '/onboarding': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return OnboardingPage(userId: userId);
        },
        '/home': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return HomePage(userId: userId);
        },
        '/addNewEntry': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return AddEntryPage(userId: userId);
        },
        '/addNewParty': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return AddPartyPage(userId: userId);
        },
        '/modifyEntry': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AddEntryPage(
            userId: args['userId'],
            existingEntry: args['entry'], // 👈 this line enables prefill
          );
        },
        '/viewPartyList': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return ViewPartiesPage(userId: userId);
        },
        '/viewEntryList': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return ViewEntriesPage(userId: userId);
        },
        '/ledgerHistory': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return LedgerPage(userId: userId);
        },
        '/entryDetailsPage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EntryDetailsPage(
            userId: args['userId'],
            entry: args['entry'],
            entryId: args['entryId'],
          );
        },
      },
    );
  }
}
