import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_store.dart';
import 'services/cart_store.dart';
import 'services/api.dart';
import 'utils/theme.dart';
import 'screens/shell.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pay_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const MallApp());
}

class MallApp extends StatelessWidget {
  const MallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthStore();
    final cart = CartStore(auth);
    final api = Api(auth);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/auth', builder: (_, s) => const AuthScreen()),
        GoRoute(
            path: '/pay/:orderId',
            builder: (_, s) => PayScreen(orderId: s.pathParameters['orderId']!)),
        ShellRoute(
          builder: (_, __, child) => Shell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(
                path: '/products',
                builder: (_, s) =>
                    ProductListScreen(category: s.uri.queryParameters['cat'])),
            GoRoute(
                path: '/products/:id',
                builder: (_, s) =>
                    ProductDetailScreen(id: s.pathParameters['id']!)),
            GoRoute(
                path: '/search',
                builder: (_, s) =>
                    SearchScreen(q: s.uri.queryParameters['q'] ?? '')),
            GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
            GoRoute(
                path: '/checkout',
                builder: (_, __) => const CheckoutScreen()),
            GoRoute(
                path: '/profile',
                builder: (_, s) =>
                    ProfileScreen(tab: s.uri.queryParameters['tab'])),
          ],
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: cart),
        Provider.value(value: api),
      ],
      child: MaterialApp.router(
        title: '道地本草',
        theme: AppTheme.theme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
