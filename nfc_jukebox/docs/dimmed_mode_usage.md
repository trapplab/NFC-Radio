# Screen Dimmed Mode - User Guide

## Overview
The Screen Dimmed Mode feature allows you to dim the screen and disable touch input while keeping the app active for NFC scanning. This is perfect for situations where you want children to be able to play with NFC tags without accidentally changing settings or accessing other parts of the app.

## Visual Indicators & Animations

### Activation Animation (Swipe Down)
When you activate dimmed mode with a three-finger swipe down:
- **Smooth Slide Down**: The dimmed overlay animates from the top of the screen downwards
- **Fade In Effect**: The overlay gradually becomes visible with a smooth fade-in
- **Duration**: 400ms animation with ease-out curve for natural movement
- **Visual Feedback**: Creates the impression of "pulling down" a shade over the screen

### Deactivation Animation (Swipe Up)
When you deactivate dimmed mode with a three-finger swipe up:
- **Smooth Slide Up**: The dimmed overlay animates upwards and disappears
- **Fade Out Effect**: The overlay gradually becomes transparent with a smooth fade-out
- **Duration**: 400ms animation with ease-in curve for natural movement
- **Visual Feedback**: Creates the impression of "lifting up" the shade to reveal the screen

### When Dimmed Mode is Active:
- **Screen Overlay**: A semi-transparent black overlay covers the entire screen
- **Status Message**: "Screen Dimmed" text appears in the center
- **Instruction**: "3-Finger Swipe Up to Unlock" text appears below the status
- **Lock Icon**: A lock icon is displayed to indicate the locked state
- **Touch Blocking**: All touch interactions are blocked (you'll see no response when touching the screen)

### When Dimmed Mode is Inactive:
- The screen appears normal with full brightness
- All touch interactions work as usual
- NFC scanning continues to work in the background

## How to Activate/Deactivate

### Activating Dimmed Mode
1. **Three-Finger Swipe Down**: Place three fingers on the screen and swipe downwards together
2. The screen will dim with a smooth animation from the top
3. A message will appear: "Screen Dimmed - 3-Finger Swipe Up to Unlock"
4. All touch input will be blocked except for NFC scanning

### Deactivating Dimmed Mode
1. **Three-Finger Swipe Up**: Place three fingers on the screen and swipe upwards together
2. The screen will return to normal brightness with a smooth slide-up animation
3. Full touch functionality will be restored

## Technical Details

### Multi-Touch Implementation
- Uses Flutter's `Listener` widget with pointer event tracking
- **Dual-Layer Detection**: Separate gesture detection for normal and dimmed modes
- **Normal Mode**: Three-finger swipe down to enable dimmed mode
- **Dimmed Mode**: Three-finger swipe up to disable dimmed mode
- Tracks finger count and initial positions independently for each layer
- Resets tracking when fingers are lifted or gesture is completed
- Works reliably across different screen sizes and orientations

### Animation Implementation
- **SlideTransition**: Creates the vertical movement effect
- **FadeTransition**: Creates the smooth fade-in/fade-out effect
- **CurvedAnimation**: Uses ease-out for activation, ease-in for deactivation
- **AnimationController**: Manages the 400ms duration for smooth transitions
- **State Management**: Automatically triggers animations when dimmed state changes

### Touch Blocking Behavior
- **Normal Mode**: All touch events work normally
- **Dimmed Mode**: Single-touch events are effectively blocked by the overlay
- **Unlock Gesture**: Three-finger swipe up works even when screen is dimmed
- **NFC Scanning**: Continues to work in both modes (not affected by touch blocking)

## Use Cases

### 1. Child-Friendly Mode
- Perfect for letting children play with NFC tags without worrying about them changing settings
- Prevents accidental app navigation or configuration changes
- Animated transitions make it visually appealing for kids

### 2. Public Demonstrations
- Great for trade shows or public displays where you want to prevent unauthorized access
- Allows visitors to experience the NFC functionality without accessing the full UI
- Professional animations enhance the user experience

### 3. Kiosk Mode
- Ideal for interactive kiosks where you want to limit user interaction
- Maintains the core NFC functionality while protecting the app configuration
- Smooth animations provide clear visual feedback

## Best Practices

1. **Test the Gesture**: Try the three-finger swipe a few times to get comfortable with it
2. **Use All Three Fingers**: Make sure all three fingers touch the screen simultaneously
3. **Clear Movement**: Swipe with a deliberate motion (at least 50 pixels) for reliable detection
4. **Enjoy the Animation**: Watch for the smooth slide-down and slide-up transitions
5. **NFC Monitoring**: Keep an eye on the NFC status indicator to ensure scanning is working

## Troubleshooting

### Gesture Not Working
- **Issue**: Three-finger swipe doesn't trigger dimmed mode
- **Solution**: Make sure all three fingers touch the screen at the same time
- **Solution**: Swipe with a bit more distance (at least 50 pixels vertically)
- **Solution**: Try on a flat surface for better finger contact

### Animation Not Smooth
- **Issue**: Animation appears choppy or doesn't play
- **Solution**: This could indicate performance issues - try closing other apps
- **Solution**: Check that your device supports Flutter animations properly
- **Solution**: Restart the app if animations stop working

### NFC Not Working in Dimmed Mode
- **Issue**: NFC tags aren't detected when screen is dimmed
- **Solution**: This shouldn't happen - NFC scanning is independent of the UI
- **Solution**: Check that NFC is enabled on your device
- **Solution**: Restart the app if the issue persists

## Advanced Usage

### Programmatic Control
If you need to control dimmed mode programmatically (for testing or advanced scenarios), you can access the `DimmedModeService`:

```dart
// Get the service from the provider
final dimmedModeService = Provider.of<DimmedModeService>(context, listen: false);

// Enable dimmed mode (with animation)
dimmedModeService.enableDimmedMode();

// Disable dimmed mode (with animation)
dimmedModeService.disableDimmedMode();

// Toggle dimmed mode (with animation)
dimmedModeService.toggleDimmedMode();

// Check current state
bool isDimmed = dimmedModeService.isDimmed;
```

### Customization
The dimmed mode can be customized by modifying the `DimmedOverlay` widget:
- **Opacity**: Change the `opacity` parameter (default: 0.7)
- **Content**: Modify the text and icons displayed
- **Colors**: Change the text and icon colors
- **Animation Duration**: Adjust the animation controller duration
- **Animation Curves**: Modify the ease-in/ease-out curves

## Future Enhancements

This feature could be enhanced in future versions with:
- **Custom Animations**: Allow users to choose different transition effects
- **Sound Effects**: Add subtle sounds for activation/deactivation
- **Haptic Feedback**: Add vibration feedback for gesture confirmation
- **Timeout**: Automatic deactivation after a period of inactivity
- **Pin Code**: Optional PIN code protection for unlocking
- **Theme Support**: Different animation styles for light/dark themes