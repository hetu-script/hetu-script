import 'package:flutter/material.dart';

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    Key? key,
    this.iconSize = 24.0,
    required this.icon,
    this.tooltip,
    this.onPressed,
  }) : super(key: key);

  final double iconSize;

  final Widget icon;

  final String? tooltip;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 6,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: IconButton(
        iconSize: iconSize,
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
