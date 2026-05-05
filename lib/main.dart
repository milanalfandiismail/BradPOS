import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'package:bradpos/presentation/blocs/dashboard_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/core/widgets/splash_page.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Entry point aplikasi BradPOS.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
  await di.init();
  runApp(const BradPOSApp());
}

class BradPOSApp extends StatefulWidget {
  const BradPOSApp({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_BradPOSAppState>()?.restartApp();
  }

  @override
  State<BradPOSApp> createState() => _BradPOSAppState();
}

class _BradPOSAppState extends State<BradPOSApp> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus())),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<KaryawanBloc>()),
        BlocProvider(create: (_) => di.sl<InventoryBloc>()),
        BlocProvider(create: (_) => di.sl<CashierBloc>()),
        BlocProvider(create: (_) => di.sl<HistoryBloc>()),
      ],
      child: MaterialApp(
        title: 'BradPOS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF065F46)),
          useMaterial3: true,
          fontFamily: 'Inter',
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
