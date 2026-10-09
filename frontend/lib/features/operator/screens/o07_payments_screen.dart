import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/payment.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O07 – Payments & records (Figma "Operator · Payments & records").
/// Payments are simulated (no real gateway – documented deviation).
class OperatorPaymentsScreen extends StatefulWidget {
  const OperatorPaymentsScreen({super.key});

  @override
  State<OperatorPaymentsScreen> createState() => _OperatorPaymentsScreenState();
}

class _OperatorPaymentsScreenState extends State<OperatorPaymentsScreen> {
  final _svc = OperatorService.instance;
  int _tab = 0; // Today · Week · Month
  List<Payment>? _payments;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _since {
    final today = startOfToday();
    return switch (_tab) {
      0 => today,
      1 => today.subtract(const Duration(days: 6)),
      _ => DateTime(today.year, today.month, 1),
    };
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      final list = await _svc.getPayments(since: _since);
      if (mounted) setState(() => _payments = list);
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  void _changeTab(int i) {
    setState(() {
      _tab = i;
      _payments = null;
    });
    _load();
  }

  /// Copies the records as CSV so they can be pasted into Excel / Sheets.
  Future<void> _export() async {
    final list = _payments ?? [];
    if (list.isEmpty) {
      showOpSnack(context, 'No records to export for this period.');
      return;
    }
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final csv = StringBuffer('date,method,type,status,parking_fee,reservation_fee,total\n');
    for (final p in list) {
      csv.writeln([
        fmt.format(p.createdAt),
        p.method,
        p.type,
        p.status,
        p.parkingFee.toStringAsFixed(2),
        p.reservationFee.toStringAsFixed(2),
        p.total.toStringAsFixed(2),
      ].join(','));
    }
    try {
      final period = const ['today', 'week', 'month'][_tab];
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/parkpin_payments_${period}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csv.toString());
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'ParkPin payment records',
        text: '${list.length} payment records ($period)',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (_) {
      // Fall back to the clipboard if the file could not be shared.
      await Clipboard.setData(ClipboardData(text: csv.toString()));
      if (mounted) showOpSnack(context, '${list.length} records copied as CSV – paste into Excel or Sheets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _payments;
    final paid = list?.where((p) => p.isPaid).toList() ?? [];
    final collected = paid.fold(0.0, (sum, p) => sum + p.total);
    final card = paid.where((p) => p.method == 'card').fold(0.0, (sum, p) => sum + p.total);
    final wallet = collected - card;
    final refunds = (list ?? []).where((p) => !p.isPaid).length;

    return Scaffold(
      body: Column(
        children: [
          const OperatorHeader(title: 'Payments & records', subtitle: 'Cashless · auto-reconciled'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                children: [
                  OpSegmented(options: const ['Today', 'Week', 'Month'], selected: _tab, onChanged: _changeTab),
                  const SizedBox(height: 16),
                  if (_error != null)
                    OpError(message: _error!, onRetry: _load)
                  else if (list == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    OpHeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const OpIconBadge(
                                icon: Icons.receipt_long_outlined,
                                size: 42,
                                background: Color(0x26FFFFFF),
                                color: AppColors.accent,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: AppColors.successDark),
                                    SizedBox(width: 5),
                                    Text('Reconciled',
                                        style: TextStyle(
                                            fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.successDark)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          HeroCaption(['Collected today', 'Collected this week', 'Collected this month'][_tab]),
                          const SizedBox(height: 6),
                          Text(rs(collected),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 10),
                          HeroPill('${paid.length} transaction${paid.length == 1 ? '' : 's'}'),
                        ],
                      ),
                    ),
                    if (paid.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      OpCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SplitBar(card: card, wallet: wallet),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _Dot(color: AppColors.primary, label: 'Card ${rs(card)}'),
                                const SizedBox(width: 12),
                                _Dot(color: AppColors.accent, label: 'Wallet ${rs(wallet)}'),
                                const Spacer(),
                                Text('avg ${rs(collected / paid.length)}',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                              ],
                            ),
                            if (refunds > 0) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('$refunds refunded – not counted in the total',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SectionLabel('Transactions', action: list.isEmpty ? null : '${list.length} records'),
                    if (list.isEmpty)
                      const OpEmpty(icon: Icons.receipt_long_outlined, message: 'No payments in this period yet.')
                    else
                      OpCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < list.length; i++)
                              _PaymentRow(payment: list[i], showDate: _tab != 0, last: i == list.length - 1),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          OpActionBar(safeBottom: true, children: [
            OpButton(label: 'Export records', outlined: true, onPressed: list == null ? null : _export),
          ]),
        ],
      ),
    );
  }
}

/// Card vs wallet share of the money collected.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.card, required this.wallet});
  final double card;
  final double wallet;

  @override
  Widget build(BuildContext context) {
    final total = card + wallet;
    final cardFlex = total == 0 ? 1 : (card / total * 1000).round();
    final walletFlex = total == 0 ? 0 : 1000 - cardFlex;
    return Semantics(
      label: 'Card ${rs(card)}, wallet ${rs(wallet)}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: Row(
            children: [
              if (cardFlex > 0) Expanded(flex: cardFlex, child: Container(color: AppColors.primary)),
              if (walletFlex > 0) Expanded(flex: walletFlex, child: Container(color: AppColors.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.showDate, required this.last});
  final Payment payment;
  final bool showDate;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final when = showDate ? DateFormat('d MMM HH:mm').format(p.createdAt) : hhmm(p.createdAt);
    final extra = p.type == 'extension' ? ' · extension' : '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          OpIconBadge(
            icon: p.method == 'wallet' ? Icons.account_balance_wallet_outlined : Icons.credit_card,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.method == 'wallet' ? 'Wallet$extra' : 'Card$extra',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OpStyle.ink)),
                Text(when, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!p.isPaid) ...[const StatusChip('refunded', tone: ChipTone.danger), const SizedBox(width: 8)],
          Text(
            rs(p.total),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              decoration: p.isPaid ? null : TextDecoration.lineThrough,
              color: p.isPaid ? OpStyle.ink : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
