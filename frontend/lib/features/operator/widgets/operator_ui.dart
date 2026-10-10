import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/models/booking.dart';

/// Reusable pieces of the operator UI, built from the Figma frames
/// (navy header, white cards with 0.5px border, segmented tabs, chips, nav).

final NumberFormat _money = NumberFormat('#,##0');
String rs(num v) => 'Rs ${_money.format(v)}';
String hhmm(DateTime t) => DateFormat('HH:mm').format(t);
String hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';

final RegExp _codePattern = RegExp(r'PP-[A-Z0-9]{4,10}');

/// Pulls "PP-XXXXXX" out of whatever the QR or text field contains.
/// Staff can also type just the 6 characters (e.g. "8A41C2") – the "PP-" is added.
String extractBookingCode(String raw) {
  final upper = raw.trim().toUpperCase().replaceAll(' ', '');
  final match = _codePattern.firstMatch(upper)?.group(0);
  if (match != null) return match;
  if (RegExp(r'^[A-Z0-9]{4,10}$').hasMatch(upper)) return 'PP-$upper';
  return upper;
}

/// Minutes a pending booking may be late before it is flagged.
const int lateGraceMinutes = 15;

/// True when a pending booking's arrival time passed more than the grace period ago.
bool isLate(Booking b, [DateTime? now]) =>
    b.status == Booking.reserved &&
    (now ?? DateTime.now()).difference(b.startTime).inMinutes > lateGraceMinutes;

/// "in 20 min", "in 2 h 5 min", "now", "12 min late" – for pending arrivals.
String arrivalLabel(DateTime start, [DateTime? now]) {
  final mins = start.difference(now ?? DateTime.now()).inMinutes;
  if (mins.abs() <= 2) return 'now';
  if (mins < 0) {
    final over = -mins;
    return over < 60 ? '$over min late' : '${over ~/ 60} h ${over % 60} min late';
  }
  if (mins < 60) return 'in $mins min';
  final rest = mins % 60;
  return rest == 0 ? 'in ${mins ~/ 60} h' : 'in ${mins ~/ 60} h $rest min';
}

/// Light vibration on taps that change something (helps staff who look away from the screen).
void tapFeedback() => HapticFeedback.selectionClick();

/// "Now", "5m", "3h", "2d" – used in notifications.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  return '${d.inDays}d';
}

bool isToday(DateTime t) {
  final n = DateTime.now();
  return t.year == n.year && t.month == n.month && t.day == n.day;
}

DateTime startOfToday() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

void showOpSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.textPrimary,
    ));
}

/// Short status text + colour for a booking, used on O04, O05 and O08.
(String, ChipTone) bookingStatus(Booking b) => switch (b.status) {
      Booking.reserved => b.hasBay ? ('hold', ChipTone.neutral) : ('needs bay', ChipTone.warning),
      Booking.active => ('checked in', ChipTone.success),
      Booking.completed => ('completed', ChipTone.neutral),
      Booking.cancelled => ('cancelled', ChipTone.danger),
      Booking.expired => ('no-show', ChipTone.danger),
      _ => (b.status, ChipTone.neutral),
    };

/// Asks the user to confirm an action. Returns true when they agree.
Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String confirm = 'Confirm', bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OpStyle.ink)),
      content: Text(message, style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: TextStyle(color: danger ? AppColors.danger : AppColors.primary)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Visual tokens shared by the operator screens (same family as the driver
/// screens: bold navy headings, soft shadows, rounded 18–20 px cards).
class OpStyle {
  OpStyle._();

  static const Color ink = Color(0xFF14284B); // headings on light backgrounds
  static const Color navyLight = Color(0xFF2E5A99); // gradient end
  static const Color tileBg = Color(0xFFEEF2F9); // icon tiles
  static const double radius = 18;

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x141B3B6F), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, navyLight],
  );

  static const TextStyle pageTitle = TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: ink, height: 1.2);
  static const TextStyle pageSubtitle = TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35);
  static const TextStyle sectionTitle = TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: ink);
  static const TextStyle cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink);
  static const TextStyle body = TextStyle(fontSize: 14.5, color: AppColors.textPrimary);
  static const TextStyle muted = TextStyle(fontSize: 13, color: AppColors.textMuted);
}

/// Navy header: back arrow and title on one row, subtitle underneath.
class OperatorHeader extends StatelessWidget {
  const OperatorHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, MediaQuery.paddingOf(context).top + 10, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (canPop)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.only(top: 12, left: canPop ? 12 : 0),
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }
}

/// White icon button for the right side of the header.
class HeaderAction extends StatelessWidget {
  const HeaderAction({super.key, required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

/// Big bold title + grey line at the top of a screen body ("Your parking history").
class OpPageIntro extends StatelessWidget {
  const OpPageIntro({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: OpStyle.pageTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: OpStyle.pageSubtitle),
          ],
        ],
      ),
    );
  }
}

/// White rounded card with a soft shadow.
class OpCard extends StatelessWidget {
  const OpCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = OpStyle.radius,
    this.onTap,
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.6),
        boxShadow: OpStyle.shadow,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// Navy gradient summary card ("TOTAL PAID Rs 250").
class OpHeroCard extends StatelessWidget {
  const OpHeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: OpStyle.heroGradient,
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x331B3B6F), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// Small spaced-out caption used inside hero cards ("EXTENSION SUMMARY").
class HeroCaption extends StatelessWidget {
  const HeroCaption(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
        ],
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// Translucent pill on a hero card ("+30 minutes of parking").
class HeroPill extends StatelessWidget {
  const HeroPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}

/// Rounded square with an icon or a letter ("P").
class OpIconBadge extends StatelessWidget {
  const OpIconBadge({
    super.key,
    this.icon,
    this.letter,
    this.size = 44,
    this.background = OpStyle.tileBg,
    this.color = AppColors.primary,
  });
  final IconData? icon;
  final String? letter;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
      alignment: Alignment.center,
      child: letter != null
          ? Text(letter!,
              style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w800, color: color))
          : Icon(icon ?? Icons.local_parking, size: size * 0.5, color: color),
    );
  }
}

/// Pill tabs in a soft track. "Pending (3)" shows 3 as a small count badge.
class OpSegmented extends StatelessWidget {
  const OpSegmented({super.key, required this.options, required this.selected, required this.onChanged});

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  static final RegExp _count = RegExp(r'^(.*?)\s*\((\d+)\)$');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE6ECF5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: _segment(i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _segment(int i) {
    final active = i == selected;
    final m = _count.firstMatch(options[i]);
    final text = m?.group(1) ?? options[i];
    final count = m?.group(2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active ? const [BoxShadow(color: Color(0x261B3B6F), blurRadius: 8, offset: Offset(0, 3))] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withValues(alpha: 0.22) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green "Live" pill with a dot.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.text = 'Live'});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successDark)),
        ],
      ),
    );
  }
}

enum ChipTone { neutral, success, warning, danger }

/// Status pill ("Hold", "Checked in", "No-show" …).
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = ChipTone.neutral});
  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (const Color(0xFFEEF1F6), const Color(0xFF55627A)),
      ChipTone.success => (AppColors.successBg, AppColors.successDark),
      ChipTone.warning => (const Color(0xFFFFF1DA), const Color(0xFFA9620A)),
      ChipTone.danger => (AppColors.dangerBg, AppColors.danger),
    };
    final text = label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// Friendly message when a list is empty.
class OpEmpty extends StatelessWidget {
  const OpEmpty({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: OpStyle.tileBg, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.primary.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Error box with a retry button (and a way back to login if the session ended).
class OpError extends StatelessWidget {
  const OpError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final sessionEnded = message.contains('log in again');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_outlined, size: 34, color: AppColors.danger),
            ),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: sessionEnded
                  ? OpButton(
                      label: 'Log in',
                      onPressed: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(OperatorRoutes.login, (_) => false),
                    )
                  : OpButton(label: 'Try again', outlined: true, onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label / value row inside a card ("Current end time   9:44 PM").
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OpStyle.ink)),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation: Dashboard · Bookings · Gate check · Profile.
/// The dashboard stays at the bottom of the stack so Android "back" works.
class OperatorBottomNav extends StatelessWidget {
  const OperatorBottomNav({super.key, required this.currentIndex});
  final int currentIndex; // -1 = none highlighted

  static const _items = [
    (Icons.grid_view_rounded, 'Dashboard', OperatorRoutes.dashboard),
    (Icons.calendar_today_outlined, 'Bookings', OperatorRoutes.bookings),
    (Icons.qr_code_scanner, 'Gate check', OperatorRoutes.gate),
    (Icons.person_outline, 'Profile', OperatorRoutes.profile),
  ];

  void _go(BuildContext context, int i) {
    final nav = Navigator.of(context);
    final route = _items[i].$3;
    if (ModalRoute.of(context)?.settings.name == route) return;
    if (i == 0) {
      nav.popUntil(ModalRoute.withName(OperatorRoutes.dashboard));
    } else {
      nav.pushNamedAndRemoveUntil(route, ModalRoute.withName(OperatorRoutes.dashboard));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        boxShadow: [BoxShadow(color: Color(0x0D1B3B6F), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == currentIndex,
                    label: _items[i].$2,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => _go(context, i),
                      radius: 34,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _items[i].$1,
                              size: 25,
                              color: i == currentIndex
                                  ? AppColors.primary
                                  : AppColors.textMuted.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 4),
                            // Text labels under icons: icon-only navigation is harder to learn.
                            Text(
                              _items[i].$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                                color: i == currentIndex ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom area that holds the main action button(s).
class OpActionBar extends StatelessWidget {
  const OpActionBar({super.key, required this.children, this.safeBottom = false});
  final List<Widget> children;
  final bool safeBottom; // true on screens without a bottom nav

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
    return safeBottom ? SafeArea(top: false, child: content) : content;
  }
}

/// Big amber action button (or white outlined), like "Confirm extension · Rs 50 →".
class OpButton extends StatelessWidget {
  const OpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fg = outlined ? AppColors.primary : AppColors.onAccent;
    final child = loading
        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
              if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 20, color: fg)],
            ],
          );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: outlined
          ? OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: enabled ? AppColors.primary : AppColors.border, width: 1.4),
                shape: shape,
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                elevation: enabled ? 3 : 0,
                shadowColor: AppColors.accent.withValues(alpha: 0.45),
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}

/// Text field with a bold label above it (larger than the base Figma input).
class OpField extends StatelessWidget {
  const OpField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffix,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final IconData? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OpStyle.ink)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 15.5, color: AppColors.textPrimary),
          decoration: opInputDecoration(hint: hint, suffix: suffix, prefixIcon: prefixIcon),
        ),
      ],
    );
  }
}

/// Rounded white input look shared by OpField and the search boxes.
InputDecoration opInputDecoration({String? hint, Widget? suffix, IconData? prefixIcon}) {
  OutlineInputBorder border(Color c, double w) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14.5, color: AppColors.textMuted),
    filled: true,
    fillColor: Colors.white,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22, color: AppColors.textMuted),
    suffixIcon: suffix,
    enabledBorder: border(AppColors.border, 1),
    focusedBorder: border(AppColors.primary, 1.6),
    errorBorder: border(AppColors.danger, 1),
    focusedErrorBorder: border(AppColors.danger, 1.6),
    errorStyle: const TextStyle(fontSize: 12.5),
  );
}

/// Section heading above a group of cards ("Upcoming parking   See all").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: OpStyle.sectionTitle)),
          if (action != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(action!,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft coloured card for warnings and tips ("Reminder adjusted").
class OpNotice extends StatelessWidget {
  const OpNotice({super.key, required this.icon, required this.text, this.tone = ChipTone.warning, this.onTap});
  final IconData icon;
  final String text;
  final ChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (const Color(0xFFEEF1F6), const Color(0xFF55627A)),
      ChipTone.success => (AppColors.successBg, AppColors.successDark),
      ChipTone.warning => (const Color(0xFFFFF4E2), const Color(0xFF9A5A07)),
      ChipTone.danger => (AppColors.dangerBg, AppColors.danger),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: fg)),
              ),
              if (onTap != null) Icon(Icons.chevron_right, size: 22, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
