import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart' as profile_entity;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditLocationScreen extends StatefulWidget {
  final Profile profile;

  const EditLocationScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  profile_entity.Location? _selectedLocation;
  List<String> _selectedLanguages = [];
  bool _isLoadingLocation = false;
  bool _isSaving = false;

  final List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Turkish',
    'Dutch',
    'Swedish',
    'Polish',
    'Greek',
    'Hebrew',
    'Thai',
    'Vietnamese',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.profile.location;
    _selectedLanguages = List.from(widget.profile.languages);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality
            ?? place.subLocality
            ?? place.subAdministrativeArea
            ?? place.administrativeArea
            ?? place.name
            ?? 'Unknown';
        final country = place.country ?? 'Unknown';
        final displayAddress = city != 'Unknown' ? '$city, $country' : country;

        setState(() {
          _selectedLocation = profile_entity.Location(
            latitude: position.latitude,
            longitude: position.longitude,
            city: city,
            country: country,
            displayAddress: displayAddress,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
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
              content: Text('Maximum 5 languages allowed'),
              backgroundColor: AppColors.warningAmber,
            ),
          );
        }
      }
    });
  }

  void _saveChanges() {
    if (_isSaving) return;

    if (_selectedLocation == null || _selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set location and select at least one language'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedProfile = widget.profile.copyWith(
      location: _selectedLocation!,
      languages: _selectedLanguages,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _selectedLocation != null && _selectedLanguages.isNotEmpty;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileUpdated) {
          // Show success dialog instead of snackbar
          await ActionSuccessDialog.showLocationUpdated(context);
          if (context.mounted) {
            Navigator.of(context).pop(state.profile);
          }
        } else if (state is ProfileError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Location & Languages',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              ),
            )
          else
            TextButton(
              onPressed: isValid ? _saveChanges : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: isValid ? AppColors.richGold : AppColors.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Section
            const Text(
              'Location',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  if (_selectedLocation != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.richGold,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocation!.displayAddress,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lon: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepBlack,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLoadingLocation
                          ? 'Getting Location...'
                          : 'Update Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Languages Section
            const Text(
              'Languages',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedLanguages.length}/5 languages selected',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((language) {
                final isSelected = _selectedLanguages.contains(language);
                return GestureDetector(
                  onTap: () => _toggleLanguage(language),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.richGold
                          : AppColors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.richGold : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          language,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.deepBlack
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check,
                            color: AppColors.deepBlack,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
