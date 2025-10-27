import 'package:flutter/material.dart';
import 'package:gradient_borders/gradient_borders.dart';
import '../../../../core/constants/app_constants.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: GradientBoxBorder(
            gradient: gradient,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12), // Reduced padding
              constraints: const BoxConstraints(
                minHeight: 120, // Fixed minimum height
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // IMPORTANT: Yeh line add karein
                children: [
                  // Icon Container - Smaller
                  Container(
                    width: 50, // Reduced from 70
                    height: 50, // Reduced from 70
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24, // Reduced from 30
                    ),
                  ),

                  const SizedBox(height: 10), // Reduced from 15

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5), // Reduced from 8

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      color: AppConstants.textColor.withOpacity(0.7),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}