import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dimmed_mode_service.dart';
import 'dimmed_overlay.dart';

class DimmedModeWrapper extends StatefulWidget {
  final Widget child;
  
  const DimmedModeWrapper({required this.child, super.key});
  
  @override
  State<DimmedModeWrapper> createState() => _DimmedModeWrapperState();
}

class _DimmedModeWrapperState extends State<DimmedModeWrapper> {
  int _touchCount = 0;
  Offset? _initialPosition;
  bool _isTrackingSwipe = false;
  
  @override
  Widget build(BuildContext context) {
    final dimmedModeService = Provider.of<DimmedModeService>(context);
    
    return Stack(
      children: [
        // Main content with gesture detection
        _buildGestureDetector(dimmedModeService, widget.child),
        
        // Dimmed overlay
        DimmedOverlay(isActive: dimmedModeService.isDimmed),
        
        // When dimmed, add a special overlay that allows three-finger gestures but blocks others
        if (dimmedModeService.isDimmed)
          _buildDimmedTouchHandler(dimmedModeService),
      ],
    );
  }
  
  Widget _buildGestureDetector(DimmedModeService dimmedModeService, Widget child) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (dimmedModeService.isDimmed) return;
        
        _touchCount++;
        if (_touchCount == 3) {
          _initialPosition = event.position;
          _isTrackingSwipe = true;
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        if (!dimmedModeService.isDimmed && _isTrackingSwipe && _initialPosition != null) {
          final deltaY = event.position.dy - _initialPosition!.dy;
          
          // Three-finger swipe down to enable dimmed mode
          if (deltaY > 100) {
            dimmedModeService.enableDimmedMode();
            _resetTracking();
          }
        }
      },
      onPointerUp: (PointerUpEvent event) {
        if (_touchCount > 0) {
          _touchCount--;
          if (_touchCount == 0) {
            _resetTracking();
          }
        }
      },
      onPointerCancel: (PointerCancelEvent event) {
        _resetTracking();
      },
      child: child,
    );
  }
  
  Widget _buildDimmedTouchHandler(DimmedModeService dimmedModeService) {
    return Positioned.fill(
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          _touchCount++;
          if (_touchCount == 3) {
            _initialPosition = event.position;
            _isTrackingSwipe = true;
          }
        },
        onPointerMove: (PointerMoveEvent event) {
          if (_isTrackingSwipe && _initialPosition != null) {
            final deltaY = event.position.dy - _initialPosition!.dy;
            
            // Three-finger swipe up to disable dimmed mode
            if (deltaY < -250) {
              dimmedModeService.disableDimmedMode();
              _resetTracking();
            }
          }
        },
        onPointerUp: (PointerUpEvent event) {
          if (_touchCount > 0) {
            _touchCount--;
            if (_touchCount == 0) {
              _resetTracking();
            }
          }
        },
        onPointerCancel: (PointerCancelEvent event) {
          _resetTracking();
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent),
      ),
    );
  }
  
  void _resetTracking() {
    _touchCount = 0;
    _initialPosition = null;
    _isTrackingSwipe = false;
  }
}