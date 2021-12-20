import 'package:flutter/material.dart';

class BorderedTab extends StatelessWidget {
  const BorderedTab({
    Key? key,
    required this.text,
    this.icon,
    this.child,
    this.borderColor = Colors.grey,
    this.width = 0.5,
  }) : super(key: key);

  final String text;
  final Widget? icon;
  final Widget? child;
  final Color borderColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Tab(
        text: text,
        icon: icon,
        child: child,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: width,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
