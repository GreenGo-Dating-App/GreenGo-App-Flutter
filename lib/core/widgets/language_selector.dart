import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {

  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.iconColor,
    this.textColor,
  });
  final bool showLabel;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return PopupMenuButton<Locale>(
          // `child:` rather than `icon:` — an IconButton clamps its icon slot
          // to iconSize, so the icon + label Row overflowed it by ~91px.
          tooltip: languageProvider.currentLanguageName,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  color: iconColor ?? AppColors.richGold,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      languageProvider.currentLanguageName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor ?? AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
