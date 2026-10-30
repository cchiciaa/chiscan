import 'package:flutter/material.dart';

/// Kontainer adaptif untuk memastikan tampilan nyaman baik di layar kecil (ponsel)
/// maupun layar lebar (tablet, desktop, dan web) dengan membatasi lebar maksimal
/// dan memusatkan konten secara proporsional.
class AdaptiveContainer extends StatelessWidget {
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
