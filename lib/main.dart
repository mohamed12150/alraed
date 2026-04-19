import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'logic/providers/cart_provider.dart';
import 'logic/providers/theme_provider.dart';
import 'logic/providers/language_provider.dart';
import 'logic/providers/shop_provider.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/navigation_provider.dart';
import 'logic/providers/orders_provider.dart';
import 'logic/providers/connectivity_provider.dart';
import 'logic/providers/location_provider.dart';
import 'logic/providers/notifications_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'presentation/screens/no_internet_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null && supabaseKey != null) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }

  OneSignal.initialize('b4dd4cad-ad7c-459f-bf22-36c97481ee63');
  await OneSignal.Notifications.requestPermission(true);

  // عرض الإشعار حتى لو التطبيق مفتوح
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.notification.display();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: Consumer3<ThemeProvider, LanguageProvider, ConnectivityProvider>(
        builder: (context, themeProvider, languageProvider, connectivityProvider, child) {
          return MaterialApp.router(
            title: 'الرائد للذبائح - Al Raed',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ar', ''), // Arabic
            ],
            routerConfig: AppRouter.router,
            builder: (context, child) {
              if (connectivityProvider.status == ConnectivityStatus.isDisconnected) {
                return NoInternetScreen(
                  onRetry: () => connectivityProvider.checkNow(),
                );
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
