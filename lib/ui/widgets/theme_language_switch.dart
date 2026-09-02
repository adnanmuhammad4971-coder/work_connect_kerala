import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class ThemeLanguageControls extends StatelessWidget {
  final bool showLabels;
  final bool isDarkBackground;

  const ThemeLanguageControls({
    super.key,
    this.showLabels = false,
    this.isDarkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Toggle (ML / EN)
        InkWell(
          onTap: () => appState.toggleLanguage(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.12)
                  : (appState.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkBackground
                    ? Colors.white.withValues(alpha: 0.2)
                    : (appState.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: isDarkBackground ? const Color(0xFFFBBF24) : (appState.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF0F4C81)),
                ),
                const SizedBox(width: 4),
                Text(
                  appState.isMalayalam ? 'മല' : 'EN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDarkBackground ? Colors.white : (appState.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Dark / Light Mode Toggle
        InkWell(
          onTap: () => appState.toggleTheme(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.12)
                  : (appState.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkBackground
                    ? Colors.white.withValues(alpha: 0.2)
                    : (appState.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 14,
                  color: appState.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 4),
                  Text(
                    appState.isDarkMode ? 'Dark' : 'Light',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDarkBackground ? Colors.white : (appState.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
