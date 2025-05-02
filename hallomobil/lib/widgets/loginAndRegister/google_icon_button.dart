import 'package:flutter/material.dart';

class CircularIconButton extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onPressed;
  final double size;
  final Color backgroundColor;
  final double padding;

  const CircularIconButton({
    super.key,
    required this.image,
    required this.onPressed,
    this.size = 50,
    this.backgroundColor = Colors.white,
    this.padding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(padding),
          child: Image(image: image),
        ),
      ),
    );
  }
}
