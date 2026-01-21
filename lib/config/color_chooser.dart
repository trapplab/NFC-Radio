import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ColorChooser extends StatelessWidget {
  const ColorChooser({super.key});

  @override
  Widget build(BuildContext context) {    
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Theme Color',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColorButton(Colors.white, 'White', context),
            _buildColorButton(const Color(0xFFC8B6A8), 'Cappuccino', context),
            _buildColorButton(Colors.black, 'Black', context),
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