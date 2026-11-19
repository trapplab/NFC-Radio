import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'settings_section_header.dart';
import 'theme_provider.dart';

class ColorChooser extends StatelessWidget {
  const ColorChooser({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.themeColor),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorButton(Colors.white, l10n.white, context),
              _buildColorButton(
                const Color(0xFFC8B6A8),
                l10n.cappuccino,
                context,
              ),
              _buildColorButton(Colors.black, l10n.black, context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color, String label, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final scheme = Theme.of(context).colorScheme;
    final bool isSelected =
        themeProvider.currentColor.toARGB32() == color.toARGB32();
    final Color checkColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => themeProvider.setColor(color),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected ? Icon(Icons.check, color: checkColor) : null,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
