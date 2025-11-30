import 'package:flutter/material.dart';
import '../config/responsive_config.dart';

/// Widget wrapper que aplica responsividad automática a cualquier pantalla
/// Envuelve el contenido con padding y scroll apropiados para pantallas pequeñas
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// Widget que adapta su contenido a pantallas pequeñas
/// Ideal para formularios y contenido que necesita scroll
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool addHorizontalPadding;
  final bool addVerticalPadding;
  final bool centerContent;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.addHorizontalPadding = true,
    this.addVerticalPadding = false,
    this.centerContent = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    Widget content = child;
    
    // Aplicar padding si es necesario
    if (padding != null || addHorizontalPadding || addVerticalPadding) {
      content = Padding(
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: addHorizontalPadding ? r.horizontalPadding : 0,
          vertical: addVerticalPadding ? r.verticalPadding : 0,
        ),
        child: content,
      );
    }
    
    // Limitar ancho máximo si es necesario
    final effectiveMaxWidth = maxWidth ?? r.maxWidth;
    if (effectiveMaxWidth < MediaQuery.of(context).size.width) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    } else if (centerContent) {
      content = Center(child: content);
    }
    
    return content;
  }
}

/// Widget para texto responsivo que ajusta su tamaño automáticamente
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextType type;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.type = TextType.body,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    double fontSize;
    switch (type) {
      case TextType.title:
        fontSize = r.titleSize;
        break;
      case TextType.subtitle:
        fontSize = r.subtitleSize;
        break;
      case TextType.body:
        fontSize = r.bodySize;
        break;
      case TextType.caption:
        fontSize = r.bodySize - 2;
        break;
    }
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Tipo de texto para ResponsiveText
enum TextType { title, subtitle, body, caption }

/// Widget para espaciado responsivo
class ResponsiveGap extends StatelessWidget {
  final SpacingType type;
  final bool horizontal;

  const ResponsiveGap({
    super.key,
    this.type = SpacingType.medium,
    this.horizontal = false,
  });

  const ResponsiveGap.xs({super.key, this.horizontal = false}) : type = SpacingType.xs;
  const ResponsiveGap.small({super.key, this.horizontal = false}) : type = SpacingType.small;
  const ResponsiveGap.medium({super.key, this.horizontal = false}) : type = SpacingType.medium;
  const ResponsiveGap.large({super.key, this.horizontal = false}) : type = SpacingType.large;
  const ResponsiveGap.xl({super.key, this.horizontal = false}) : type = SpacingType.xl;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveConfig.getSpacing(context, type: type);
    return horizontal 
        ? SizedBox(width: size)
        : SizedBox(height: size);
  }
}

/// Widget para crear un grid responsivo
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? columns;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.columns,
    this.childAspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final cols = columns ?? r.gridColumns;
    final space = spacing ?? r.spacing();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: space,
        mainAxisSpacing: runSpacing ?? space,
        childAspectRatio: childAspectRatio ?? 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Widget que muestra diferentes layouts según el tamaño de pantalla
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    if (r.isDesktop && desktop != null) return desktop!;
    if (r.isTablet && tablet != null) return tablet!;
    return mobile;
  }
}

/// Botón responsivo que ajusta su tamaño
class ResponsiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isPrimary;
  final bool isFullWidth;
  final bool isLoading;

  const ResponsiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    final buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? Colors.white : Theme.of(context).primaryColor,
            ),
          )
        : child;
    
    final button = isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: (style ?? ElevatedButton.styleFrom()).copyWith(
              minimumSize: WidgetStateProperty.all(
                Size(isFullWidth ? double.infinity : 0, r.buttonHeight),
              ),
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(
                  horizontal: r.spacing(SpacingType.large),
                  vertical: r.spacing(SpacingType.small),
                ),
              ),
            ),
            child: buttonChild,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: (style ?? OutlinedButton.styleFrom()).copyWith(
              minimumSize: WidgetStateProperty.all(
                Size(isFullWidth ? double.infinity : 0, r.buttonHeight),
              ),
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(
                  horizontal: r.spacing(SpacingType.large),
                  vertical: r.spacing(SpacingType.small),
                ),
              ),
            ),
            child: buttonChild,
          );
    
    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Card responsivo
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    final card = Card(
      color: color,
      elevation: elevation,
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: r.spacing(SpacingType.small),
        vertical: r.spacing(SpacingType.xs),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radius()),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(r.spacing()),
        child: child,
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.radius()),
        child: card,
      );
    }
    
    return card;
  }
}

/// Avatar responsivo
class ResponsiveAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSizeType size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSizeType.medium,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveConfig.getAvatarSize(context, type: size);
    final fontSize = avatarSize * 0.4;
    
    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null && initials != null
          ? Text(
              initials!,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

/// Input field responsivo
class ResponsiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const ResponsiveTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: r.bodySize),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.spacing(),
          vertical: r.spacing(SpacingType.small),
        ),
        labelStyle: TextStyle(fontSize: r.bodySize),
        hintStyle: TextStyle(fontSize: r.bodySize),
        errorStyle: TextStyle(fontSize: r.bodySize - 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius()),
        ),
      ),
    );
  }
}
