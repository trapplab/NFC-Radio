import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DimmedOverlay extends StatefulWidget {
  final bool isActive;
  final double opacity;
  final VoidCallback onLockScreen;
  
  const DimmedOverlay({
    required this.isActive,
    this.opacity = 0.9,
    required this.onLockScreen,
    super.key,
  });
  
  @override
  State<DimmedOverlay> createState() => _DimmedOverlayState();
}

class _DimmedOverlayState extends State<DimmedOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from top (off-screen)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    // Start animation when overlay becomes active
    if (widget.isActive) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(DimmedOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!oldWidget.isActive && widget.isActive) {
      // Overlay just became active - start animation
      _animationController.reset();
      _animationController.forward();
    } else if (oldWidget.isActive && !widget.isActive) {
      // Overlay just became inactive - reverse animation
      _animationController.reverse();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return Container();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.black.withAlpha((widget.opacity * 255).toInt()),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.screenLocked,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.swipeUpToUnlock,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),
                Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}