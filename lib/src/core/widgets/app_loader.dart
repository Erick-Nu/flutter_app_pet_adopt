import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? label;
  final double iconPadding;

  const AppLoader({
    super.key,
    this.size = 40,
    this.color,
    this.label,
    this.iconPadding = 0,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderColor = widget.color ?? AppTheme.primaryOrange;

    final icon = RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.pets,
        size: widget.size,
        color: loaderColor,
      ),
    );

    if (widget.label == null) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(widget.iconPadding),
          child: icon,
        ),
        Text(widget.label!, style: const TextStyle(color: AppTheme.textPrimary)),
      ],
    );
  }
}
