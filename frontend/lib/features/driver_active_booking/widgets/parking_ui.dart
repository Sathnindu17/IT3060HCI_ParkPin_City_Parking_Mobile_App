import 'package:flutter/material.dart';

class ParkingStyle {
  static const navy = Color(0xFF1D3D70);
  static const orange = Color(0xFFFAA51A);
  static const background = Color(0xFFF5F7FC);
  static const text = Color(0xFF25344D);
  static const muted = Color(0xFF7C879A);
}

class ParkingCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const ParkingCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParkingStyle.navy.withAlpha(10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ParkingInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ParkingInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: ParkingStyle.navy,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ParkingStyle.text,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ParkingStyle.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ParkingPreviewLabel extends StatelessWidget {
  const ParkingPreviewLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 18),
      child: Text(
        'Design preview · no database changes',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: ParkingStyle.muted,
        ),
      ),
    );
  }
}

class ParkingFooter extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? footnote;
  final bool busy;

  const ParkingFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.footnote,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ParkingStyle.background,
        border: Border(
          top: BorderSide(color: Color(0xFFE8EDF5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: busy ? null : onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParkingStyle.orange,
                    foregroundColor: ParkingStyle.text,
                    disabledBackgroundColor:
                        const Color(0xFFE3E7EF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ParkingStyle.navy,
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                primaryLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ],
                        ),
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: busy ? null : onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ParkingStyle.navy,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFCCD7E7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      secondaryLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 12),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ParkingStyle.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}