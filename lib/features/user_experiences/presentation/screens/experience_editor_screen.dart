import 'dart:async';
import '../../../../core/widgets/listing_wizard.dart';
import '../../../experience_bookings/data/datasources/experience_availability_service.dart';
import '../../../experience_bookings/domain/availability_rules.dart';
import '../../../ticket_payments/presentation/ticket_l10n.dart';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/platform/web_media.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/data/services/event_geocoder.dart';
import '../../../events/presentation/screens/event_location_picker_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../experience_bookings/presentation/screens/experience_slots_screen.dart';
import '../../../profile/domain/entities/location.dart' as profile_entity;
import '../../domain/entities/user_experience.dart';
import '../../domain/experience_validation.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../bloc/experience_editor_bloc.dart';
import '../experience_creation_gate.dart';
import '../experience_l10n.dart';
import '../experience_safety_flow.dart';
import '../widgets/experience_policy_widgets.dart';
import '../../../ticket_payments/domain/ticket_payments.dart';
import '../../../ticket_payments/presentation/widgets/ticket_payment_selector.dart';

/// Languages a host can offer (same names profiles store).
// i18n-ignore: stored values; displayed via ExperienceL10n.language
const List<String> kExperienceLanguages = [
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
  'Turkish',
  'Dutch',
  'Swedish',
  'Polish',
  'Greek',
  'Hebrew',
  'Thai',
  'Vietnamese',
];

/// Same currency list as the events form.
const List<String> kExperienceCurrencies = ['\$', '€', '£', 'R\$', '¥'];

/// Create / edit a member-hosted experience. Pops with the saved
/// [UserExperience] (or null when cancelled).
class ExperienceEditorScreen extends StatelessWidget {
  const ExperienceEditorScreen({
    super.key,
    required this.currentUserId,
    this.existing,
    this.communityId,
    this.communityName,
  });

  final String currentUserId;
  final UserExperience? existing;

  /// New listing posted from a community's Experiences tab: the link is
  /// sent with the create call (the server checks the host may post there).
  /// Ignored when editing ([existing] keeps its own, immutable link).
  final String? communityId;
  final String? communityName;

  static Route<UserExperience> route({
    required String currentUserId,
    UserExperience? existing,
    String? communityId,
    String? communityName,
  }) =>
      MaterialPageRoute(
        builder: (_) => ExperienceEditorScreen(
            currentUserId: currentUserId,
            existing: existing,
            communityId: communityId,
            communityName: communityName),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExperienceEditorBloc(
          repository: di.sl<UserExperiencesRepository>()),
      child: _EditorForm(
          currentUserId: currentUserId,
          existing: existing,
          communityId: communityId,
          communityName: communityName),
    );
  }
}

class _EditorForm extends StatefulWidget {
  const _EditorForm({
    required this.currentUserId,
    this.existing,
    this.communityId,
    this.communityName,
  });
  final String currentUserId;
  final UserExperience? existing;
  final String? communityId;
  final String? communityName;

  @override
  State<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends State<_EditorForm> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _meetingPoint = TextEditingController();
  final _hours = TextEditingController(text: '2');
  final _maxGroup = TextEditingController(text: '10');
  final _minGroup = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _paymentValue = TextEditingController();
  final _availability = TextEditingController();
  final _cancellation = TextEditingController();
  final List<TextEditingController> _included = [TextEditingController()];
  final List<TextEditingController> _notIncluded = [];

  ExperienceCategory _category = ExperienceCategory.foodDrink;
  int _minutes = 0;
  final Set<String> _languages = {};
  bool _isFree = false;
  String _currency = kExperienceCurrencies.first;
  PaymentLinkType _paymentType = PaymentLinkType.pix;
  // Paid listings: cash at the meeting and/or the online link.
  // Paid listings are sold as in-app tickets only (ticket_payments): the
  // legacy cash / pasted-link methods are no longer offered.
  final Set<PaymentMethod> _methods = {PaymentMethod.online};
  TicketPaymentChoice _ticket = const TicketPaymentChoice();
  bool _legacyPayment = false;
  String _pricingMode = 'per_person';
  final _groupPrice = TextEditingController();
  final _maxPerUser = TextEditingController(text: '4');
  // Date-based price: a different price on weekend days (day overrides are
  // set in Manage times).
  bool _weekendOn = false;
  final _weekendPrice = TextEditingController();
  Set<int> _weekendDays = {6, 7};
  CancellationPolicy _policy = CancellationPolicy.fallback;
  // Bookings: host approves each request (false = instant booking).

  // Photos: a new pick takes precedence over the existing URL.
  final ImagePicker _picker = ImagePicker();
  XFile? _mainPhoto;
  String? _existingMainUrl;
  final List<XFile> _newPhotos = [];
  final List<String> _existingPhotos = [];

  // Location coordinates and the text they belong to.
  double? _lat;
  double? _lng;
  String? _city;
  String? _country;
  String? _coordsLabel;

  List<ExperienceFieldError> _errors = const [];
  bool _busy = false;
  ExperienceStatus _requestedStatus = ExperienceStatus.published;

  bool get _isNew => widget.existing == null;

  /// The community this listing is (or will be) posted in.
  String? get _communityId => widget.existing != null
      ? widget.existing!.communityId
      : widget.communityId;
  String? get _communityName => widget.existing != null
      ? widget.existing!.communityName
      : widget.communityName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerDraft();
      _loadAvailability();
    });
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
      _category = e.category;
      _existingMainUrl = e.mainPhotoUrl.isEmpty ? null : e.mainPhotoUrl;
      _existingPhotos.addAll(e.photoUrls);
      _included
        ..clear()
        ..addAll(e.included.map((s) => TextEditingController(text: s)));
      if (_included.isEmpty) _included.add(TextEditingController());
      _notIncluded.addAll(e.notIncluded.map((s) => TextEditingController(text: s)));
      _location.text = e.locationName;
      _lat = e.lat;
      _lng = e.lng;
      _city = e.city;
      _country = e.country;
      _coordsLabel = e.hasCoordinates ? e.locationName : null;
      _meetingPoint.text = e.meetingPoint ?? '';
      _hours.text = '${e.durationMinutes ~/ 60}';
      _minutes = e.durationMinutes % 60 - (e.durationMinutes % 60) % 15;
      _languages.addAll(e.languages);
      _maxGroup.text = '${e.maxGroupSize}';
      _minGroup.text = e.minGroupSize?.toString() ?? '';
      _isFree = e.isFree;
      _price.text = e.price == e.price.roundToDouble()
          ? e.price.toStringAsFixed(0)
          : e.price.toStringAsFixed(2);
      if (e.currency != null && kExperienceCurrencies.contains(e.currency)) {
        _currency = e.currency!;
      }
      if (e.paymentLink != null) {
        _paymentType = e.paymentLink!.type;
        _paymentValue.text = e.paymentLink!.value;
      }
      _availability.text = e.availability ?? '';
      _policy = e.cancellationPolicy;
      _cancellation.text = e.cancellationNotes ?? '';
      _pricingMode = e.pricingMode;
      if (e.groupPrice != null) {
        final cur = isoCurrencyFor(e.currency) ?? 'usd';
        _groupPrice.text = currencyExponent(cur) == 0
            ? '${e.groupPrice}'
            : (e.groupPrice! / 100).toStringAsFixed(2);
      }
      _maxPerUser.text = e.maxTicketsPerUser?.toString() ?? '';
      _weekendDays = e.weekendDays.toSet();
      if (e.weekendPrice != null) {
        _weekendOn = true;
        final cur = isoCurrencyFor(e.currency) ?? 'usd';
        final v = e.isPerGroup
            ? e.weekendPrice! / (currencyExponent(cur) == 0 ? 1 : 100)
            : e.weekendPrice!;
        _weekendPrice.text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
      }
      if (e.acceptsOnline) {
        _ticket = TicketPaymentChoice(
          provider: TicketProvider.fromWire(e.paymentProvider),
          linkMethod: e.paymentLinkMethod,
          instructions: e.paymentInstructions,
        );
      } else if (!e.isFree) {
        // Legacy cash / pasted link: the host must choose a ticket payment.
        _legacyPayment = true;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _location,
      _meetingPoint,
      _hours,
      _maxGroup,
      _minGroup,
      _price,
      _paymentValue,
      _groupPrice,
      _maxPerUser,
      _weekendPrice,
      _availability,
      _cancellation,
      ..._included,
      ..._notIncluded,
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────── helpers

  int get _photoCount => _existingPhotos.length + _newPhotos.length;

  int? get _durationMinutes {
    final h = int.tryParse(_hours.text.trim());
    if (h == null) return null;
    return h * 60 + _minutes;
  }

  String _opt(TextEditingController c, [int max = ExperienceLimits.shortTextMax]) {
    final t = c.text.trim();
    return t.length > max ? t.substring(0, max) : t;
  }

  ExperienceDraft _draft() => ExperienceDraft(
        title: _title.text,
        description: _description.text,
        category: _category,
        hasMainPhoto: _mainPhoto != null || _existingMainUrl != null,
        photoCount: _photoCount,
        included: _included.map((c) => c.text).toList(),
        notIncluded: _notIncluded.map((c) => c.text).toList(),
        locationName: _location.text,
        durationMinutes: _durationMinutes,
        languages: _languages.toList(),
        maxGroupSize: int.tryParse(_maxGroup.text.trim()),
        minGroupSize: _minGroup.text.trim().isEmpty
            ? null
            : int.tryParse(_minGroup.text.trim()) ?? -1,
        meetingPoint: _meetingPoint.text,
        availability: _availability.text,
        cancellationNotes: _cancellation.text,
        isFree: _isFree,
        paymentMethods: _methods,
        ticketProviderComplete: _ticket.isComplete && !needsReconnect(_ticket),
        price: _isFree
            ? 0
            : (_pricingMode == 'per_group'
                ? (double.tryParse(_groupPrice.text.trim().replaceAll(',', '.')) ?? -1)
                : double.tryParse(_price.text.trim().replaceAll(',', '.'))),
        paymentType: _paymentType,
        paymentValue: _paymentValue.text,
      );

  String? _err(List<ExperienceFieldError> kinds) {
    final l = AppLocalizations.of(context)!;
    for (final k in kinds) {
      if (_errors.contains(k)) return ExperienceL10n.fieldError(l, k);
    }
    return null;
  }

  void _snack(String msg, {bool error = true}) {
    if (error) {
      showUserErrorMessage(context, msg);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.errorRed : AppColors.successGreen,
    ));
  }

  // ───────────────────────────────────────────── photos

  Future<void> _pickMain() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _mainPhoto = x);
  }

  Future<void> _pickExtra() async {
    if (_photoCount >= ExperienceLimits.maxPhotos) return;
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _newPhotos.add(x));
  }

  Future<bool> _photosAreClean() async {
    // On-device nudity check (native only); server moderation still applies.
    if (kIsWeb) return true;
    for (final f in [if (_mainPhoto != null) _mainPhoto!, ..._newPhotos]) {
      final res =
          await PhotoValidationService().validateImageForSending(File(f.path));
      if (!mounted) return false;
      if (!res.isValid) {
        _snack(AppLocalizations.of(context)!.photoExplicitContent);
        return false;
      }
    }
    return true;
  }

  // ───────────────────────────────────────────── location

  Future<void> _pickOnMap() async {
    final loc = await Navigator.of(context)
        .push<profile_entity.Location>(EventLocationPickerScreen.route());
    if (loc == null || !mounted) return;
    setState(() {
      _lat = loc.latitude;
      _lng = loc.longitude;
      _city = loc.city.isNotEmpty ? loc.city : null;
      _country = loc.country.isNotEmpty ? loc.country : null;
      _location.text = loc.displayAddress;
      _coordsLabel = loc.displayAddress;
    });
  }

  /// Coordinates for the typed location: the map pick when it still matches
  /// the text, else geocoded (null when the place can't be found).
  Future<void> _resolveLocation() async {
    final text = _location.text.trim();
    if (_lat != null && _lng != null && _coordsLabel?.trim() == text) return;
    final loc = await EventGeocoder.geocode(text);
    if (loc == null) {
      _lat = _lng = null;
      _coordsLabel = null;
      return;
    }
    _lat = loc.latitude;
    _lng = loc.longitude;
    _city = loc.city.isNotEmpty ? loc.city : _city;
    _country = loc.country.isNotEmpty ? loc.country : _country;
    _coordsLabel = text;
  }

  // ───────────────────────────────────────────── save

  Future<void> _save(ExperienceStatus status) async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    final errors = ExperienceValidator.validate(_draft());
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      _snack(errors.contains(ExperienceFieldError.prohibitedText)
          ? l.uexpErrProhibited
          : (errors.contains(ExperienceFieldError.contactInfo)
              ? l.uexpErrContactInfo
              : l.uexpErrFixFields));
      return;
    }

    // Phase 1 safety, asked in place BEFORE uploading (the server enforces
    // the same rules): host agreement to publish; an APPROVED ID document to
    // publish a paid listing (else: save as draft / publish as free).
    if (status == ExperienceStatus.published &&
        widget.existing?.isHidden != true) {
      setState(() => _busy = true);
      try {
        final snap = await ExperienceSafetyFlow.load(widget.currentUserId);
        if (!mounted) return;
        if (!await ExperienceSafetyFlow.ensureHostAgreement(
            context, widget.currentUserId,
            snapshot: snap)) {
          return;
        }
        if (!mounted) return;
        if (!_isFree && snap.idState != IdDocState.approved) {
          final r = await ExperienceSafetyFlow.paidBlocked(
              context, widget.currentUserId);
          if (!mounted) return;
          switch (r) {
            case SafetyResolution.saveDraft:
              status = ExperienceStatus.draft;
            case SafetyResolution.publishFree:
              setState(() => _isFree = true);
            case SafetyResolution.retry:
              break; // approved meanwhile
            case SafetyResolution.cancel:
              return;
          }
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    setState(() => _busy = true);
    try {
      // Tier limit (FREE 0 / SILVER 1 / GOLD 5 / PLATINUM ∞) before uploading.
      if (_isNew) {
        final ok = await ExperienceCreationGate(
                repository: di.sl<UserExperiencesRepository>())
            .ensureCanCreate(context, widget.currentUserId);
        if (!ok || !mounted) return;
      }
      if (!await _photosAreClean()) return;

      // Uploads (new picks only; kept URLs stay).
      final ds = di.sl<ProfileRemoteDataSource>();
      String? mainUrl = _existingMainUrl;
      final photos = <String>[..._existingPhotos];
      try {
        if (_mainPhoto != null) {
          mainUrl = await ds.uploadPhoto(widget.currentUserId, _mainPhoto!,
              folder: 'experiences');
        }
        for (final f in _newPhotos) {
          photos.add(await ds.uploadPhoto(widget.currentUserId, f,
              folder: 'experiences'));
        }
      } catch (_) {
        if (mounted) _snack(l.uexpPhotoUploadFailed);
        return;
      }
      if (!mounted || mainUrl == null) return;

      await _resolveLocation();
      if (!mounted) return;
      if (_lat == null) _snack(l.uexpLocationNotFound, error: false);

      final host = (await UserDirectoryService.instance
          .resolve([widget.currentUserId]))[widget.currentUserId];
      if (!mounted) return;

      final e = widget.existing;
      // per_group: `price` mirrors the group price (major units) for lists
      // and older clients; the server charges groupPrice (minor units).
      final price = _isFree
          ? 0.0
          : double.tryParse((_pricingMode == 'per_group' ? _groupPrice : _price)
                  .text
                  .trim()
                  .replaceAll(',', '.')) ??
              0;
      final minG = int.tryParse(_minGroup.text.trim());
      _requestedStatus = status;
      final experience = UserExperience(
        id: e?.id ?? '',
        hostId: widget.currentUserId,
        hostName: (host?.name.isNotEmpty ?? false) ? host!.name : e?.hostName,
        hostPhotoUrl: host?.photoUrl ?? e?.hostPhotoUrl,
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        mainPhotoUrl: mainUrl,
        photoUrls: photos,
        included: ExperienceValidator.cleanItems(
            _included.map((c) => c.text).toList()),
        notIncluded: ExperienceValidator.cleanItems(
            _notIncluded.map((c) => c.text).toList()),
        locationName: _location.text.trim(),
        city: _city,
        country: _country,
        lat: _lat,
        lng: _lng,
        geohash: _lat != null && _lng != null
            ? GeoQuery.encode(_lat!, _lng!)
            : null,
        meetingPoint: _opt(_meetingPoint).isEmpty ? null : _opt(_meetingPoint),
        durationMinutes: _durationMinutes!,
        languages: _languages.toList(),
        minGroupSize: minG,
        maxGroupSize: int.parse(_maxGroup.text.trim()),
        price: price,
        currency: _isFree ? null : _currency,
        isFree: _isFree,
        paymentLink: null,
        paymentMethods: _isFree ? const {} : {PaymentMethod.online},
        paymentProvider: _isFree ? null : _ticket.provider?.wire,
        paymentLinkMethod: _isFree || _ticket.provider != TicketProvider.link ? null : _ticket.linkMethod,
        paymentInstructions: _isFree || _ticket.provider != TicketProvider.link
            ? null
            : ((_ticket.instructions ?? '').trim().isEmpty ? null : _ticket.instructions!.trim()),
        pricingMode: _pricingMode,
        groupPrice: _isFree || _pricingMode != 'per_group'
            ? null
            : toMinorUnits(double.tryParse(_groupPrice.text.trim().replaceAll(',', '.')) ?? 0,
                isoCurrencyFor(_currency) ?? 'usd'),
        maxTicketsPerUser: int.tryParse(_maxPerUser.text.trim()),
        weekendPrice: _isFree || !_weekendOn
            ? null
            : (() {
                final v = double.tryParse(_weekendPrice.text.trim().replaceAll(',', '.'));
                if (v == null || v <= 0) return null;
                return _pricingMode == 'per_group'
                    ? toMinorUnits(v, isoCurrencyFor(_currency) ?? 'usd').toDouble()
                    : v;
              })(),
        weekendDays: (_weekendDays.toList()..sort()),
        // Availability is defined by the dates (slots), not free text.
        availability: null,
        cancellationPolicy: _policy,
        requestToBook: true,
        cancellationNotes: _opt(_cancellation,
                    ExperienceLimits.cancellationNotesMax)
                .isEmpty
            ? null
            : _opt(_cancellation, ExperienceLimits.cancellationNotesMax),
        // A moderation-hidden listing stays hidden (the server restores it
        // once the text is clean).
        status: e?.isHidden == true ? ExperienceStatus.hidden : status,
        createdAt: e?.createdAt,
        ratingSum: e?.ratingSum ?? 0,
        ratingCount: e?.ratingCount ?? 0,
        ratingAvg: e?.ratingAvg ?? 0,
        ratingDist: e?.ratingDist ?? const {},
        reviewCount: e?.reviewCount ?? 0,
        // Server-owned link: only sent on create (createPayload).
        communityId: _communityId,
        communityName: _communityName,
      );
      _submit(experience);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Last submitted experience (re-submitted after a guided safety prompt).
  UserExperience? _submitted;

  /// A new listing the host asked to publish: stored as a draft first (it
  /// has no dates yet), then its dates screen, then [_publishWithDates].
  bool _publishAfterDates = false;

  void _submit(UserExperience experience) {
    _submitted = experience;
    _requestedStatus = experience.status;
    _publishAfterDates =
        _isNew && experience.status == ExperienceStatus.published;
    if (_publishAfterDates) {
      experience = experience.copyWith(status: ExperienceStatus.draft);
    }
    context.read<ExperienceEditorBloc>().add(ExperienceEditorSaved(
          experience,
          isNew: _isNew,
          publish: experience.status == ExperienceStatus.published,
          wasPublished: widget.existing?.isPublished == true,
        ));
  }

  /// Opens the dates of the stored draft [draft], then publishes it (the
  /// server requires an upcoming date). No date added: it stays a draft.
  Future<void> _publishWithDates(UserExperience draft) async {
    final l = AppLocalizations.of(context)!;
    if (_useRecurring) {
      // Recurring schedule from the wizard: no separate dates screen.
      await _saveAvailability(draft.id);
    } else {
      await Navigator.of(context).push(ExperienceSlotsScreen.route(
          experience: draft, currentUserId: widget.currentUserId));
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final repo = di.sl<UserExperiencesRepository>();
    try {
      var asFree = false;
      for (var attempt = 0; attempt < 2; attempt++) {
        final r = await repo.publishExperience(draft.id, asFree: asFree);
        if (!mounted) return;
        final f = r.fold((f) => f, (_) => null);
        if (f == null) {
          _snack(l.uexpPublished, error: false);
          Navigator.of(context).pop((asFree ? draft.asFree() : draft)
              .copyWith(status: ExperienceStatus.published));
          return;
        }
        if (f is ExperienceSafetyFailure && f.code != 'dates_required') {
          final res = await ExperienceSafetyFlow.resolve(
              context, widget.currentUserId, f.code);
          if (!mounted) return;
          if (res == SafetyResolution.retry) continue;
          if (res == SafetyResolution.publishFree) {
            asFree = true;
            continue;
          }
          break;
        }
        _snack(f is ExperienceSafetyFailure
            ? l.uexpDatesRequiredToPublish
            : l.uexpSaveFailed);
        break;
      }
      if (mounted) Navigator.of(context).pop(draft);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Posted in <community>" — the listing's (immutable) community link.
  Widget _postedInChip(AppLocalizations l) {
    final name = (_communityName ?? '').trim();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Chip(
          key: const Key('uexpPostedInChip'),
          avatar: const Icon(Icons.groups_outlined,
              size: 18, color: AppColors.richGold),
          label: Text(
            l.uexpPostedInCommunity(name.isEmpty ? '…' : name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.backgroundCard,
          side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.5)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  /// Languages as a compact combobox: a field that opens a searchable
  /// multi-select list, with the chosen ones as removable chips.
  Widget _languagesField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const ValueKey('editor-languages'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickLanguages(l),
          child: InputDecorator(
            decoration: _dec(l.uexpLanguages).copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.richGold),
            ),
            isEmpty: _languages.isEmpty,
            child: Text(
              _languages.map((x) => ExperienceL10n.language(l, x)).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text,
            ),
          ),
        ),
        if (_languages.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final lang in _languages)
              InputChip(
                label: Text(ExperienceL10n.language(l, lang)),
                labelStyle: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12),
                backgroundColor: AppColors.richGold.withValues(alpha: 0.18),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: () => setState(() => _languages.remove(lang)),
              ),
          ]),
        ],
      ],
    );
  }

  Future<void> _pickLanguages(AppLocalizations l) async {
    final draft = {..._languages};
    var query = '';
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final q = query.toLowerCase();
          final options = kExperienceLanguages
              .where((x) =>
                  q.isEmpty ||
                  x.toLowerCase().contains(q) ||
                  ExperienceL10n.language(l, x).toLowerCase().contains(q))
              .toList();
          final full = draft.length >= ExperienceLimits.languagesMax;
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(l.uexpLanguages,
                style: const TextStyle(color: AppColors.textPrimary)),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: 360,
              height: 420,
              child: Column(children: [
                TextField(
                  style: _text,
                  decoration: _dec(
                          MaterialLocalizations.of(ctx).searchFieldLabel)
                      .copyWith(
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textTertiary)),
                  onChanged: (v) => setD(() => query = v.trim()),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(children: [
                    for (final lang in options)
                      CheckboxListTile(
                        dense: true,
                        value: draft.contains(lang),
                        activeColor: AppColors.richGold,
                        checkColor: Colors.black,
                        title: Text(ExperienceL10n.language(l, lang),
                            style: _text),
                        onChanged: !draft.contains(lang) && full
                            ? null
                            : (v) => setD(() {
                                  if (v == true) {
                                    draft.add(lang);
                                  } else {
                                    draft.remove(lang);
                                  }
                                }),
                      ),
                  ]),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, draft),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(l.done),
              ),
            ],
          );
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() => _languages
        ..clear()
        ..addAll(picked));
    }
  }

  /// The server refused to publish ([code]): ask for what is missing, then
  /// re-submit (or save as draft / publish as free).
  Future<void> _resolveSafety(String code, UserExperience? savedDraft) async {
    final l = AppLocalizations.of(context)!;
    final x = _submitted;
    if (x == null) return;
    if (code == 'dates_required' && savedDraft != null) {
      await _publishWithDates(savedDraft);
      return;
    }
    final r =
        await ExperienceSafetyFlow.resolve(context, widget.currentUserId, code);
    if (!mounted) return;
    switch (r) {
      case SafetyResolution.retry:
        _submit(x);
      case SafetyResolution.publishFree:
        setState(() => _isFree = true);
        _submit(x.asFree());
      case SafetyResolution.saveDraft:
        if (savedDraft != null) {
          // Edits are already stored as a draft.
          _snack(l.uexpSaved, error: false);
          Navigator.of(context).pop(savedDraft);
        } else {
          _submit(x.copyWith(status: ExperienceStatus.draft));
        }
      case SafetyResolution.cancel:
        if (savedDraft != null) {
          // Stored as a draft already: leave the editor with it.
          Navigator.of(context).pop(savedDraft);
        }
    }
  }

  // ───────────────────────────────────────────── build

  InputDecoration _dec(String label, {String? hint, String? error}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        errorMaxLines: 3,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      );

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  static const _text = TextStyle(color: AppColors.textPrimary);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocListener<ExperienceEditorBloc, ExperienceEditorState>(
      listener: (context, s) async {
        if (s.status == ExperienceEditorStatus.saved &&
            s.saved != null &&
            _publishAfterDates) {
          _publishAfterDates = false;
          await _publishWithDates(s.saved!);
        } else if (s.status == ExperienceEditorStatus.saved &&
            s.saved != null) {
          if (_useRecurring) await _saveAvailability(s.saved!.id);
          unawaited(_draftStore.clear());
          if (!context.mounted) return;
          _snack(
              _requestedStatus == ExperienceStatus.published
                  ? l.uexpPublished
                  : l.uexpSaved,
              error: false);
          Navigator.of(context).pop(s.saved);
        } else if (s.status == ExperienceEditorStatus.failed) {
          final f = s.failure;
          if (f is ExperienceLimitFailure) {
            final allowance = await ExperienceCreationGate(
                    repository: di.sl<UserExperiencesRepository>())
                .check(widget.currentUserId);
            if (!context.mounted) return;
            await ExperienceCreationGate.showLimitDialog(
                context, widget.currentUserId, allowance);
          } else if (f is ExperienceSafetyFailure) {
            await _resolveSafety(f.code, s.saved);
          } else if (f is ExperienceContactInfoFailure) {
            setState(() => _errors = [..._errors, ExperienceFieldError.contactInfo]);
            _snack(l.uexpErrContactInfo);
          } else if (f is ExperienceProhibitedFailure) {
            _snack(l.uexpErrProhibited);
          } else if (f is ExperienceCommunityFailure) {
            _snack(l.uexpErrCommunityNotAllowed);
          } else if (f is ExperienceInvalidFailure) {
            _snack(l.uexpErrFixFields);
          } else {
            _snack(l.uexpSaveFailed);
          }
        }
      },
      child: BlocBuilder<ExperienceEditorBloc, ExperienceEditorState>(
        builder: (context, s) {
          final saving = _busy || s.status == ExperienceEditorStatus.saving;
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              title: Text(_isNew ? l.uexpNewTitle : l.uexpEditTitle,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            body: AbsorbPointer(
              absorbing: saving,
              child: ListingWizard(
                editMode: !_isNew,
                controller: _wizard,
                onStepChanged: (_) => _autosaveDraft(),
                steps: [
                  WizardStep(
                    title: l.wzExpBasics,
                    description: l.wzExBasicsDesc,
                    requirements: l.wzExBasicsReq,
                    icon: Icons.edit_note,
                    error: () => _stepError(l, const [
                      ExperienceFieldError.titleLength, ExperienceFieldError.descriptionLength,
                      ExperienceFieldError.mainPhotoRequired, ExperienceFieldError.tooManyPhotos,
                      ExperienceFieldError.includedRequired, ExperienceFieldError.tooManyIncluded,
                      ExperienceFieldError.includedItemTooLong, ExperienceFieldError.tooManyNotIncluded,
                      ExperienceFieldError.notIncludedItemTooLong, ExperienceFieldError.languagesRequired,
                    ]),
                    summary: () => _title.text,
                    builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if ((_communityId ?? '').isNotEmpty)
                    _postedInChip(l),
                  _photosSection(l),
                  _section(l.uexpSectionBasics, [
                    TextField(
                      controller: _title,
                      maxLength: ExperienceLimits.titleMax,
                      style: _text,
                      decoration: _dec(l.uexpFieldTitle,
                          error: _err([ExperienceFieldError.titleLength])),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ExperienceCategory>(
                      value: _category,
                      dropdownColor: AppColors.backgroundCard,
                      style: _text,
                      decoration: _dec(l.uexpFieldCategory),
                      items: [
                        for (final c in ExperienceCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Icon(ExperienceL10n.categoryIcon(c),
                                  size: 18, color: AppColors.richGold),
                              const SizedBox(width: 8),
                              Text(ExperienceL10n.category(l, c)),
                            ]),
                          ),
                      ],
                      onChanged: (v) => setState(
                          () => _category = v ?? ExperienceCategory.other),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      minLines: 4,
                      maxLines: 10,
                      maxLength: ExperienceLimits.descriptionMax,
                      style: _text,
                      decoration: _dec(l.uexpFieldDescription,
                          error:
                              _err([ExperienceFieldError.descriptionLength])),
                    ),
                  ]),
                  _itemsSection(
                    l.uexpIncluded,
                    _included,
                    max: ExperienceLimits.includedMax,
                    error: _err([
                      ExperienceFieldError.includedRequired,
                      ExperienceFieldError.tooManyIncluded,
                      ExperienceFieldError.includedItemTooLong,
                    ]),
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.successGreen,
                  ),
                  _itemsSection(
                    l.uexpNotIncluded,
                    _notIncluded,
                    max: ExperienceLimits.notIncludedMax,
                    error: _err([
                      ExperienceFieldError.tooManyNotIncluded,
                      ExperienceFieldError.notIncludedItemTooLong,
                    ]),
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.errorRed,
                  ),
                  _section(l.uexpLanguages, [
                    _languagesField(l),
                    if (_err([ExperienceFieldError.languagesRequired]) != null)
                      _errorLine(
                          _err([ExperienceFieldError.languagesRequired])!),
                  ]),
                    ]),
                  ),
                  WizardStep(
                    title: l.wzLocation,
                    description: l.wzExLocationDesc,
                    requirements: l.wzExLocationReq,
                    icon: Icons.place_outlined,
                    error: () => _stepError(l, const [ExperienceFieldError.locationRequired]),
                    summary: () => _location.text,
                    builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _section(l.uexpFieldLocation, [
                    TextField(
                      controller: _location,
                      maxLength: ExperienceLimits.locationMax,
                      style: _text,
                      decoration: _dec(l.uexpFieldLocation,
                          hint: l.uexpLocationHint,
                          error: _err([ExperienceFieldError.locationRequired])),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _pickOnMap,
                        icon: const Icon(Icons.map_outlined,
                            color: AppColors.richGold),
                        label: Text(l.uexpPickOnMap,
                            style: const TextStyle(color: AppColors.richGold)),
                      ),
                    ),
                    TextField(
                      controller: _meetingPoint,
                      maxLength: ExperienceLimits.shortTextMax,
                      style: _text,
                      decoration: _dec(l.uexpMeetingPoint),
                    ),
                  ]),
                    ]),
                  ),
                  WizardStep(
                    title: l.wzFormatPrice,
                    description: l.wzExFormatDesc,
                    requirements: l.wzExFormatReq,
                    note: _isFree ? l.wzPaymentAppearsNote : null,
                    icon: Icons.sell_outlined,
                    error: () => _stepError(l, const [
                      ExperienceFieldError.durationInvalid, ExperienceFieldError.maxGroupInvalid,
                      ExperienceFieldError.minGroupInvalid, ExperienceFieldError.priceInvalid,
                    ]),
                    summary: () => _isFree ? l.uexpFree : '$_currency ${_pricingMode == 'per_group' ? _groupPrice.text : _price.text}',
                    builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _section(l.uexpSectionPractical, [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _hours,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: _text,
                          decoration: _dec(l.uexpHours),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _minutes,
                          dropdownColor: AppColors.backgroundCard,
                          style: _text,
                          decoration: _dec(l.uexpMinutes),
                          items: [
                            for (final m in const [0, 15, 30, 45])
                              DropdownMenuItem(value: m, child: Text('$m')),
                          ],
                          onChanged: (v) => setState(() => _minutes = v ?? 0),
                        ),
                      ),
                    ]),
                    if (_err([ExperienceFieldError.durationInvalid]) != null)
                      _errorLine(_err([ExperienceFieldError.durationInvalid])!),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _minGroup,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: _text,
                          decoration: _dec(l.uexpMinGroup,
                              error:
                                  _err([ExperienceFieldError.minGroupInvalid])),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxGroup,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: _text,
                          decoration: _dec(l.uexpMaxGroup,
                              error:
                                  _err([ExperienceFieldError.maxGroupInvalid])),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(l.uexpCancellationLabel,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    CancellationPolicyPicker(
                      value: _policy,
                      onChanged: (p) => setState(() => _policy = p),
                    ),
                    TextField(
                      controller: _cancellation,
                      maxLength: ExperienceLimits.cancellationNotesMax,
                      minLines: 1,
                      maxLines: 4,
                      style: _text,
                      decoration: _dec(l.uexpPolicyNotes),
                    ),
                  ]),
                  _pricingSection(l),
                    ]),
                  ),
                  WizardStep(
                    title: l.wzAvailability,
                    description: l.wzExAvailDesc,
                    requirements: l.wzExAvailReq,
                    icon: Icons.calendar_month_outlined,
                    error: () => _useRecurring && _availRules.error != null ? l.mtErrRules : null,
                    summary: () => _useRecurring
                        ? '${_availRules.windowStart}–${_availRules.windowEnd} · ${l.mtHoursMinutes(_availRules.durationMinutes ~/ 60, _availRules.durationMinutes % 60)}'
                        : l.bkDatesTitle,
                    builder: (context) => _availabilityStep(l),
                  ),
                  WizardStep(
                    title: l.wzPayment,
                    description: l.wzExPaymentDesc,
                    requirements: l.wzExPaymentReq,
                    icon: Icons.payments_outlined,
                    skip: _isFree,
                    error: () => _stepError(l, const [ExperienceFieldError.paymentMethodsRequired]),
                    summary: () => _ticket.provider == null ? '—' : TicketL10n.provider(l, _ticket.provider!),
                    builder: (context) => _paymentSection(l),
                  ),
                  WizardStep(
                    title: l.wzReview,
                    description: l.wzExReviewDesc,
                    icon: Icons.fact_check_outlined,
                    builder: (context) => _reviewStep(l, saving),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Wizard helpers ----
  final ListingWizardController _wizard = ListingWizardController();

  /// The first error of [kinds] in the current form (step gating), or null.
  String? _stepError(AppLocalizations l, List<ExperienceFieldError> kinds) {
    final errors = ExperienceValidator.validate(_draft());
    for (final k in kinds) {
      if (errors.contains(k)) return ExperienceL10n.fieldError(l, k);
    }
    return null;
  }

  // Availability step: the recurring schedule (saved after the listing).
  bool _useRecurring = true;
  AvailabilityRules _availRules = AvailabilityRules(
    timezone: defaultTimeZone(DateTime.now().timeZoneOffset),
    dateFrom: dateKey(DateTime.now()),
  );
  bool _availLoaded = false;
  AvailabilityOverrides _availOverrides = const AvailabilityOverrides();

  /// Saves the wizard's schedule (asks before removing booked times).
  Future<void> _saveAvailability(String experienceId) async {
    if (experienceId.isEmpty || _availRules.error != null) return;
    final l = AppLocalizations.of(context)!;
    final svc = ExperienceAvailabilityService();
    try {
      final r = await svc.save(experienceId, _availRules, _availOverrides);
      if (r.needsConfirm && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(l.mtConfirmTitle),
            content: Text(l.mtConfirmBody(r.affected)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.mtConfirmCancelBookings)),
            ],
          ),
        );
        if (ok == true) await svc.save(experienceId, _availRules, _availOverrides, confirm: true);
      }
    } catch (_) {
      if (mounted) _snack(l.mtErrRules);
    }
  }

  Future<void> _loadAvailability() async {
    final e = widget.existing;
    if (e == null || _availLoaded) return;
    _availLoaded = true;
    try {
      final s = await ExperienceAvailabilityService().load(e.id);
      if (!mounted) return;
      setState(() {
        _availOverrides = s.overrides;
        if (s.rules != null) {
          _availRules = s.rules!;
        } else {
          _useRecurring = false; // legacy listing: keeps its dated slots
        }
      });
    } catch (_) {}
  }

  Widget _availabilityStep(AppLocalizations l) {
    final r = _availRules;
    final preview = dayTimes(r.copyWith(weekdays: const [1, 2, 3, 4, 5, 6, 7]), '2024-01-01');
    final locale = Localizations.localeOf(context).toString();
    Future<String?> pickTime(String initial) async {
      final m = minutesOf(initial) ?? 540;
      final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
      return t == null ? null : hmOf(t.hour * 60 + t.minute);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(
        key: const ValueKey('wizard-recurring-toggle'),
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.richGold,
        title: Text(l.wzRecurringToggle, style: _text),
        subtitle: Text(l.wzRecurringInfo, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        value: _useRecurring,
        onChanged: (v) => setState(() => _useRecurring = v),
      ),
      if (_useRecurring) ...[
        Row(children: [
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('wizard-avail-from'),
              onPressed: () async {
                final t = await pickTime(r.windowStart);
                if (t != null) setState(() => _availRules = _availRules.copyWith(windowStart: t));
              },
              child: Text('${l.mtAvailableFrom} ${r.windowStart}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('wizard-avail-until'),
              onPressed: () async {
                final t = await pickTime(r.windowEnd);
                if (t != null) setState(() => _availRules = _availRules.copyWith(windowEnd: t));
              },
              child: Text('${l.mtAvailableUntil} ${r.windowEnd}'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: const [30, 45, 60, 90, 120, 150, 180, 240, 300, 360, 480].contains(r.durationMinutes) ? r.durationMinutes : null,
              dropdownColor: AppColors.backgroundCard,
              decoration: _dec(l.mtDuration),
              items: [
                for (final d in const [30, 45, 60, 90, 120, 150, 180, 240, 300, 360, 480])
                  DropdownMenuItem(value: d, child: Text(l.mtHoursMinutes(d ~/ 60, d % 60))),
              ],
              onChanged: (v) => setState(() => _availRules = _availRules.copyWith(durationMinutes: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: const [0, 10, 15, 30, 45, 60, 90, 120].contains(r.bufferMinutes) ? r.bufferMinutes : 0,
              dropdownColor: AppColors.backgroundCard,
              decoration: _dec(l.mtBreak),
              items: [
                for (final d in const [0, 10, 15, 30, 45, 60, 90, 120])
                  DropdownMenuItem(value: d, child: Text(d == 0 ? l.mtNoBreak : l.mtMinutes(d))),
              ],
              onChanged: (v) => setState(() => _availRules = _availRules.copyWith(bufferMinutes: v)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: r.startEveryMinutes,
          dropdownColor: AppColors.backgroundCard,
          decoration: _dec(l.mtStartEvery),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l.mtStartEveryAuto)),
            for (final d in const [15, 30, 45, 60, 90, 120, 180, 240].where((d) => d >= r.durationMinutes))
              DropdownMenuItem<int?>(value: d, child: Text(l.mtMinutes(d))),
          ],
          onChanged: (v) => setState(() => _availRules =
              v == null ? _availRules.copyWith(clearStartEvery: true) : _availRules.copyWith(startEveryMinutes: v)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (var wd = 1; wd <= 7; wd++)
            FilterChip(
              key: ValueKey('wizard-avail-wd-$wd'),
              label: Text(DateFormat.E(locale).format(DateTime(2024, 1, wd))),
              selected: r.weekdays.contains(wd),
              onSelected: (v) => setState(() {
                final w = {...r.weekdays};
                v ? w.add(wd) : w.remove(wd);
                _availRules = _availRules.copyWith(weekdays: w.toList()..sort());
              }),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (d != null) setState(() => _availRules = _availRules.copyWith(dateFrom: dateKey(d)));
              },
              child: Text('${l.mtDateFrom}: ${r.dateFrom ?? '—'}'), // i18n-ignore: localized label + date
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                setState(() => _availRules = d == null ? _availRules.copyWith(clearDateTo: true) : _availRules.copyWith(dateTo: dateKey(d)));
              },
              child: Text('${l.mtDateTo}: ${r.dateTo ?? l.mtNoEnd}'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(l.mtPreview, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 4),
        Wrap(key: const ValueKey('wizard-avail-preview'), spacing: 6, runSpacing: 6, children: [
          for (final t in preview) Chip(label: Text(t), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 6),
        Text(l.wzFineTuneLater, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ] else
        _bookingSettings(l),
    ]);
  }

  /// "Fix" on the review checklist: jump to the step that owns [e].
  VoidCallback? _fixFor(ExperienceFieldError e) {
    final step = switch (e) {
      ExperienceFieldError.locationRequired => 1,
      ExperienceFieldError.durationInvalid ||
      ExperienceFieldError.maxGroupInvalid ||
      ExperienceFieldError.minGroupInvalid ||
      ExperienceFieldError.priceInvalid => 2,
      ExperienceFieldError.paymentMethodsRequired ||
      ExperienceFieldError.paymentLinkRequired ||
      ExperienceFieldError.paymentLinkInvalid => _isFree ? 2 : 4,
      _ => 0,
    };
    return () => _wizard.goTo(step);
  }

  Widget _reviewStep(AppLocalizations l, bool saving) {
    final errors = ExperienceValidator.validate(_draft());
    final checks = <(String, bool, VoidCallback?)>[
      for (final e in errors) (ExperienceL10n.fieldError(l, e), true, _fixFor(e)),
      if (!_useRecurring && widget.existing == null) (l.wzWarnNoAvailability, false, () => _wizard.goTo(3)),
      if (_useRecurring && _availRules.error != null) (l.mtErrRules, true, () => _wizard.goTo(3)),
    ];
    final blocked = checks.any((c) => c.$2);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.wzPreviewTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      const SizedBox(height: 6),
      Card(
        key: const ValueKey('experience-review-preview'),
        color: AppColors.backgroundCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_title.text.isEmpty ? '—' : _title.text,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_location.text, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(_isFree
                    ? l.uexpFree
                    : (_pricingMode == 'per_group'
                        ? l.tpGroupPreview('$_currency${_groupPrice.text}', int.tryParse(_maxGroup.text) ?? 0)
                        : '$_currency${_price.text}'),
                style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      WizardChecklist(items: checks),
      const SizedBox(height: 16),
      if (blocked)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.wzPublishBlocked,
              key: const ValueKey('experience-publish-blocked'),
              style: const TextStyle(color: AppColors.warningAmber, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      Row(children: [
                  if (widget.existing?.isPublished != true)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.richGold,
                          side: const BorderSide(color: AppColors.richGold),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: saving
                            ? null
                            : () => _save(ExperienceStatus.draft),
                        child: Text(l.uexpSaveDraft),
                      ),
                    ),
                  if (widget.existing?.isPublished != true)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: saving || blocked
                          ? null
                          : () => _save(ExperienceStatus.published),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.deepBlack))
                          : Text(widget.existing?.isPublished == true
                              ? l.uexpSaveChanges
                              : l.uexpPublish),
                    ),
                  ),
                ]),
    ]);
  }

  WizardDraftStore get _draftStore => WizardDraftStore('wizard_experience_${widget.currentUserId}');

  Map<String, dynamic> _draftMap() => {
        'title': _title.text,
        'description': _description.text,
        'category': _category.name,
        'location': _location.text,
        'meetingPoint': _meetingPoint.text,
        'hours': _hours.text,
        'minutes': _minutes,
        'maxGroup': _maxGroup.text,
        'minGroup': _minGroup.text,
        'isFree': _isFree,
        'price': _price.text,
        'currency': _currency,
        'pricingMode': _pricingMode,
        'groupPrice': _groupPrice.text,
        'languages': _languages.toList(),
        'rules': _availRules.toMap(),
        'recurring': _useRecurring,
      };

  void _restoreDraft(Map<String, dynamic> d) {
    setState(() {
      _title.text = d['title'] as String? ?? '';
      _description.text = d['description'] as String? ?? '';
      _category = ExperienceCategory.fromWire(d['category']);
      _location.text = d['location'] as String? ?? '';
      _meetingPoint.text = d['meetingPoint'] as String? ?? '';
      _hours.text = d['hours'] as String? ?? _hours.text;
      _minutes = (d['minutes'] as int?) ?? _minutes;
      _maxGroup.text = d['maxGroup'] as String? ?? _maxGroup.text;
      _minGroup.text = d['minGroup'] as String? ?? '';
      _isFree = d['isFree'] as bool? ?? _isFree;
      _price.text = d['price'] as String? ?? _price.text;
      if (kExperienceCurrencies.contains(d['currency'])) _currency = d['currency'] as String;
      _pricingMode = d['pricingMode'] == 'per_group' ? 'per_group' : 'per_person';
      _groupPrice.text = d['groupPrice'] as String? ?? '';
      _languages
        ..clear()
        ..addAll(((d['languages'] as List?) ?? const []).whereType<String>());
      if (d['rules'] is Map) _availRules = AvailabilityRules.fromMap(Map<String, dynamic>.from(d['rules'] as Map));
      _useRecurring = d['recurring'] as bool? ?? true;
    });
  }

  Future<void> _autosaveDraft() async {
    if (!_isNew) return;
    await _draftStore.write(_draftMap());
  }

  Future<void> _offerDraft() async {
    if (!_isNew) return;
    final d = await _draftStore.read();
    if (d == null || !mounted) return;
    if (await WizardDraftStore.askResume(context)) {
      _restoreDraft(d);
    } else {
      await _draftStore.clear();
    }
  }

  /// "Dates & availability": every booking is a request on one of these
  /// dates, and a listing needs an upcoming one to be published (a new
  /// listing is saved first, then its dates screen opens).
  Widget _bookingSettings(AppLocalizations l) {
    final existing = widget.existing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.event_available,
              size: 18, color: AppColors.richGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.uexpDatesRequiredHint,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 10),
        if (existing != null && existing.id.isNotEmpty)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.richGold,
              side: const BorderSide(color: AppColors.richGold),
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(context).push(
                ExperienceSlotsScreen.route(
                    experience: existing, currentUserId: widget.currentUserId)),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(l.bkDatesTitle),
          )
        else
          Text(l.bkDatesAfterSave,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12)),
      ],
    );
  }

  Widget _errorLine(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Text(text,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
      );

  Widget _photosSection(AppLocalizations l) {
    Widget slot({
      XFile? file,
      String? url,
      required VoidCallback onTap,
      VoidCallback? onRemove,
      bool main = false,
    }) {
      final has = file != null || (url != null && url.isNotEmpty);
      final size = main ? 110.0 : 72.0;
      return GestureDetector(
        onTap: onTap,
        child: Stack(children: [
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              image: file != null
                  ? DecorationImage(
                      image: WebMedia.imageProviderFor(file), fit: BoxFit.cover)
                  : (has
                      ? DecorationImage(
                          image: NetworkImage(url!), fit: BoxFit.cover)
                      : null),
              border: Border.all(
                  color: main
                      ? AppColors.richGold.withValues(alpha: 0.6)
                      : AppColors.textTertiary.withValues(alpha: 0.3)),
            ),
            child: has
                ? null
                : Icon(main ? Icons.add_a_photo : Icons.add,
                    color: AppColors.textSecondary),
          ),
          if (onRemove != null && has)
            Positioned(
              right: 12,
              top: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ]),
      );
    }

    return _section(l.uexpSectionPhotos, [
      Text('${l.uexpMainPhoto} · ${l.uexpMorePhotos(ExperienceLimits.maxPhotos)}',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      const SizedBox(height: 8),
      SizedBox(
        height: 116,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            slot(
              file: _mainPhoto,
              url: _existingMainUrl,
              main: true,
              onTap: _pickMain,
              onRemove: () => setState(() {
                _mainPhoto = null;
                _existingMainUrl = null;
              }),
            ),
            for (final u in _existingPhotos)
              slot(
                url: u,
                onTap: () {},
                onRemove: () => setState(() => _existingPhotos.remove(u)),
              ),
            for (final f in _newPhotos)
              slot(
                file: f,
                onTap: () {},
                onRemove: () => setState(() => _newPhotos.remove(f)),
              ),
            if (_photoCount < ExperienceLimits.maxPhotos) slot(onTap: _pickExtra),
          ],
        ),
      ),
      if (_err([
            ExperienceFieldError.mainPhotoRequired,
            ExperienceFieldError.tooManyPhotos
          ]) !=
          null)
        _errorLine(_err([
          ExperienceFieldError.mainPhotoRequired,
          ExperienceFieldError.tooManyPhotos
        ])!),
    ]);
  }

  Widget _itemsSection(
    String title,
    List<TextEditingController> items, {
    required int max,
    required String? error,
    required IconData icon,
    required Color iconColor,
  }) {
    final l = AppLocalizations.of(context)!;
    return _section(title, [
      for (var i = 0; i < items.length; i++)
        Padding(
          key: ObjectKey(items[i]),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: items[i],
                maxLength: ExperienceLimits.itemMax,
                style: _text,
                decoration: _dec('', hint: l.uexpItemHint)
                    .copyWith(labelText: null, counterText: ''),
              ),
            ),
            IconButton(
              tooltip: l.uexpRemoveItem,
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.textTertiary),
              onPressed: () {
                final removed = items[i];
                setState(() => items.remove(removed));
                // Dispose once its TextField has been unmounted.
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => removed.dispose());
              },
            ),
          ]),
        ),
      if (items.length < max)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => items.add(TextEditingController())),
            icon: const Icon(Icons.add, color: AppColors.richGold),
            label: Text(l.uexpAddItem,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ),
      if (error != null) _errorLine(error),
    ]);
  }

  /// Wizard step "Payment" (paid listings only).
  Widget _paymentSection(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (_legacyPayment && !_ticket.isComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.tpLegacyPaymentPrompt,
                  style: const TextStyle(color: AppColors.warningAmber, fontSize: 12.5)),
            ),
          TicketPaymentSelector(
            uid: widget.currentUserId,
            value: _ticket,
            onChanged: (c) => setState(() => _ticket = c),
            capacity: int.tryParse(_maxGroup.text.trim()),
            price: _pricingMode == 'per_group'
                ? double.tryParse(_groupPrice.text.trim().replaceAll(',', '.'))
                : double.tryParse(_price.text.trim().replaceAll(',', '.')),
            currency: _currency,
          ),
          if (_err([ExperienceFieldError.paymentMethodsRequired]) != null)
            _errorLine(_err([ExperienceFieldError.paymentMethodsRequired])!),
        ],
      );

  Widget _pricingSection(AppLocalizations l) {
    return _section(l.uexpPrice, [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.richGold,
        title: Text(l.uexpIsFree, style: _text),
        value: _isFree,
        onChanged: (v) => setState(() => _isFree = v),
      ),
      if (!_isFree)
        Row(children: [
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<String>(
              value: _currency,
              dropdownColor: AppColors.backgroundCard,
              style: _text,
              decoration: _dec(l.uexpCurrency),
              items: [
                for (final c in kExperienceCurrencies)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) =>
                  setState(() => _currency = v ?? kExperienceCurrencies.first),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: _text,
              decoration: _dec(l.uexpPrice,
                  error: _err([ExperienceFieldError.priceInvalid])),
            ),
          ),
        ]),
      if (!_isFree) ...[
        const SizedBox(height: 12),
        // Pricing mode: per person (default) or one price per group.
        SegmentedButton<String>(
          key: const ValueKey('experience-pricing-mode'),
          segments: [
            ButtonSegment(value: 'per_person', label: Text(l.tpPerPerson)),
            ButtonSegment(value: 'per_group', label: Text(l.tpPerGroup)),
          ],
          selected: {_pricingMode},
          onSelectionChanged: (v) => setState(() => _pricingMode = v.first),
        ),
        const SizedBox(height: 6),
        Text(_pricingMode == 'per_group' ? l.tpPerGroupInfo : l.tpPerPersonInfo,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        if (_pricingMode == 'per_group') ...[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('experience-group-price'),
            controller: _groupPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: _text,
            onChanged: (_) => setState(() {}),
            decoration: _dec('${l.tpGroupPrice} ($_currency)',
                error: _err([ExperienceFieldError.priceInvalid])),
          ),
          if (_groupPrice.text.trim().isNotEmpty && int.tryParse(_maxGroup.text.trim()) != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.tpGroupPreview('$_currency${_groupPrice.text.trim()}', int.parse(_maxGroup.text.trim())),
                style: const TextStyle(color: AppColors.richGold, fontSize: 12.5),
              ),
            ),
        ],
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey('experience-weekend-toggle'),
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.richGold,
          title: Text(l.mtWeekendPriceToggle, style: _text),
          subtitle: Text(l.mtWeekendPriceInfo,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          value: _weekendOn,
          onChanged: (v) => setState(() => _weekendOn = v),
        ),
        if (_weekendOn) ...[
          TextField(
            key: const ValueKey('experience-weekend-price'),
            controller: _weekendPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: _text,
            decoration: _dec('${l.mtWeekendPrice} ($_currency)'),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (var wd = 1; wd <= 7; wd++)
              FilterChip(
                key: ValueKey('experience-weekend-day-$wd'),
                label: Text(DateFormat.E(Localizations.localeOf(context).toString()).format(DateTime(2024, 1, wd))),
                selected: _weekendDays.contains(wd),
                onSelected: (v) => setState(() => v ? _weekendDays.add(wd) : _weekendDays.remove(wd)),
              ),
          ]),
        ],
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('experience-max-per-user'),
          controller: _maxPerUser,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: _text,
          decoration: _dec(
              _pricingMode == 'per_group' ? l.tpMaxGroupBookingsPerUser : l.tpMaxTicketsPerUser,
              hint: l.tpNoLimitHint),
        ),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.warningAmber.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.warningAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.uexpPaymentDisclaimer,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ]),
      ),
    ]);
  }
}
