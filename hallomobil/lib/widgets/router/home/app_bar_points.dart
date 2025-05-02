import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class AppBarPoints extends StatelessWidget {
  final int points;

  const AppBarPoints({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.08),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      decoration: BoxDecoration(
        color: ColorConstants.MAINCOLOR,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: ColorConstants.WHITE,
            size: 30,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Text(
            points.toString(),
            style: const TextStyle(color: ColorConstants.WHITE),
          ),
        ],
      ),
    );
  }
}
