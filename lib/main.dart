import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/karyawan/presentation/bloc/karyawan_bloc.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'core/widgets/splash_page.dart';

/// Entry point aplikasi BradPOS.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();
  runApp(const MyApp());
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
      ],
      child: MaterialApp(
        title: 'BradPOS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF065F46)),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const SplashPage(),
      ),
    );
  }
}
