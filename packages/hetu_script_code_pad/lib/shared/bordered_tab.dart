import 'package:flutter/material.dart';

class BorderedTab extends StatelessWidget {
  const BorderedTab({
    super.key,
    required this.text,
    this.icon,
    this.child,
    this.borderColor = Colors.grey,
    this.width = 0.5,
  });

  final String text;
  final Widget? icon;
  final Widget? child;
  final Color borderColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: width,
            color: borderColor,
          ),
        ),
      ),
      child: Tab(
        text: text,
        icon: icon,
        child: child,
      ),
    );
  }
}
