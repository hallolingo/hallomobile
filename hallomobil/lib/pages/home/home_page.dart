import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/home/home_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        backgroundColor: ColorConstants.WHITE,
        title: Image.asset(HomeConstants.APPBARLOGO,
            width: MediaQuery.of(context).size.width * 0.5),
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.only(
                right: MediaQuery.of(context).size.width * 0.08),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
            decoration: BoxDecoration(
              color: ColorConstants.MAINCOLOR,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: ColorConstants.WHITE,
                  size: 30,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Text(
                  '2400',
                  style: TextStyle(color: ColorConstants.WHITE),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
