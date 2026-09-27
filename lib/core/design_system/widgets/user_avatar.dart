import 'package:flutter/material.dart';

/// A round avatar with the person's initial, or a person icon without a name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.name, this.radius = 36});

  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name?.trim().characters.firstOrNull?.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      child: initial == null
          ? Icon(Icons.person, size: radius)
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
