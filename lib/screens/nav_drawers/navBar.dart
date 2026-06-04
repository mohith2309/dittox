import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings.dart';
import '../../utils/color_pallets.dart';
import '../../utils/ui_sounds.dart';
import '../navBar_Screens/cart_Screen.dart';
import '../navBar_Screens/home_screen.dart';
import '../navBar_Screens/profile_Screen.dart';

class ButtonNavigationBar extends StatefulWidget {
  static const routeName = '/buttomNavBar';
  final String accessToken;
  final int initialIndex;

  const ButtonNavigationBar({
    super.key,
    required this.accessToken,
    this.initialIndex = 0,
  });

  @override
  State<ButtonNavigationBar> createState() => _ButtonNavigationBarState();
}

class _ButtonNavigationBarState extends State<ButtonNavigationBar> {
  late int _selectedIndex;
  int _ordersRefreshToken = 0;
  late String _effectiveToken;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _effectiveToken = widget.accessToken.trim();
    _screens = [
      HomeScreen(accessToken: _effectiveToken),
      CartScreen(accessToken: _effectiveToken, refreshToken: 0),
      ProfilePage(accessToken: _effectiveToken),
    ];
  }

  void _onTabTap(int index) {
    UiSounds.tabSwitch();
    setState(() {
      if (index == 1) {
        _ordersRefreshToken++;
        _screens[1] = CartScreen(
          accessToken: _effectiveToken,
          refreshToken: _ordersRefreshToken,
        );
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to settings so dark mode + potato mode trigger rebuilds.
    final settings = context.watch<AppSettings>();
    // Keep UiSounds in sync with the setting.
    UiSounds.update(settings.uiSounds);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appBody = IndexedStack(
      index: _selectedIndex,
      children: _screens,
    );
    Widget body = appBody;
    if (kIsWeb) {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth > 1180 ? 1180.0 : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: appBody,
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1415) : ColorPallets.surface,
      // extendBody lets content scroll under the floating nav bar for a
      // premium feel — each screen adds bottom padding via MediaQuery.padding.
      extendBody: true,
      body: body,
      bottomNavigationBar: _DittoxNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTap,
        potatoMode: settings.potatoMode,
        isDark: isDark,
        reduceAnimations: settings.reduceAnimations,
      ),
    );
  }
}

// ─── Custom floating glass nav bar ────────────────────────────────────────────

class _DittoxNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool potatoMode;
  final bool isDark;
  final bool reduceAnimations;

  const _DittoxNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.potatoMode,
    required this.isDark,
    required this.reduceAnimations,
  });

  static const _tabs = [
    _NavTab(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavTab(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
    _NavTab(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final animDuration = reduceAnimations
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 300);
    final animCurve = reduceAnimations ? Curves.linear : Curves.easeInOut;

    // The bar itself is a pill-shaped floating container.
    final barDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      boxShadow: potatoMode
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
    );

    Widget barContent = Row(
      children: List.generate(_tabs.length, (i) {
        final isActive = i == selectedIndex;
        return Expanded(
          child: _NavItem(
            tab: _tabs[i],
            isActive: isActive,
            isDark: isDark,
            animDuration: animDuration,
            animCurve: animCurve,
            onTap: () => onTap(i),
          ),
        );
      }),
    );

    Widget bar;
    if (potatoMode) {
      // Potato mode: flat solid bar, no blur
      bar = Container(
        height: 62,
        decoration: barDecoration.copyWith(
          color: isDark ? const Color(0xFF1A2526) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF2D3E40) : ColorPallets.cardBorder,
          ),
        ),
        child: barContent,
      );
    } else {
      // Normal mode: frosted glass pill bar
      bar = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            child: barContent,
          ),
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kIsWeb ? 720 : double.infinity,
          ),
          child: Container(
            // Floating margin — bar hovers above the screen edge.
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: barDecoration,
            child: bar,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final bool isDark;
  final Duration animDuration;
  final Curve animCurve;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.isDark,
    required this.animDuration,
    required this.animCurve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = ColorPallets.deepBlue;
    final inactiveColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: animDuration,
        curve: animCurve,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active pill around icon
            AnimatedContainer(
              duration: animDuration,
              curve: animCurve,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? ColorPallets.deepBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: animDuration,
                child: Icon(
                  isActive ? tab.activeIcon : tab.inactiveIcon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            AnimatedDefaultTextStyle(
              duration: animDuration,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: isActive ? 0.3 : 0,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _NavTab {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavTab(this.activeIcon, this.inactiveIcon, this.label);
}
