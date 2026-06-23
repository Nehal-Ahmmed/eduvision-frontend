import 'package:flutter/material.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://eduvision-backend-jnuf.onrender.com',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gbokmjcsddiekdbaaiij.supabase.co',
  );

  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdib2ttamNzZGRpZWtkYmFhaWlqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODI2NTI4NywiZXhwIjoyMDkzODQxMjg3fQ.us7FJ9Uy_eCsT7_u1_Ihw-6oS1ow__919_BXLV88IUc',
  );
}

class AppColors {
  // Background Gradients
  static const gradientStart = Color(0xFFEFF6FF); // blue-50
  static const gradientMiddle = Color(0xFFEEF2FF); // indigo-50
  static const gradientEnd = Color(0xFFFAF5FF); // purple-50

  // Main Colors
  static const blue900 = Color(0xFF1E3A8A);
  static const blue800 = Color(0xFF1E40AF);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue600 = Color(0xFF2563EB);
  static const blue500 = Color(0xFF3B82F6);
  static const blue400 = Color(0xFF60A5FA);
  static const blue300 = Color(0xFF93C5FD);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);

  static const indigo900 = Color(0xFF312E81);
  static const indigo800 = Color(0xFF3730A3);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo200 = Color(0xFFC7D2FE);
  static const indigo50 = Color(0xFFEEF2FF);

  static const purple900 = Color(0xFF581C87);
  static const purple800 = Color(0xFF6B21A8);
  static const purple700 = Color(0xFF7E22CE);
  static const purple600 = Color(0xFF9333EA);
  static const purple500 = Color(0xFFA855F7);
  static const purple400 = Color(0xFFC084FC);
  static const purple200 = Color(0xFFE9D5FF);
  static const purple50 = Color(0xFFFAF5FF);

  static const green900 = Color(0xFF14532D);
  static const green800 = Color(0xFF166534);
  static const green700 = Color(0xFF15803D);
  static const green600 = Color(0xFF16A34A);
  static const green500 = Color(0xFF22C55E);
  static const green400 = Color(0xFF4ADE80);
  static const green200 = Color(0xFFBBF7D0);
  static const green50 = Color(0xFFF0FDF4);

  static const emerald50 = Color(0xFFECFDF5);

  static const yellow900 = Color(0xFF78350F);
  static const yellow800 = Color(0xFF92400E);
  static const yellow700 = Color(0xFFA16207);
  static const yellow600 = Color(0xFFCA8A04);
  static const yellow400 = Color(0xFFFACC15);
  static const yellow200 = Color(0xFFFEF08A);
  static const yellow100 = Color(0xFFFEF3C7);
  static const yellow50 = Color(0xFFFEFCE8);

  static const orange900 = Color(0xFF7C2D12);
  static const orange800 = Color(0xFF9A3412);
  static const orange600 = Color(0xFFEA580C);
  static const orange500 = Color(0xFFF97316);
  static const orange200 = Color(0xFFFED7AA);
  static const orange50 = Color(0xFFFFF7ED);

  static const pink50 = Color(0xFFFDF2F8);

  static const red900 = Color(0xFF7F1D1D);
  static const red600 = Color(0xFFDC2626);
  static const red500 = Color(0xFFEF4444);
  static const red400 = Color(0xFFF87171);
  static const red300 = Color(0xFFFCA5A5);
  static const red200 = Color(0xFFFECACA);
  static const red50 = Color(0xFFFEF2F2);

  // Neutral Colors
  static const white = Color(0xFFFFFFFF);
  static const gray900 = Color(0xFF111827);
  static const gray800 = Color(0xFF1F2937);
  static const gray700 = Color(0xFF374151);
  static const gray600 = Color(0xFF4B5563);
  static const gray500 = Color(0xFF6B7280);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray50 = Color(0xFFF9FAFB);

  // Notebook Theme Colors
  static const notebookSpiral = Color(0xFFFECACA);
  static const notebookSpiralDark = Color(0xFFFCA5A5);
  static const notebookBorder = Color(0xFFF87171);
  static const notebookLines = Color(0xFFBFDBFE);
}

class AppTextStyles {
  static const studentTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.75,
    height: 1.5,
  );

  static const pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static const sectionHeading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const subsectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const smallMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const extraSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;
  static const double full = 9999;
}

class SmartNotesTheme {
  // Colors
  static const Color bgMain = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF9FAFB);
  static const Color bgTertiary = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textMain = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDark = Colors.black;
  static const Color accent = Color(0xFFF3F4F6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color iconColor = Color(0xFF9CA3AF);
  static const Color iconActive = Color(0xFF111827);
  static const Color iconDark = Colors.black;

  // Sizes
  static const double leftSidebarWidth = 260.0;
  static const double aiSidebarWidth = 320.0;
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    color: textMain,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    color: textMain,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle body = TextStyle(color: textMain, fontSize: 14);
  static const TextStyle bodySmall = TextStyle(color: textMain, fontSize: 13);
  static const TextStyle caption = TextStyle(color: textMuted, fontSize: 12);
  static const TextStyle tiny = TextStyle(color: textMuted, fontSize: 11);
}
