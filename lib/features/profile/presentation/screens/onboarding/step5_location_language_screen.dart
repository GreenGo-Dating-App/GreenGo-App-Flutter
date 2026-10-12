import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/web_location_fallback.dart';
import '../../../../../core/widgets/connection_error_dialog.dart';
import '../../../../../generated/app_localizations.dart';
import 'onboarding_value_labels.dart';
import '../../../data/models/profile_model.dart' show normalizeCountryName;
import '../../../domain/entities/location.dart' as location_entity;
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step5LocationLanguageScreen extends StatefulWidget {
  const Step5LocationLanguageScreen({super.key});

  @override
  State<Step5LocationLanguageScreen> createState() =>
      _Step5LocationLanguageScreenState();
}

class _Step5LocationLanguageScreenState
    extends State<Step5LocationLanguageScreen> {
  final List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Portuguese (Brazil)',
    'Russian',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Polish',
    'Turkish',
    'Greek',
  ];

  /// The stored value stays English (it is what matching/search compares on);
  /// only the chip label follows the user's selected app language.
  String _localizedLanguage(BuildContext context, String language) {
    final l10n = AppLocalizations.of(context);
    return l10n == null ? language : localizedOnboardingLanguage(l10n, language);
  }

  List<String> _selectedLanguages = [];
  location_entity.Location? _selectedLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  /// True while the automatic detection on opening the step runs: a failure
  /// then only shows the inline error, never a dialog the user did not ask for.
  bool _silentErrors = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _selectedLanguages = List.from(state.languages);
      _selectedLocation = state.location;
    }
    // Web: detect the location as soon as the step opens (the button stays
    // for a retry).
    if (kIsWeb && _selectedLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetect());
    }
  }

  Future<void> _autoDetect() async {
    if (!mounted || _isLoadingLocation || _selectedLocation != null) return;
    _silentErrors = true;
    try {
      await _getCurrentLocation();
    } finally {
      _silentErrors = false;
    }
  }

  Future<void> _getCurrentLocation() async {
    // Resolved before the first await so the localized copy below never reads
    // the BuildContext across an async gap.
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    if (kIsWeb) return _getWebLocation(l10n);

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
          l10n?.locationServicesDisabled ?? 'Location Services Disabled',
          l10n?.locationServicesDisabledMessage ?? 'Please enable location services in your device settings to use this feature.',
        );
        return;
      }

      // Check location permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError(
            l10n?.locationPermissionDenied ?? 'Permission Denied',
            l10n?.locationPermissionDeniedMessage ?? 'Location permission is required to detect your current location. Please grant permission to continue.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          l10n?.locationPermissionPermanentlyDenied ?? 'Permission Permanently Denied',
          l10n?.locationPermissionPermanentlyDeniedMessage ?? 'Location permission has been permanently denied. Please enable it in your device settings to use this feature.',
        );
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality
            ?? placemark.subLocality
            ?? placemark.subAdministrativeArea
            ?? placemark.administrativeArea
            ?? placemark.name
            ?? '';
        final country = normalizeCountryName(placemark.country ?? '');
        final displayAddress = city.isNotEmpty ? '$city, $country' : country;

        setState(() {
          _selectedLocation = location_entity.Location(
            latitude: position.latitude,
            longitude: position.longitude,
            city: city,
            country: country,
            displayAddress: displayAddress,
          );
          _isLoadingLocation = false;
        });
      } else {
        _showLocationError(
          l10n?.locationNotFound ?? 'Location Not Found',
          l10n?.locationNotFoundMessage ?? 'We could not determine your address. Please try again or set your location manually later.',
        );
      }
    } on PlatformException catch (e) {
      // Handle platform-specific errors gracefully
      String message;
      if (e.code == 'PERMISSION_DENIED') {
        message = l10n?.locationErrorPermissionDenied ?? 'Location permission was denied. Please grant permission in settings.';
      } else if (e.code == 'LOCATION_SERVICE_DISABLED') {
        message = l10n?.locationErrorServicesDisabled ?? 'Location services are disabled. Please enable them in settings.';
      } else {
        message = l10n?.locationErrorUnableToGet ?? 'Unable to get your location. Please check your device settings or try again later.';
      }
      _showLocationError(l10n?.locationError ?? 'Location Error', message);
    } on TimeoutException {
      _showLocationError(
        l10n?.locationRequestTimeout ?? 'Request Timeout',
        l10n?.locationRequestTimeoutMessage ?? 'Getting your location took too long. Please check your connection and try again.',
      );
    } catch (e) {
      // Handle any other errors gracefully
      final errorMessage = e.toString().toLowerCase();
      String userMessage;

      if (errorMessage.contains('network') || errorMessage.contains('internet') || errorMessage.contains('connection')) {
        userMessage = l10n?.locationErrorCheckInternet ?? 'Please check your internet connection and try again.';
      } else if (errorMessage.contains('permission')) {
        userMessage = l10n?.locationErrorPermissionRequired ?? 'Location permission is required. Please grant permission in settings.';
      } else if (errorMessage.contains('service') || errorMessage.contains('disabled')) {
        userMessage = l10n?.locationErrorServicesDisabled ?? 'Location services are disabled. Please enable them in settings.';
      } else if (errorMessage.contains('timeout')) {
        userMessage = l10n?.locationErrorTookTooLong ?? 'Getting your location took too long. Please try again.';
      } else {
        userMessage = l10n?.locationUnavailable ?? 'Unable to get your location at the moment. You can set it manually later in settings.';
      }

      _showLocationError(l10n?.locationUnavailableTitle ?? 'Location Unavailable', userMessage);
    }
  }

  /// Web: the `geocoding` plugin has no web implementation
  /// (`placemarkFromCoordinates` always throws there), so the browser position
  /// is turned into a city through the server (`reverseGeocodeCoarse`). When
  /// the browser gives no position (denied, timeout) or the lookup fails, the
  /// approximate IP location fills the gap; the user can correct it later.
  Future<void> _getWebLocation(AppLocalizations? l10n) async {
    Position? position;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 20));
      }
    } catch (e) {
      debugPrint('[Onboarding] browser location unavailable: $e');
    }

    location_entity.Location? location;
    if (position != null) {
      location = await WebLocationFallback.reverseGeocode(
          position.latitude, position.longitude);
    }
    if (location == null) {
      final approx = await WebLocationFallback.fromIpAddress();
      if (approx != null) {
        location = position == null
            ? approx
            : location_entity.Location(
                latitude: position.latitude,
                longitude: position.longitude,
                city: approx.city,
                country: approx.country,
                displayAddress: approx.displayAddress,
              );
      }
    }
    if (!mounted) return;
    if (location == null) {
      _showLocationError(
        l10n?.locationUnavailableTitle ?? 'Location Unavailable',
        l10n?.locationUnavailable ??
            'Unable to get your location at the moment. You can set it manually later in settings.',
      );
      return;
    }
    setState(() {
      _selectedLocation = location;
      _isLoadingLocation = false;
    });
  }

  void _showLocationError(String title, String message) {
    setState(() {
      _isLoadingLocation = false;
      _locationError = message;
    });

    // Show a graceful dialog
    if (mounted && !_silentErrors) {
      ConnectionErrorDialog.showError(
        context,
        title: title,
        message: message,
        icon: Icons.location_off,
        onRetry: _getCurrentLocation,
      );
    }
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        if (_selectedLanguages.length < 3) {
          _selectedLanguages.add(language);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.onboardingMaxLanguages ?? 'You can select up to 3 languages'),
              backgroundColor: AppColors.warningAmber,
            ),
          );
        }
      }
    });
  }

  void _handleContinue() {
    // Both location AND language are required.
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.onboardingMinLocation ??
              'Please set your location to continue'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.onboardingMinLanguage ?? 'Please select at least one language'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(
          OnboardingLocationUpdated(
            location: _selectedLocation!,
            languages: _selectedLanguages,
          ),
        );

    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    if (_selectedLocation != null && _selectedLanguages.isNotEmpty) {
      context.read<OnboardingBloc>().add(
            OnboardingLocationUpdated(
              location: _selectedLocation!,
              languages: _selectedLanguages,
            ),
          );
    }
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return LuxuryOnboardingLayout(
          title: AppLocalizations.of(context)?.onboardingWhereAreYou ?? 'Where are you?',
          subtitle: AppLocalizations.of(context)?.onboardingWhereAreYouSubtitle ?? 'Set your preferred languages and your location',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          bottomChild: LuxuryButton(
            text: AppLocalizations.of(context)?.onboardingContinue ?? 'Continue',
            onPressed: _handleContinue,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Section (mandatory)
                    Text(
                      AppLocalizations.of(context)?.onboardingLocation ?? 'Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedLocation != null
                              ? AppColors.richGold.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _selectedLocation != null
                                ? AppColors.richGold
                                : Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedLocation?.displayAddress ??
                                  (AppLocalizations.of(context)?.onboardingNoLocationSelected ?? 'No location selected'),
                              style: TextStyle(
                                color: _selectedLocation != null
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Get Location Button
                    LuxuryButton(
                      text: AppLocalizations.of(context)?.onboardingUseCurrentLocation ?? 'Use Current Location',
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      isLoading: _isLoadingLocation,
                      isSecondary: true,
                    ),

                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _locationError!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Languages Section
                    Text(
                      AppLocalizations.of(context)?.onboardingPickLanguages ?? 'Languages you speak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.onboardingLanguagesSelected(_selectedLanguages.length) ?? '${_selectedLanguages.length}/3 selected',
                        style: TextStyle(
                          color: _selectedLanguages.isNotEmpty
                              ? AppColors.richGold
                              : Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Languages List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableLanguages.map((language) {
                    final isSelected = _selectedLanguages.contains(language);
                    return LuxuryChip(
                      label: _localizedLanguage(context, language),
                      isSelected: isSelected,
                      onTap: () => _toggleLanguage(language),
                      icon: isSelected ? Icons.check_circle : null,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
