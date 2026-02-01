import 'package:flutter/material.dart';

/// A reusable widget that provides a consistent gradient background across the app.
/// 
/// To change the main color for all screens, modify the [primaryColor] parameter
/// or update the Theme's primaryColor in your app's theme configuration.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryColor;
  
  const GradientBackground({
    super.key,
    required this.child,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).primaryColor;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: child,
    );
  }
}
