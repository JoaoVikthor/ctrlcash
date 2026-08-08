import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/budget_form_screen.dart';
import 'home_screen.dart';
import 'budgets_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CashCtrlApp());
}

class CashCtrlApp extends StatelessWidget {
  const CashCtrlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        StreamProvider<User?>(
          create: (context) =>
              context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider(),
        ),
        ChangeNotifierProvider<BudgetProvider>(
          create: (_) => BudgetProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'CashCtrl',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF0D1E16),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF165A41),
            secondary: Color(0xFFB89775),
          ),
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/cadastro': (context) => const CadastroScreen(),
          '/dashboard': (context) => const HomeScreen(),
          '/budgets': (context) => const BudgetsScreen(),
          '/budget-form': (context) => const BudgetFormScreen(),
          '/expenses': (context) => const ExpensesScreen(),
          '/transaction-form': (context) => const TransactionFormScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _sub;
  User? _user;
  bool _waiting = true;
  bool _linked = false;

  @override
  void initState() {
    super.initState();
    final AuthService authService = context.read<AuthService>();
    final UserProvider userProvider = context.read<UserProvider>();
    final TransactionProvider txProvider = context.read<TransactionProvider>();
    final BudgetProvider budgetProvider = context.read<BudgetProvider>();
    if (!_linked) {
      txProvider.attach(userProvider);
      budgetProvider.attach(userProvider);
      _linked = true;
    }
    _sub = authService.authStateChanges.listen((User? user) {
      if (user == null) {
        userProvider.limpar();
      } else {
        userProvider.setUsuario(user.uid);
      }
      if (mounted) setState(() => _user = user);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _waiting) setState(() => _waiting = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1E16),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB89775)),
        ),
      );
    }

    if (_user == null) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}