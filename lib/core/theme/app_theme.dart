import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema escuro fixo do Vetora (Trabalho 1, seção 03).
///
/// Inter é usada nos textos e JetBrains Mono nos dados, unidades e rótulos
/// técnicos, pelos estilos estáticos de [AppTextStyles].
abstract final class AppTheme {
  static const fontText = 'Inter';
  static const fontMono = 'JetBrainsMono';

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.ciano,
      onPrimary: AppColors.grafite, // texto escuro no botão ciano (6,0 : 1)
      secondary: AppColors.ciano,
      onSecondary: AppColors.grafite,
      surface: AppColors.grafite,
      onSurface: AppColors.brancoTecnico,
      surfaceContainer: AppColors.superficie,
      surfaceContainerHigh: AppColors.superficieElevada,
      outline: AppColors.borda,
      onSurfaceVariant: AppColors.textoSecundario,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.grafite,
      fontFamily: fontText,
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.titulo,
        bodyLarge: AppTextStyles.corpo,
        labelSmall: AppTextStyles.rotulo,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ciano,
          foregroundColor: AppColors.grafite,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.botao,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textoTerciario,
          textStyle: AppTextStyles.rotulo,
        ),
      ),
      // A barra do topo ganha a cor de superfície quando o conteúdo rola por
      // baixo dela: separa os planos sem sombra.
      appBarTheme: AppBarTheme(
        backgroundColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.scrolledUnder)
              ? AppColors.superficie
              : AppColors.grafite,
        ),
        foregroundColor: AppColors.brancoTecnico,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.superficie,
        indicatorColor: AppColors.cianoProfundo,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ciano
                : AppColors.textoSecundario,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontText,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.brancoTecnico
                : AppColors.textoSecundario,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.superficieElevada,
        contentTextStyle: TextStyle(
          fontFamily: fontText,
          fontSize: 14,
          color: AppColors.brancoTecnico,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borda),
        ),
      ),
    );
  }
}

/// Escala tipográfica de referência (Trabalho 1, seção 03 — Tipografia).
abstract final class AppTextStyles {
  static const titulo = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.brancoTecnico,
  );

  static const corpo = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 16,
    height: 1.5,
    color: AppColors.textoSecundario,
  );

  static const rotulo = TextStyle(
    fontFamily: AppTheme.fontMono,
    fontSize: 12,
    letterSpacing: 2,
    color: AppColors.textoTerciario,
  );

  /// Título de seção da Home ("Mais estudados").
  static const secao = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.brancoTecnico,
  );

  /// Título dentro de cartões.
  static const tituloCartao = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.brancoTecnico,
  );

  /// Texto de apoio menor (descrições de cartões e mensagens).
  static const apoio = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 13,
    height: 1.5,
    color: AppColors.textoSecundario,
  );

  static const valor = TextStyle(
    fontFamily: AppTheme.fontMono,
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AppColors.brancoTecnico,
  );

  static const botao = TextStyle(
    fontFamily: AppTheme.fontText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const logotipo = TextStyle(
    fontFamily: AppTheme.fontMono,
    fontWeight: FontWeight.w700,
    letterSpacing: 6,
    color: AppColors.brancoTecnico,
  );
}
