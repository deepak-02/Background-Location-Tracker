import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TrackingControls extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const TrackingControls({
    super.key,
    required this.isTracking,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientButton(
            onPressed: isTracking ? null : onStart,
            gradient: AppColors.primaryGradient,
            icon: Icons.play_arrow_rounded,
            label: 'START',
            disabled: isTracking,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _GradientButton(
            onPressed: isTracking ? onStop : null,
            gradient: AppColors.dangerGradient,
            icon: Icons.stop_rounded,
            label: 'STOP',
            disabled: !isTracking,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final IconData icon;
  final String label;
  final bool disabled;

  const _GradientButton({
    required this.onPressed,
    required this.gradient,
    required this.icon,
    required this.label,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.35 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}