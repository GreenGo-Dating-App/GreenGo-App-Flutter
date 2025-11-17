import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../constants/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  final Color? textColor;

  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return PopupMenuButton<Locale>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: iconColor ?? AppColors.richGold,
              ),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  languageProvider.currentLanguageName,
                  style: TextStyle(
                    color: textColor ?? AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          color: AppColors.backgroundCard,
          itemBuilder: (context) {
            return LanguageProvider.supportedLocales.map((locale) {
              final languageName = languageProvider.getLanguageName(locale);
              final isSelected = languageProvider.currentLocale == locale;

              return PopupMenuItem<Locale>(
                value: locale,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: AppColors.richGold,
                        size: 20,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 12),
                    Text(
                      languageName,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.richGold
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (locale) async {
            await languageProvider.setLocale(locale);
          },
        );
      },
    );
  }
}
