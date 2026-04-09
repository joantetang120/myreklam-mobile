import 'package:flutter/material.dart';

class CategoriesIcon extends StatelessWidget {
  final String title;
  final Color iconColor;
  final Color bgColor;
  final IconData? icon;
  final String? iconAsset;
  final VoidCallback? onTap;

  const CategoriesIcon({
    super.key,
    required this.title,
    required this.iconColor,
    required this.bgColor,
    this.icon,
    this.iconAsset,
    this.onTap,
  }) : assert(
         icon != null || iconAsset != null,
         'Either icon or iconAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        spacing: 5,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: Center(
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: iconColor,
                          size: 20,
                        );
                      },
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
          ),
          Text(title, style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}
