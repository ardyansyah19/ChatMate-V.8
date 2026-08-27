import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';

class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String initials;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.65,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Text(
            initials,
            style: TextStyle(color: Colors.white, fontSize: radius * 0.6),
          ),
          errorWidget: (context, url, error) => Text(
            initials,
            style: TextStyle(color: Colors.white, fontSize: radius * 0.6),
          ),
        ),
      ),
    );
  }
}
