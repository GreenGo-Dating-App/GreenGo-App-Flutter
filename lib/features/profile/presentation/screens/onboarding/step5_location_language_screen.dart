import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/connection_error_dialog.dart';
import '../../../domain/entities/profile.dart' as profile_entity;
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

  List<String> _selectedLanguages = [];
  location_entity.Location? _selectedLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _selectedLanguages = List.from(state.languages);
      _selectedLocation = state.location;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
          'Location Services Disabled',
          'Please enable location services in your device settings to use this feature.',
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError(
            'Permission Denied',
            'Location permission is required to detect your current location. Please grant permission to continue.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Permission Permanently Denied',
          'Location permission has been permanently denied. Please enable it in your device settings to use this feature.',
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
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
        final country = placemark.country ?? '';
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
          'Location Not Found',
          'We could not determine your address. Please try again or set your location manually later.',
        );
      }
    } on PlatformException catch (e) {
      // Handle platform-specific errors gracefully
      String message;
      if (e.code == 'PERMISSION_DENIED') {
        message = 'Location permission was denied. Please grant permission in settings.';
      } else if (e.code == 'LOCATION_SERVICE_DISABLED') {
        message = 'Location services are disabled. Please enable them in settings.';
      } else {
        message = 'Unable to get your location. Please check your device settings or try again later.';
      }
      _showLocationError('Location Error', message);
    } on TimeoutException {
      _showLocationError(
        'Request Timeout',
        'Getting your location took too long. Please check your connection and try again.',
      );
    } catch (e) {
      // Handle any other errors gracefully
      String errorMessage = e.toString().toLowerCase();
      String userMessage;

      if (errorMessage.contains('network') || errorMessage.contains('internet') || errorMessage.contains('connection')) {
        userMessage = 'Please check your internet connection and try again.';
      } else if (errorMessage.contains('permission')) {
        userMessage = 'Location permission is required. Please grant permission in settings.';
      } else if (errorMessage.contains('service') || errorMessage.contains('disabled')) {
        userMessage = 'Location services are disabled. Please enable them in settings.';
      } else if (errorMessage.contains('timeout')) {
        userMessage = 'Getting your location took too long. Please try again.';
      } else {
        userMessage = 'Unable to get your location at the moment. You can set it manually later in settings.';
      }

      _showLocationError('Location Unavailable', userMessage);
    }
  }

  void _showLocationError(String title, String message) {
    setState(() {
      _isLoadingLocation = false;
      _locationError = message;
    });

    // Show a graceful dialog
    if (mounted) {
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
        if (_selectedLanguages.length < 5) {
          _selectedLanguages.add(language);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select up to 5 languages'),
              backgroundColor: AppColors.warningAmber,
            ),
          );
        }
      }
    });
  }

  void _handleContinue() {
    // Only require language selection - location is optional
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // If location is set, update it
    if (_selectedLocation != null) {
      context.read<OnboardingBloc>().add(
            OnboardingLocationUpdated(
              location: _selectedLocation! as location_entity.Location,
              languages: _selectedLanguages,
            ),
          );
    } else {
      // Just update languages if no location
      context.read<OnboardingBloc>().add(
            OnboardingLocationUpdated(
              location: location_entity.Location(
                latitude: 0.0,
                longitude: 0.0,
                city: 'Unknown',
                country: 'Unknown',
                displayAddress: 'Location not set',
              ),
              languages: _selectedLanguages,
            ),
          );
    }

    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    if (_selectedLocation != null && _selectedLanguages.isNotEmpty) {
      context.read<OnboardingBloc>().add(
            OnboardingLocationUpdated(
              location: _selectedLocation! as location_entity.Location,
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
          title: 'Where are you?',
          subtitle: 'Set your preferred languages and location (optional)',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Section
                    Row(
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can set your location later in settings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
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
                                  'No location selected',
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
                      text: 'Use Current Location',
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
                      'Languages',
                      style: TextStyle(
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
                        '${_selectedLanguages.length}/5 selected',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableLanguages.map((language) {
                      final isSelected = _selectedLanguages.contains(language);
                      return LuxuryChip(
                        label: language,
                        isSelected: isSelected,
                        onTap: () => _toggleLanguage(language),
                        icon: isSelected ? Icons.check_circle : null,
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                child: LuxuryButton(
                  text: 'Continue',
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
