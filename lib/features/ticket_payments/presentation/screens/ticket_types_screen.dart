import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';

/// Organizer: the ticket types of a paid event (General, VIP, early bird…).
/// Price per type, stock, sales window, per-person limit, hide / stop selling,
/// order. Sold counts are shown; a type with sales cannot be deleted (stop
/// selling instead) and tickets already issued keep their own price and type.
class TicketTypesScreen extends StatelessWidget {
  const TicketTypesScreen({super.key, required this.eventId, required this.currency, this.service});

  final String eventId;
  final String currency;
  final TicketPaymentsService? service;

  static Route<void> route(String eventId, String currency) =>
      MaterialPageRoute(builder: (_) => TicketTypesScreen(eventId: eventId, currency: currency));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final svc = service ?? TicketPaymentsService();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, title: Text(l.tpTicketTypes)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.richGold,
        foregroundColor: AppColors.deepBlack,
        onPressed: () => _edit(context, svc, null, 0),
        icon: const Icon(Icons.add),
        label: Text(l.tpAddTicketType),
      ),
      body: StreamBuilder<List<TicketType>>(
        stream: svc.watchTicketTypes(eventId),
        builder: (context, snap) {
          final types = snap.data;
          if (types == null) return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          if (types.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.tpTicketTypesEmpty,
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final t = types[i];
              return ListTile(
                tileColor: AppColors.backgroundCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(t.name, style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  [
                    t.price == 0 ? l.tpFree : formatTicketAmount(t.price, currency),
                    l.tpTypeSold(t.sold, t.quantity?.toString() ?? '∞'),
                    if (!t.active || t.hidden) l.tpTypeUnavailable,
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (i > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18, color: AppColors.textTertiary),
                      onPressed: () async {
                        final above = types[i - 1];
                        await svc.saveTicketType(eventId, _with(t, sortOrder: above.sortOrder));
                        await svc.saveTicketType(eventId, _with(above, sortOrder: t.sortOrder == above.sortOrder ? t.sortOrder + 1 : t.sortOrder));
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.richGold),
                    onPressed: () => _edit(context, svc, t, t.sortOrder),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  static TicketType _with(TicketType t, {int? sortOrder, bool? active}) => TicketType(
        id: t.id, name: t.name, description: t.description, price: t.price, quantity: t.quantity,
        sold: t.sold, held: t.held, salesStart: t.salesStart, salesEnd: t.salesEnd, maxPerUser: t.maxPerUser,
        hidden: t.hidden, active: active ?? t.active, sortOrder: sortOrder ?? t.sortOrder,
      );

  Future<void> _edit(BuildContext context, TicketPaymentsService svc, TicketType? t, int order) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final name = TextEditingController(text: t?.name ?? '');
    final desc = TextEditingController(text: t?.description ?? '');
    final exp = currencyExponent(currency);
    final price = TextEditingController(
        text: t == null ? '' : (exp == 0 ? '${t.price}' : (t.price / 100).toStringAsFixed(2)));
    final qty = TextEditingController(text: t?.quantity?.toString() ?? '');
    final per = TextEditingController(text: t?.maxPerUser?.toString() ?? '');
    DateTime? start = t?.salesStart;
    DateTime? end = t?.salesEnd;
    var hidden = t?.hidden ?? false;
    var active = t?.active ?? true;
    final fmt = DateFormat.yMMMd().add_Hm();

    Future<DateTime?> pick(BuildContext ctx, DateTime? initial) async {
      final d = await showDatePicker(
          context: ctx,
          initialDate: initial ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 730)));
      if (d == null || !ctx.mounted) return null;
      final tm = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()));
      return DateTime(d.year, d.month, d.day, tm?.hour ?? 0, tm?.minute ?? 0);
    }

    final save = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(t == null ? l.tpAddTicketType : l.tpEditTicketType,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, maxLength: 80, decoration: InputDecoration(labelText: l.tpTypeName)),
              TextField(controller: desc, maxLength: 300, decoration: InputDecoration(labelText: l.tpTypePerks)),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(labelText: '${l.tpTypePrice} (${currency.toUpperCase()})'),
              ),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.tpTypeQuantity, hintText: '∞'),
              ),
              TextField(
                controller: per,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.tpTypeMaxPerUser, hintText: '∞'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.tpSalesStart, style: const TextStyle(color: AppColors.textSecondary)),
                subtitle: Text(start == null ? '—' : fmt.format(start!)),
                onTap: () async {
                  final d = await pick(ctx, start);
                  setD(() => start = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.tpSalesEnd, style: const TextStyle(color: AppColors.textSecondary)),
                subtitle: Text(end == null ? '—' : fmt.format(end!)),
                onTap: () async {
                  final d = await pick(ctx, end);
                  setD(() => end = d);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.tpTypeSelling, style: const TextStyle(color: AppColors.textSecondary)),
                value: active,
                onChanged: (v) => setD(() => active = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.tpTypeHidden, style: const TextStyle(color: AppColors.textSecondary)),
                value: hidden,
                onChanged: (v) => setD(() => hidden = v),
              ),
              if (t != null && t.sold > 0)
                Text(l.tpTypeHasSalesWarning,
                    style: const TextStyle(color: AppColors.warningAmber, fontSize: 12)),
            ]),
          ),
          actions: [
            if (t != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text(t.sold > 0 ? l.tpStopSelling : l.delete,
                    style: const TextStyle(color: AppColors.errorRed)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, 'save'), child: Text(l.tpSave)),
          ],
        ),
      ),
    );
    try {
      if (save == 'delete' && t != null) {
        if (t.sold > 0 || t.held > 0) {
          await svc.saveTicketType(eventId, _with(t, active: false));
        } else {
          await svc.deleteTicketType(eventId, t.id);
        }
      } else if (save == 'save') {
        final major = double.tryParse(price.text.trim().replaceAll(',', '.')) ?? 0;
        if (name.text.trim().isEmpty) return;
        await svc.saveTicketType(
          eventId,
          TicketType(
            id: t?.id ?? '',
            name: name.text.trim(),
            description: desc.text.trim().isEmpty ? null : desc.text.trim(),
            price: toMinorUnits(major, currency),
            quantity: int.tryParse(qty.text.trim()),
            maxPerUser: int.tryParse(per.text.trim()),
            salesStart: start,
            salesEnd: end,
            hidden: hidden,
            active: active,
            sortOrder: order,
            sold: t?.sold ?? 0,
            held: t?.held ?? 0,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.tpErrGeneric)));
    } finally {
      for (final c in [name, desc, price, qty, per]) {
        c.dispose();
      }
    }
  }
}
