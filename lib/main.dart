import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/address_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/review_provider.dart';
import 'providers/wishlist_provider.dart';
import 'repositories/repositories.dart';
import 'core/constants/app_constants.dart';
import 'views/admin/admin_edit_product_screen.dart';
import 'views/admin/admin_main_screen.dart';
import 'views/admin/admin_promo_codes_screen.dart';
import 'views/all_products/all_products_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/details/product_details_screen.dart';
import 'views/home/widgets/filter_bottom_sheet.dart';
import 'views/main_navigation_screen.dart';
import 'views/orders/checkout_screen.dart';
import 'views/orders/order_success_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv loading notice: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository layer (can be mocked/faked in tests)
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        Provider<ProductRepository>(create: (_) => FirestoreProductRepository()),
        Provider<CategoryRepository>(create: (_) => FirestoreCategoryRepository()),
        Provider<BrandRepository>(create: (_) => FirestoreBrandRepository()),
        Provider<OrderRepository>(create: (_) => FirestoreOrderRepository()),
        Provider<PromoRepository>(create: (_) => FirestorePromoRepository()),
        Provider<AddressRepository>(create: (_) => FirestoreAddressRepository()),

        // Providers wired with repositories
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (ctx) => AuthProvider(authRepository: ctx.read<AuthRepository>()),
          update: (ctx, repo, prev) => prev ?? AuthProvider(authRepository: repo),
        ),
        ChangeNotifierProxyProvider<ProductRepository, ProductProvider>(
          create: (ctx) => ProductProvider(productRepository: ctx.read<ProductRepository>()),
          update: (ctx, repo, prev) => prev ?? ProductProvider(productRepository: repo),
        ),
        ChangeNotifierProxyProvider<PromoRepository, CartProvider>(
          create: (ctx) => CartProvider(promoRepository: ctx.read<PromoRepository>(), seedSample: false),
          update: (ctx, repo, prev) => prev ?? CartProvider(promoRepository: repo, seedSample: false),
        ),
        ChangeNotifierProxyProvider<ProductRepository, WishlistProvider>(
          create: (ctx) => WishlistProvider(productRepository: ctx.read<ProductRepository>()),
          update: (ctx, repo, prev) => prev ?? WishlistProvider(productRepository: repo),
        ),
        ChangeNotifierProxyProvider<OrderRepository, OrderProvider>(
          create: (ctx) =>
              OrderProvider(orderRepository: ctx.read<OrderRepository>())..initAdminOrdersStream(),
          update: (ctx, repo, prev) =>
              prev ?? (OrderProvider(orderRepository: repo)..initAdminOrdersStream()),
        ),
        ChangeNotifierProxyProvider<ProductRepository, ReviewProvider>(
          create: (ctx) => ReviewProvider(productRepository: ctx.read<ProductRepository>()),
          update: (ctx, repo, prev) => prev ?? ReviewProvider(productRepository: repo),
        ),
        ChangeNotifierProxyProvider5<CategoryRepository, BrandRepository, PromoRepository, AuthRepository,
            ProductRepository, AdminProvider>(
          create: (ctx) => AdminProvider(
            categoryRepository: ctx.read<CategoryRepository>(),
            brandRepository: ctx.read<BrandRepository>(),
            promoRepository: ctx.read<PromoRepository>(),
            authRepository: ctx.read<AuthRepository>(),
            productRepository: ctx.read<ProductRepository>(),
          ),
          update: (ctx, catRepo, brandRepo, promoRepo, authRepo, prodRepo, prev) =>
              prev ??
              AdminProvider(
                categoryRepository: catRepo,
                brandRepository: brandRepo,
                promoRepository: promoRepo,
                authRepository: authRepo,
                productRepository: prodRepo,
              ),
        ),
        ChangeNotifierProxyProvider<AddressRepository, AddressProvider>(
          create: (ctx) => AddressProvider(addressRepository: ctx.read<AddressRepository>()),
          update: (ctx, repo, prev) => prev ?? AddressProvider(addressRepository: repo),
        ),
      ],
      child: MaterialApp(
        title: 'MegaStore - E-Commerce',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          if (width > 480) {
            return Container(
              color: const Color(0xFF0F172A),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: child,
              ),
            );
          }
          return child!;
        },
        routes: {
          '/home': (_) => const MainNavigationScreen(initialIndex: 0),
          '/filter': (_) => const Scaffold(
                backgroundColor: Color(0x66000000),
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: FilterBottomSheet(),
                ),
              ),
          '/wishlist': (_) => const MainNavigationScreen(initialIndex: 1),
          '/cart': (_) => const MainNavigationScreen(initialIndex: 2),
          '/orders': (_) => const MainNavigationScreen(initialIndex: 3),
          '/profile': (_) => const MainNavigationScreen(initialIndex: 4),
          '/login': (_) => const LoginScreen(),
          '/checkout': (_) => const CheckoutScreen(),
          '/details': (_) => ProductDetailsScreen(product: AppConstants.initialProducts.first),
          '/order-success': (_) => OrderSuccessScreen(order: OrderProvider.sampleOrders.first),
          '/all-products': (_) => const AllProductsScreen(title: 'All Products'),
          '/admin': (_) => const AdminMainScreen(initialIndex: 0),
          '/admin/products': (_) => const AdminMainScreen(initialIndex: 1),
          '/admin/orders': (_) => const AdminMainScreen(initialIndex: 2),
          '/admin/catalog': (_) => const AdminMainScreen(initialIndex: 3),
          '/admin/users': (_) => const AdminMainScreen(initialIndex: 4),
          '/admin/add-product': (_) => const AdminEditProductScreen(),
          '/admin/promo-codes': (_) => const AdminPromoCodesScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Synchronize current user ID with cart, wishlist, orders, and addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<CartProvider>().updateUserId(auth.userId);
        context.read<WishlistProvider>().updateUserId(auth.userId);
        context.read<OrderProvider>().updateUserId(auth.userId);
        context.read<AddressProvider>().initAddresses(auth.userId);
      }
    });

    if (auth.isAdmin) {
      return const AdminMainScreen();
    }

    return const MainNavigationScreen();
  }
}
