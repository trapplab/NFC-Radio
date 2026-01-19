import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'dimmed_mode_service.dart';
import 'settings_provider.dart';

class DimmedModeWrapper extends StatefulWidget {
  final Widget child;
  
  const DimmedModeWrapper({required this.child, super.key});
  
  @override
  State<DimmedModeWrapper> createState() => _DimmedModeWrapperState();
}

class _DimmedModeWrapperState extends State<DimmedModeWrapper> {
  double _sliderValue = 0.0;
  OverlayEntry? _overlayEntry;
  double? _originalBrightness;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dimmedModeService = Provider.of<DimmedModeService>(context, listen: false);
      dimmedModeService.addListener(_onDimmedModeChanged);
      
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.addListener(_onSettingsChanged);
      
      if (settings.useSystemOverlay) {
        _requestPermission();
      }

      // Check initial state
      if (dimmedModeService.isDimmed) {
        _onDimmedModeChanged();
      }
    });
  }
  
  Future<void> _requestPermission() async {
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.useSystemOverlay) {
      _requestPermission();
    }
    // If dimmed mode is active, we might need to switch overlay type
    _onDimmedModeChanged();
    
    // Rebuild to show/hide slider or app-wide overlay
    setState(() {});
  }
  
  @override
  void dispose() {
    final dimmedModeService = Provider.of<DimmedModeService>(context, listen: false);
    dimmedModeService.removeListener(_onDimmedModeChanged);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.removeListener(_onSettingsChanged);
    _removeOverlay();
    super.dispose();
  }
  
  void _onDimmedModeChanged() {
    if (!mounted) return;
    final dimmedModeService = Provider.of<DimmedModeService>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    debugPrint('DimmedModeWrapper: _onDimmedModeChanged - isDimmed: ${dimmedModeService.isDimmed}, useSystemOverlay: ${settings.useSystemOverlay}');

    if (dimmedModeService.isDimmed) {
      // Save current brightness and dim screen
      ScreenBrightness().current.then((brightness) {
        _originalBrightness = brightness;
        ScreenBrightness().setScreenBrightness(0.0);
      });

      if (settings.useSystemOverlay) {
        _showOverlay();
        // Start kiosk mode if system overlay is enabled
        getKioskMode().then((state) {
          if (state == KioskMode.disabled) {
            startKioskMode();
          }
        });
      } else {
        _removeOverlay();
      }
    } else {
      // Restore screen brightness
      if (_originalBrightness != null) {
        ScreenBrightness().setScreenBrightness(_originalBrightness!).then((_) {
          // Reset to system control after a short delay to ensure the set value is applied
          Future.delayed(const Duration(milliseconds: 500), () {
            ScreenBrightness().resetScreenBrightness();
          });
        });
      } else {
        ScreenBrightness().resetScreenBrightness();
      }

      _removeOverlay();
      // Stop kiosk mode when deactivating
      getKioskMode().then((state) {
        if (state == KioskMode.enabled) {
          stopKioskMode();
        }
      });
    }
    
    // Rebuild to show/hide app-wide overlay or slider
    setState(() {});
  }
  
  void _showOverlay() {
    if (!mounted) return;
    debugPrint('DimmedModeWrapper: _showOverlay called');
    if (_overlayEntry == null) {
      debugPrint('DimmedModeWrapper: Creating new OverlayEntry');
      _overlayEntry = OverlayEntry(
        builder: (overlayContext) => BlockOverlay(
          swipeThreshold: -350, // Set the 3-finger slide length here (negative for upward)
          onUnlock: () {
            debugPrint('DimmedModeWrapper: Overlay unlock triggered');
            if (!mounted) return;
            final dimmedModeService = Provider.of<DimmedModeService>(context, listen: false);
            dimmedModeService.disableDimmedMode();
          },
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      debugPrint('DimmedModeWrapper: OverlayEntry already exists');
    }
  }
  
  void _removeOverlay() {
    debugPrint('DimmedModeWrapper: _removeOverlay called');
    if (_overlayEntry != null) {
      debugPrint('DimmedModeWrapper: Removing OverlayEntry');
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dimmedModeService = Provider.of<DimmedModeService>(context);
    final settings = Provider.of<SettingsProvider>(context);
    
    return Material(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Main content
                widget.child,
                
                // App-wide overlay (used when system overlay is disabled)
                if (dimmedModeService.isDimmed && !settings.useSystemOverlay)
                  BlockOverlay(
                    swipeThreshold: -350, // Set the 3-finger slide length here (negative for upward)
                    onUnlock: () => dimmedModeService.disableDimmedMode(),
                  ),
              ],
            ),
          ),
          
          // Always visible lock slider at bottom (Footer)
          if (!dimmedModeService.isDimmed)
            Container(
              padding: EdgeInsets.fromLTRB(40, 10, 40, 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Shimmering text effect (simplified)
                    Center(
                      child: Text(
                        'Slide to Lock',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.3),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    
                    // The actual slider
                    Positioned.fill(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          sliderTheme: SliderThemeData(
                            trackHeight: 60,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.transparent, // Hide default thumb
                            overlayColor: Colors.transparent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 26,
                              elevation: 0,
                            ),
                          ),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Slider(
                            value: _sliderValue,
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                              if (value >= 0.9) {
                                dimmedModeService.enableDimmedMode();
                                setState(() {
                                  _sliderValue = 0.0;
                                });
                              }
                            },
                            onChangeEnd: (value) {
                              if (value < 0.9) {
                                setState(() {
                                  _sliderValue = 0.0;
                                });
                              }
                            },
                            min: 0.0,
                            max: 1.0,
                          ),
                        ),
                      ),
                    ),
                    
                    // Arrow icon on the thumb
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double thumbSize = 52;
                        final double availableWidth = constraints.maxWidth - thumbSize - 8;
                        return Positioned(
                          left: 4 + (_sliderValue * availableWidth),
                          top: 4,
                          child: IgnorePointer(
                            child: Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BlockOverlay extends StatefulWidget {
  final VoidCallback onUnlock;
  final double swipeThreshold;
  
  const BlockOverlay({
    required this.onUnlock, 
    this.swipeThreshold = -350, 
    super.key,
  });
  
  @override
  State<BlockOverlay> createState() => _BlockOverlayState();
}

class _BlockOverlayState extends State<BlockOverlay> {
  int _touchCount = 0;
  Offset? _initialPosition;
  bool _isTrackingSwipe = false;
  
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            // Center instruction
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Screen Locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3-Finger Swipe Up to Unlock',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            // Listener for three-finger swipe
            Positioned.fill(
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
                    if (deltaY < widget.swipeThreshold) {
                      widget.onUnlock();
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
            ),
          ],
        ),
      ),
    );
  }
  
  void _resetTracking() {
    _touchCount = 0;
    _initialPosition = null;
    _isTrackingSwipe = false;
  }
}
