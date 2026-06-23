import 'package:academic_project/presentation/navigation/app_navigation.dart';
import 'package:academic_project/presentation/theme/app_theme.dart';
import 'package:academic_project/presentation/settings/provider/settings_provider.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'package:dio/dio.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendConnection();
    });
  }

  Future<void> _checkBackendConnection() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // We do a GET request to the base URL.
      // Even if it returns 403 or 404, the DioException will be thrown,
      // but we can catch it and if it has a response (like 403), it means the server is running!
      final response = await dio.get('/');
      _showToast('Backend Connection Success! (Status: ${response.statusCode})', Colors.green);
    } on DioException catch (e) {
      if (e.response != null) {
        // If there's a response, the server is alive and talking to us (e.g., 403 Forbidden).
        _showToast('Backend Connection Success! Server is running.', Colors.green);
      } else {
        // No response means connection failed/timeout.
        _showToast('Backend Connection Failed: ${e.message}', Colors.red);
      }
    } catch (e) {
      _showToast('Backend Connection Failed: $e', Colors.red);
    }
  }

  void _showToast(String message, Color color) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider2);
    final settingsVal = ref.watch(settingsProvider);

    final themeStr = settingsVal.maybeWhen(
      data: (s) => s.theme,
      orElse: () => 'light',
    );

    return MaterialApp.router(
      title: 'EduVision',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: themeStr == 'dark' ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
      ),
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
    );
  }
}
