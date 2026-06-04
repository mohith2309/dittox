import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../model/notification_item.dart';
import '../../providers/app_notifications.dart';

class SamsungNotificationStack extends StatefulWidget {
  final VoidCallback? onTap;
  final bool topRight;

  const SamsungNotificationStack(
      {super.key, this.onTap, this.topRight = false});

  @override
  State<SamsungNotificationStack> createState() =>
      _SamsungNotificationStackState();
}

class _SamsungNotificationStackState extends State<SamsungNotificationStack> {
  String? _latestTopId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotifications>(
      builder: (context, notifs, child) {
        final visible = notifs.visible;

        if (visible.isEmpty) {
          _latestTopId = null;
          return const SizedBox.shrink();
        }

        final currentTopId = visible.first.id;
        final isNewNotification =
            _latestTopId != null && _latestTopId != currentTopId;
        _latestTopId = currentTopId;

        final media = MediaQuery.of(context);
        return Positioned(
          top: widget.topRight ? media.padding.top + 18 : null,
          right: widget.topRight ? 24 : 16,
          bottom: widget.topRight ? null : media.padding.bottom + 84,
          left: widget.topRight ? null : 16,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.topRight ? 360 : double.infinity,
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: Column(
              crossAxisAlignment: widget.topRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: visible
                  .take(widget.topRight ? 3 : 1)
                  .map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SamsungOneUINotification(
                          key: ValueKey(n.id),
                          notification: n,
                          shouldVibrate: isNewNotification,
                          onDismiss: () => notifs.dismiss(n.id),
                          onTap: () {
                            notifs.markAsRead(n.id);
                            widget.onTap?.call();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class SamsungOneUINotification extends StatefulWidget {
  final AppNotification notification;
  final bool shouldVibrate;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const SamsungOneUINotification({
    super.key,
    required this.notification,
    required this.shouldVibrate,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<SamsungOneUINotification> createState() =>
      _SamsungOneUINotificationState();
}

class _SamsungOneUINotificationState extends State<SamsungOneUINotification>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shakeController;

  late Animation<double> _widthAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _iconShift;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _closeOpacity;
  late Animation<double> _shakeAnim;

  final double _height = 72;
  final double _collapsedWidth = 60;
  final double _expandedWidth = 320;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    _widthAnim = Tween<double>(
      begin: _collapsedWidth,
      end: _expandedWidth,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
    ));

    _iconShift = Tween<double>(begin: 0, end: -24).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _closeOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    if (widget.notification.autoDismissMs > 0) {
      final visibleFor = widget.notification.autoDismissMs < 8000
          ? 8000
          : widget.notification.autoDismissMs;
      Future.delayed(Duration(milliseconds: visibleFor), () {
        if (mounted) _dismiss();
      });
    }

    if (widget.shouldVibrate) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _shakeController.forward().then((_) => _shakeController.reverse());
          HapticFeedback.mediumImpact();
        }
      });
    }
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _shakeController]),
      builder: (context, child) {
        final shakeOffset = _shakeAnim.value * 5 * (1 - _shakeAnim.value);
        final bool isCollapsed = _controller.value < 0.45;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
            },
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: _widthAnim.value,
                    height: _height,
                    decoration: BoxDecoration(
                      color: _getBackgroundColor().withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _getAccentColor().withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: isCollapsed
                          ? Center(
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _getAccentColor()
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getIcon(),
                                      color: _getAccentColor(),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset(_iconShift.value * 0.18, 0),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _getAccentColor()
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _getIcon(),
                                          color: _getAccentColor(),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _textOpacity,
                                    child: SlideTransition(
                                      position: _textSlide,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.notification.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: _getTextColor(),
                                              decoration: TextDecoration.none,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.notification.body,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getTextColor()
                                                  .withValues(alpha: 0.68),
                                              decoration: TextDecoration.none,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FadeTransition(
                                  opacity: _closeOpacity,
                                  child: GestureDetector(
                                    onTap: _dismiss,
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() => Colors.white;
  Color _getAccentColor() {
    switch (widget.notification.type) {
      case 'orderUpdate':
        return const Color(0xFF6750A4);
      case 'storeAlert':
        return const Color(0xFFE53935);
      case 'offer':
        return const Color(0xFF43A047);
      case 'error':
        return const Color(0xFFD32F2F);
      case 'info':
        return const Color(0xFF1976D2);
      case 'success':
        return const Color(0xFF388E3C);
      case 'warning':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF6750A4);
    }
  }

  Color _getTextColor() => const Color(0xFF1C1B1F);

  IconData _getIcon() {
    switch (widget.notification.type) {
      case 'orderUpdate':
        return Icons.local_shipping_rounded;
      case 'storeAlert':
        return Icons.error_outline_rounded;
      case 'offer':
        return Icons.celebration_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
