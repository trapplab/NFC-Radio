import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'theme_provider.dart';

class ColorChooser extends StatelessWidget {
  const ColorChooser({super.key});

  @override
  Widget build(BuildContext context) {    
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.themeColor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColorButton(Colors.white, l10n.white, context),
            _buildColorButton(const Color(0xFFC8B6A8), l10n.cappuccino, context),
            _buildColorButton(Colors.black, l10n.black, context),
          ],
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color, String label, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        GestureDetector(
          onTap: () => themeProvider.setColor(color),
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: themeProvider.currentColor == color
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
          ),
        ),
        Text(label),
      ],
    );
  }
}