import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppSnackBarType { info, success, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
}) {
  Color backgroundColor;
  IconData icon;

  switch (type) {
    case AppSnackBarType.success:
      backgroundColor = Colors.green.shade600;
      icon = Icons.check_circle_outline_rounded;
      break;
    case AppSnackBarType.error:
      backgroundColor = AppTheme.error;
      icon = Icons.error_outline_rounded;
      break;
    case AppSnackBarType.info:
    default:
      backgroundColor = AppTheme.primaryOrange;
      icon = Icons.info_outline_rounded;
      break;
  }

  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
  );

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(snackBar);
}
