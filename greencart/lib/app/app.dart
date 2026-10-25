import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database/app_database.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cart_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/order_repository.dart';
import '../features/auth/auth_provider.dart';
import '../features/cart/cart_provider.dart';
import '../features/notifications/notifications_provider.dart';
import '../features/orders/orders_provider.dart';
import '../features/products/catalog_provider.dart';
import '../features/profile/address_provider.dart';
import '../features/profile/settings_provider.dart';
import '../features/auth/splash_screen.dart';
import '../features/seller/seller_provider.dart';
import 'shell_tab_provider.dart';
import 'theme/app_theme.dart';

class GreenCartApp extends StatelessWidget {
  const GreenCartApp({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final db = database.db;
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider(create: (_) => AuthRepository(db)),
        Provider(create: (_) => CartRepository(db)),
        Provider(create: (_) => CatalogRepository(db)),
        Provider(create: (_) => OrderRepository(db)),
        Provider(create: (_) => NotificationRepository(db)),
        Provider(create: (_) => AddressRepository(db)),
        ChangeNotifierProvider(create: (c) => AuthProvider(c.read<AuthRepository>(), c.read<CartRepository>())..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (c) => CatalogProvider(c.read<CatalogRepository>())..reload()),
        ChangeNotifierProvider(create: (_) => ShellTabProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (c) => CartProvider(c.read<CartRepository>()),
          update: (_, auth, prev) => prev!..setOwner(auth.ownerId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (c) => OrdersProvider(c.read<OrderRepository>()),
          update: (_, auth, prev) => prev!..setOwner(auth.ownerId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (c) => NotificationsProvider(c.read<NotificationRepository>()),
          update: (_, auth, prev) => prev!..setOwner(auth.ownerId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AddressProvider>(
          create: (c) => AddressProvider(c.read<AddressRepository>()),
          update: (_, auth, prev) => prev!..setOwner(auth.ownerId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SellerProvider>(
          create: (c) => SellerProvider(
            c.read<CatalogRepository>(),
            c.read<OrderRepository>(),
            c.read<CatalogProvider>(),
            c.read<OrdersProvider>(),
            c.read<NotificationsProvider>(),
          ),
          update: (_, auth, prev) => prev!..setOwner(auth.user?.isSeller == true ? auth.ownerId : 0),
        ),
      ],
      child: MaterialApp(
        title: 'GreenCart',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
