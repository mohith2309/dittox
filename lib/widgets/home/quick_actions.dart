import 'package:flutter/material.dart';
import '../../utils/color_pallets.dart';

class QuickActions extends StatelessWidget {
  final BuildContext ctx;
  final String accessToken;
  final VoidCallback onUploadTap;
  final VoidCallback onScanTap;
  final VoidCallback onOrdersTap;

  const QuickActions({
    super.key,
    required this.ctx,
    required this.accessToken,
    required this.onUploadTap,
    required this.onScanTap,
    required this.onOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionPill(
                icon: Icons.upload_file_rounded,
                label: 'Upload',
                color: const Color(0xFF6750A4),
                onTap: onUploadTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionPill(
                icon: Icons.document_scanner_rounded,
                label: 'Scan',
                color: const Color(0xFF43A047),
                onTap: onScanTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionPill(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                color: const Color(0xFFFC8019),
                onTap: onOrdersTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _isPressed ? 0.1 : 0.15),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: ColorPallets.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
