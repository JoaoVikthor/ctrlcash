import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/budget.dart';
import 'models/transaction.dart';
import 'models/ingredient.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/ingredient_provider.dart';
import 'providers/product_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/budget_form_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/ingredient_form_screen.dart';
import 'screens/products_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_scanner_screen.dart';
import 'screens/settings/edit_profile_screen.dart';
import 'screens/settings/notifications_screen.dart';
import 'screens/settings/security_screen.dart';
import 'screens/settings/help_screen.dart';
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

class CashCtrlApp extends StatefulWidget {
  const CashCtrlApp({super.key});

  @override
  State<CashCtrlApp> createState() => _CashCtrlAppState();
}

class _CashCtrlAppState extends State<CashCtrlApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AuthService _authService;
  late final UserProvider _userProvider;
  late final TransactionProvider _transactionProvider;
  late final BudgetProvider _budgetProvider;
  late final IngredientProvider _ingredientProvider;
  late final ProductProvider _productProvider;

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _userProvider = UserProvider();

    _transactionProvider = TransactionProvider();
    _budgetProvider = BudgetProvider();
    _ingredientProvider = IngredientProvider();
    _productProvider = ProductProvider();

    _transactionProvider.attach(_userProvider);
    _budgetProvider.attach(_userProvider);
    _ingredientProvider.attach(_userProvider);
    _productProvider.attach(_userProvider);

    _authSub = _authService.authStateChanges.listen((User? user) {
      if (user == null) {
        _userProvider.limpar();
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else {
        _userProvider.setUsuario(user.uid);
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _transactionProvider.dispose();
    _budgetProvider.dispose();
    _ingredientProvider.dispose();
    _productProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        ChangeNotifierProvider<TransactionProvider>.value(
            value: _transactionProvider),
        ChangeNotifierProvider<BudgetProvider>.value(value: _budgetProvider),
        ChangeNotifierProvider<IngredientProvider>.value(
            value: _ingredientProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: _productProvider),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
          '/budget-form': (context) => BudgetFormScreen(
              editing: ModalRoute.of(context)?.settings.arguments as Budget?),
          '/expenses': (context) => const ExpensesScreen(),
          '/transaction-form': (context) => TransactionFormScreen(
              editing: ModalRoute.of(context)?.settings.arguments
                  as AppTransaction?),
          '/reports': (context) => const ReportsScreen(),
          '/ingredients': (context) => const IngredientsScreen(),
          '/ingredient-form': (context) => IngredientFormScreen(
              editing: ModalRoute.of(context)?.settings.arguments as Ingredient?),
          '/products': (context) => const ProductsScreen(),
          '/product-form': (context) {
            final id = ModalRoute.of(context)?.settings.arguments as String?;
            return ProductFormScreen(
                editing: id == null
                    ? null
                    : context.read<ProductProvider>().list
                        .where((p) => p.id == id)
                        .firstOrNull);
          },
          '/product-detail': (context) => const ProductDetailScreen(),
          '/product-scanner': (context) => const ProductScannerScreen(),
          '/product-form-with-barcode': (context) => ProductFormScreen(
              initialBarcode:
                  ModalRoute.of(context)?.settings.arguments as String?),
          '/product-form-with-photo': (context) => ProductFormScreen(
              initialPhotoUrl:
                  ModalRoute.of(context)?.settings.arguments as String?),
          '/settings': (context) => const SettingsScreen(),
          '/settings/profile': (context) => const EditProfileScreen(),
          '/settings/notifications': (context) => const NotificationsScreen(),
          '/settings/security': (context) => const SecurityScreen(),
          '/settings/help': (context) => const HelpScreen(),
        },
        home: const _InitialSplash(),
      ),
    );
  }
}

class _InitialSplash extends StatelessWidget {
  const _InitialSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1E16),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFB89775)),
      ),
    );
  }
}
