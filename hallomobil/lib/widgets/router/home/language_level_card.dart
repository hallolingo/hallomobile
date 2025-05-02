import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class LanguageLevelCard extends StatelessWidget {
  final String level;
  final String imagePath;

  const LanguageLevelCard({
    super.key,
    required this.level,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.width * 0.02,
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      decoration: BoxDecoration(
        color: ColorConstants.MAINCOLOR,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: ColorConstants.WHITE,
            radius: MediaQuery.of(context).size.width * 0.1,
            child: Image.asset(
              imagePath,
              width: MediaQuery.of(context).size.width * 0.1,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Almanca Seviyen',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  color: ColorConstants.WHITE,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.01),
              Text(
                level,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: ColorConstants.WHITE,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
