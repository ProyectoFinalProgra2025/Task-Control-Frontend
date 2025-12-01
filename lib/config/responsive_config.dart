import 'package:flutter/material.dart';

/// Configuración global de responsividad para la aplicación
/// Soporta desde 300px hasta pantallas grandes
class ResponsiveConfig {
  // Breakpoints
  static const double mobileSmall = 300;
  static const double mobileMedium = 360;
  static const double mobileLarge = 400;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  /// Obtener el tipo de dispositivo basado en el ancho
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMedium) return DeviceType.mobileSmall;
    if (width < mobileLarge) return DeviceType.mobileMedium;
    if (width < tablet) return DeviceType.mobileLarge;
    if (width < desktop) return DeviceType.tablet;
    if (width < desktopLarge) return DeviceType.desktop;
    return DeviceType.desktopLarge;
  }

  /// ¿Es una pantalla pequeña (< 360px)?
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMedium;
  }

  /// ¿Es móvil (< 600px)?
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// ¿Es tablet (600-1024px)?
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// ¿Es desktop (>= 1024px)?
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Obtener padding horizontal responsivo
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileSmall) return 8;
    if (width < mobileMedium) return 12;
    if (width < mobileLarge) return 16;
    if (width < tablet) return 20;
    if (width < desktop) return 24;
    return 32;
  }

  /// Obtener padding vertical responsivo
  static double getVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMedium) return 12;
    if (width < tablet) return 16;
    return 20;
  }

  /// Obtener tamaño de fuente responsivo para títulos
  static double getTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileSmall) return 18;
    if (width < mobileMedium) return 20;
    if (width < mobileLarge) return 22;
    if (width < tablet) return 24;
    return 28;
  }

  /// Obtener tamaño de fuente responsivo para subtítulos
  static double getSubtitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileSmall) return 12;
    if (width < mobileMedium) return 13;
    if (width < mobileLarge) return 14;
    return 16;
  }

  /// Obtener tamaño de fuente responsivo para cuerpo
  static double getBodyFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileSmall) return 11;
    if (width < mobileMedium) return 12;
    if (width < mobileLarge) return 13;
    return 14;
  }

  /// Obtener tamaño de iconos responsivo
  static double getIconSize(BuildContext context, {IconSizeType type = IconSizeType.medium}) {
    final width = MediaQuery.of(context).size.width;
    
    switch (type) {
      case IconSizeType.small:
        if (width < mobileMedium) return 14;
        if (width < tablet) return 16;
        return 18;
      case IconSizeType.medium:
        if (width < mobileMedium) return 18;
        if (width < tablet) return 20;
        return 24;
      case IconSizeType.large:
        if (width < mobileMedium) return 24;
        if (width < tablet) return 28;
        return 32;
      case IconSizeType.xlarge:
        if (width < mobileMedium) return 32;
        if (width < tablet) return 40;
        return 48;
    }
  }

  /// Obtener número de columnas para grids
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileLarge) return 1;
    if (width < tablet) return 2;
    if (width < desktop) return 3;
    return 4;
  }

  /// Obtener espaciado entre elementos
  static double getSpacing(BuildContext context, {SpacingType type = SpacingType.medium}) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < mobileMedium;
    
    switch (type) {
      case SpacingType.xs:
        return isSmall ? 2 : 4;
      case SpacingType.small:
        return isSmall ? 4 : 8;
      case SpacingType.medium:
        return isSmall ? 8 : 12;
      case SpacingType.large:
        return isSmall ? 12 : 16;
      case SpacingType.xl:
        return isSmall ? 16 : 24;
    }
  }

  /// Obtener tamaño de avatar responsivo
  static double getAvatarSize(BuildContext context, {AvatarSizeType type = AvatarSizeType.medium}) {
    final width = MediaQuery.of(context).size.width;
    
    switch (type) {
      case AvatarSizeType.small:
        if (width < mobileMedium) return 28;
        if (width < tablet) return 32;
        return 36;
      case AvatarSizeType.medium:
        if (width < mobileMedium) return 36;
        if (width < tablet) return 40;
        return 48;
      case AvatarSizeType.large:
        if (width < mobileMedium) return 48;
        if (width < tablet) return 56;
        return 64;
      case AvatarSizeType.xlarge:
        if (width < mobileMedium) return 64;
        if (width < tablet) return 80;
        return 100;
    }
  }

  /// Obtener altura de botón responsiva
  static double getButtonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMedium) return 40;
    if (width < tablet) return 44;
    return 48;
  }

  /// Obtener radio de borde responsivo
  static double getBorderRadius(BuildContext context, {BorderRadiusType type = BorderRadiusType.medium}) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < mobileMedium;
    
    switch (type) {
      case BorderRadiusType.small:
        return isSmall ? 4 : 6;
      case BorderRadiusType.medium:
        return isSmall ? 8 : 12;
      case BorderRadiusType.large:
        return isSmall ? 12 : 16;
      case BorderRadiusType.xl:
        return isSmall ? 16 : 24;
      case BorderRadiusType.circular:
        return 1000;
    }
  }

  /// Obtener ancho máximo de contenido
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tablet) return width;
    if (width < desktop) return width * 0.9;
    return 1200;
  }
}

/// Tipos de dispositivo
enum DeviceType {
  mobileSmall,  // < 360px
  mobileMedium, // 360-400px
  mobileLarge,  // 400-600px
  tablet,       // 600-1024px
  desktop,      // 1024-1440px
  desktopLarge, // > 1440px
}

/// Tipos de tamaño de icono
enum IconSizeType { small, medium, large, xlarge }

/// Tipos de espaciado
enum SpacingType { xs, small, medium, large, xl }

/// Tipos de tamaño de avatar
enum AvatarSizeType { small, medium, large, xlarge }

/// Tipos de radio de borde
enum BorderRadiusType { small, medium, large, xl, circular }

/// Extension para acceso rápido a configuración responsiva
extension ResponsiveContext on BuildContext {
  /// Acceso rápido a configuración responsiva
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

/// Helper class para acceso fluido a valores responsivos
class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  // Getters rápidos
  bool get isSmall => ResponsiveConfig.isSmallScreen(context);
  bool get isMobile => ResponsiveConfig.isMobile(context);
  bool get isTablet => ResponsiveConfig.isTablet(context);
  bool get isDesktop => ResponsiveConfig.isDesktop(context);
  
  double get horizontalPadding => ResponsiveConfig.getHorizontalPadding(context);
  double get verticalPadding => ResponsiveConfig.getVerticalPadding(context);
  
  double get titleSize => ResponsiveConfig.getTitleFontSize(context);
  double get subtitleSize => ResponsiveConfig.getSubtitleFontSize(context);
  double get bodySize => ResponsiveConfig.getBodyFontSize(context);
  
  double get buttonHeight => ResponsiveConfig.getButtonHeight(context);
  int get gridColumns => ResponsiveConfig.getGridColumns(context);
  double get maxWidth => ResponsiveConfig.getMaxContentWidth(context);
  
  double icon([IconSizeType type = IconSizeType.medium]) => 
      ResponsiveConfig.getIconSize(context, type: type);
  
  double spacing([SpacingType type = SpacingType.medium]) => 
      ResponsiveConfig.getSpacing(context, type: type);
  
  double avatar([AvatarSizeType type = AvatarSizeType.medium]) => 
      ResponsiveConfig.getAvatarSize(context, type: type);
  
  double radius([BorderRadiusType type = BorderRadiusType.medium]) => 
      ResponsiveConfig.getBorderRadius(context, type: type);
  
  /// Selector condicional basado en tamaño de pantalla
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
