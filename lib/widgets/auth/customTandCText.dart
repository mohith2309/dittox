import 'package:flutter/material.dart';

class CustomTandCText extends StatelessWidget {
  final String title;
  final String text;
  const CustomTandCText({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        Text(text),
      ],
    );
  }
}
