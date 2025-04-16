import 'package:flutter/material.dart';

class ProfileHeaderColumn extends StatelessWidget {
  const ProfileHeaderColumn({
    super.key,
    required this.title,
    required this.width,
  });

  final String title;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        // Ensure the text is centered within the column
        child: Text(
          title,
          textAlign: TextAlign.center, // Center the text horizontally
          style:
              Theme.of(context).textTheme.bodyLarge, // Use consistent styling
        ),
      ),
    );
  }
}
