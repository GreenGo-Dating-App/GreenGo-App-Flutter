import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../ticket_payments/domain/ticket_payments.dart' show formatTicketAmount;
import '../../data/billing_profile_repository.dart';
import '../../data/finance_documents_repository.dart';
import '../../domain/finance_document.dart';
import '../bloc/finance_documents_cubit.dart';
import '../widgets/billing_status.dart';

/// Profile > Business > Invoices: the seller's GreenGo fee invoices (+ credit
/// notes) and monthly statements, with PDF download. The ticket service fee
/// is paid by the seller; the same documents are e-mailed on the 2nd of each
/// month.
class FinanceDocumentsScreen extends StatefulWidget {
  const FinanceDocumentsScreen({this.repository, this.billingRepository, super.key});

  /// Injectable for tests.
  final FinanceDocumentsRepository? repository;
  final BillingProfileRepository? billingRepository;

  @override
  State<FinanceDocumentsScreen> createState() => _FinanceDocumentsScreenState();
}

class _FinanceDocumentsScreenState extends State<FinanceDocumentsScreen> {
  late final FinanceDocumentsRepository _repo = widget.repository ?? FinanceDocumentsRepository();
  late final FinanceDocumentsCubit _invoices = FinanceDocumentsCubit(_repo, FinanceDocKind.invoices)..load();
  late final FinanceDocumentsCubit _statements = FinanceDocumentsCubit(_repo, FinanceDocKind.statements)..load();

  @override
  void dispose() {
    _invoices.close();
    _statements.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => SafeNavigation.pop(context),
          ),
          title: Text(
            l10n.financeDocsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(text: l10n.financeDocsTabInvoices),
              Tab(text: l10n.financeDocsTabStatements),
            ],
          ),
        ),
        // Shortcut to Invoice details while they are missing.
        body: BillingStatusScope(
          repository: widget.billingRepository,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(AppDimensions.paddingL, AppDimensions.paddingL, AppDimensions.paddingL, 0),
                child: BillingRequiredBanner(compact: true),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _DocsList(cubit: _invoices, repository: _repo),
                    _DocsList(cubit: _statements, repository: _repo, statements: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: its own cubit (two cubits of the same type, so passed explicitly).
class _DocsList extends StatefulWidget {
  const _DocsList({required this.cubit, required this.repository, this.statements = false});

  final FinanceDocumentsCubit cubit;
  final FinanceDocumentsRepository repository;
  final bool statements;

  @override
  State<_DocsList> createState() => _DocsListState();
}

class _DocsListState extends State<_DocsList> with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  String? _downloadingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _cubit.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  FinanceDocumentsCubit get _cubit => widget.cubit;

  Future<void> _download(FinanceDocument doc) async {
    if (_downloadingId != null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloadingId = doc.id);
    try {
      final pdf = await widget.repository.pdf(doc);
      // Mobile: the share sheet (save to Files / Drive / e-mail…).
      // Web: share_plus downloads the file when Web Share can't take files.
      await Share.shareXFiles(
        [XFile.fromData(pdf.bytes, mimeType: 'application/pdf', name: pdf.filename)],
        fileNameOverrides: [pdf.filename],
      );
    } catch (e) {
      debugPrint('[FinanceDocs] pdf ${doc.id} failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeDocsDownloadFailed)));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _openNfse(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<FinanceDocumentsCubit, FinanceDocumentsState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.status == FinanceDocsStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
        }
        if (state.status == FinanceDocsStatus.failed) {
          return _Message(
            icon: Icons.cloud_off,
            text: l10n.financeDocsError,
            action: TextButton(onPressed: _cubit.load, child: Text(l10n.financeDocsRetry)),
          );
        }
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            l10n.financeDocsFeeNote,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13, height: 1.4),
          ),
        );
        return RefreshIndicator(
          color: AppColors.richGold,
          onRefresh: _cubit.load,
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  children: [
                    header,
                    const SizedBox(height: 40),
                    _Message(
                      icon: widget.statements ? Icons.summarize_outlined : Icons.receipt_long_outlined,
                      text: widget.statements ? l10n.financeDocsEmptyStatements : l10n.financeDocsEmptyInvoices,
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  itemCount: state.items.length + 2,
                  separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 10),
                  itemBuilder: (context, i) {
                    if (i == 0) return header;
                    if (i == state.items.length + 1) {
                      if (state.loadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
                        );
                      }
                      if (state.loadMoreFailed) {
                        return Center(child: TextButton(onPressed: _cubit.loadMore, child: Text(l10n.financeDocsRetry)));
                      }
                      return const SizedBox(height: 24);
                    }
                    final doc = state.items[i - 1];
                    return _DocTile(
                      doc: doc,
                      downloading: _downloadingId == doc.id,
                      onDownload: () => _download(doc),
                      onOpenNfse: doc.nfse?.url != null ? () => _openNfse(doc.nfse!.url!) : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.downloading, required this.onDownload, this.onOpenNfse});

  final FinanceDocument doc;
  final bool downloading;
  final VoidCallback onDownload;
  final VoidCallback? onOpenNfse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = doc.issuedAt == null ? null : DateFormat.yMMMd(locale).format(doc.issuedAt!.toLocal());
    final isStatement = doc.kind == FinanceDocKind.statements;

    final chips = <Widget>[
      if (!isStatement)
        _Chip(
          label: doc.isCreditNote ? l10n.financeDocsCreditNote : l10n.financeDocsInvoice,
          color: doc.isCreditNote ? AppColors.infoBlue : AppColors.richGold,
        ),
      if (doc.isVoid) _Chip(label: l10n.financeDocsVoid, color: AppColors.errorRed),
      if (doc.nfse != null && !isStatement)
        _Chip(
          label: doc.nfse!.isAuthorized && (doc.nfse!.number ?? '').isNotEmpty
              ? l10n.financeDocsNfseNumber(doc.nfse!.number!)
              : doc.nfse!.isCancelled
                  ? l10n.financeDocsNfseCancelled
                  : l10n.financeDocsNfsePending,
          color: doc.nfse!.isAuthorized ? AppColors.successGreen : AppColors.warningAmber,
        ),
      if (doc.isTest) _Chip(label: l10n.financeDocsTest, color: AppColors.errorRed),
    ];

    final amounts = isStatement
        ? [
            for (final l in doc.lines)
              l10n.financeDocsNet(formatTicketAmount(l.net, l.currency, locale: locale)),
          ]
        : [
            if (doc.total != null && doc.currency != null)
              formatTicketAmount(doc.total!, doc.currency!, locale: locale),
          ];

    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: downloading ? null : onDownload,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isStatement ? Icons.summarize_outlined : Icons.receipt_long_outlined,
                color: AppColors.richGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.number,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (doc.period != null) l10n.financeDocsPeriod(doc.period!),
                        if (date != null) l10n.financeDocsIssued(date),
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                    ),
                    if (amounts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final a in amounts)
                        Text(a, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: chips),
                    ],
                    if (onOpenNfse != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: onOpenNfse,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.richGold),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(l10n.financeDocsOpenNfse),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              downloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.richGold),
                    )
                  : IconButton(
                      tooltip: l10n.financeDocsDownload,
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, color: AppColors.richGold),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textTertiary, size: 44),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              if (action != null) ...[const SizedBox(height: 8), action!],
            ],
          ),
        ),
      );
}
