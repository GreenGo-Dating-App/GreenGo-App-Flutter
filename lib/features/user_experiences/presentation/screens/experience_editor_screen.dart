import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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
    await Navigator.of(context).push(ExperienceSlotsScreen.route(
        experience: draft, currentUserId: widget.currentUserId));
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
              _languages.join(', '),
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
                label: Text(lang),
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
              .where((x) => q.isEmpty || x.toLowerCase().contains(q))
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
                        title: Text(lang, style: _text),
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
              child: ListView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
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
                    _languagesField(l),
                    if (_err([ExperienceFieldError.languagesRequired]) != null)
                      _errorLine(
                          _err([ExperienceFieldError.languagesRequired])!),
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
                    _bookingSettings(l),
                  ]),
                  _pricingSection(l),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
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
                      onPressed: saving
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
              ),
            ),
          );
        },
      ),
    );
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
