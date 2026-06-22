import 'package:academic_project/presentation/navigation/app_navigation.dart';
import 'package:academic_project/presentation/theme/app_theme.dart';
import 'package:academic_project/presentation/settings/provider/settings_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider2);
    final settingsVal = ref.watch(settingsProvider);

    final themeStr = settingsVal.maybeWhen(
      data: (s) => s.theme,
      orElse: () => 'light',
    );

    return MaterialApp.router(
      title: 'EduVision',
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
