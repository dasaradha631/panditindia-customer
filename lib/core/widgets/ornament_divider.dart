import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Small gold diamond rule used between the splash headline and dots.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.color = AppColors.gold});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _line(),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        _line(),
      ],
    );
  }

  Widget _line() => Container(
        width: 54,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Colors.transparent, color, Colors.transparent],
          ),
        ),
      );
}
