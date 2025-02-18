import 'package:flutter/material.dart';

class CustomInfoBox extends StatelessWidget {
  final String title;
  final String info;
  final Color infoColor;

  const CustomInfoBox({
    super.key,
    required this.title,
    required this.info,
    required this.infoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF77347A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                info,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: infoColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
