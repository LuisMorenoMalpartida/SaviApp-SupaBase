import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool fullWidth;

  const AppButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.fullWidth = true});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(onPressed: onPressed, child: child);
    if (fullWidth) {
      return SizedBox(width: double.infinity, height: 52, child: btn);
    }
    return btn;
  }
}
