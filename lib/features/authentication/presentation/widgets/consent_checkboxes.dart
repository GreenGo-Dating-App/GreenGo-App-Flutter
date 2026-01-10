import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';

/// Consent checkboxes widget for registration
/// Includes Privacy Policy, Terms, Profiling, and Third-party data sharing
class ConsentCheckboxes extends StatelessWidget {
  final bool privacyPolicyAccepted;
  final bool termsAccepted;
  final bool profilingAccepted;
  final bool thirdPartyDataAccepted;
  final ValueChanged<bool> onPrivacyPolicyChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onProfilingChanged;
  final ValueChanged<bool> onThirdPartyDataChanged;
  final bool enabled;

  const ConsentCheckboxes({
    super.key,
    required this.privacyPolicyAccepted,
    required this.termsAccepted,
    required this.profilingAccepted,
    required this.thirdPartyDataAccepted,
    required this.onPrivacyPolicyChanged,
    required this.onTermsChanged,
    required this.onProfilingChanged,
    required this.onThirdPartyDataChanged,
    this.enabled = true,
  });

  /// Check if all required consents are accepted
  static bool areRequiredConsentsAccepted({
    required bool privacyPolicy,
    required bool terms,
  }) {
    return privacyPolicy && terms;
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _openTermsAndConditions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsAndConditionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          l10n.consentRequired,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Privacy Policy checkbox (required)
        _buildConsentItem(
          context: context,
          value: privacyPolicyAccepted,
          onChanged: enabled ? (value) => onPrivacyPolicyChanged(value ?? false) : null,
          title: l10n.acceptPrivacyPolicy,
          isRequired: true,
          onLinkTap: () => _openPrivacyPolicy(context),
          linkText: l10n.readPrivacyPolicy,
        ),

        const SizedBox(height: 8),

        // Terms and Conditions checkbox (required)
        _buildConsentItem(
          context: context,
          value: termsAccepted,
          onChanged: enabled ? (value) => onTermsChanged(value ?? false) : null,
          title: l10n.acceptTermsAndConditions,
          isRequired: true,
          onLinkTap: () => _openTermsAndConditions(context),
          linkText: l10n.readTermsAndConditions,
        ),

        const SizedBox(height: 16),

        // Optional consents section
        Text(
          l10n.optionalConsents,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Profiling checkbox (optional)
        _buildConsentItem(
          context: context,
          value: profilingAccepted,
          onChanged: enabled ? (value) => onProfilingChanged(value ?? false) : null,
          title: l10n.acceptProfiling,
          isRequired: false,
          subtitle: l10n.profilingDescription,
        ),

        const SizedBox(height: 8),

        // Third-party data sharing checkbox (optional)
        _buildConsentItem(
          context: context,
          value: thirdPartyDataAccepted,
          onChanged: enabled ? (value) => onThirdPartyDataChanged(value ?? false) : null,
          title: l10n.acceptThirdPartyData,
          isRequired: false,
          subtitle: l10n.thirdPartyDataDescription,
        ),
      ],
    );
  }

  Widget _buildConsentItem({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String title,
    required bool isRequired,
    String? subtitle,
    VoidCallback? onLinkTap,
    String? linkText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRequired && !value
              ? AppColors.errorRed.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.richGold,
                checkColor: AppColors.deepBlack,
                side: BorderSide(
                  color: isRequired && !value
                      ? AppColors.errorRed
                      : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isRequired)
                            const Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (onLinkTap != null && linkText != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onLinkTap,
                          child: Text(
                            linkText,
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
