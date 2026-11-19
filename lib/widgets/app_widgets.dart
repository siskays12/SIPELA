// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';

// ─── Design Tokens (Clean, Calm, Professional) ───
const kBrandPrimary = Color(0xFF1E3A8A); // Deep Navy
const kBrandAccent = Color(0xFF2563EB);  // Clean Royal Blue
const kSurface = Colors.white;
const kBackground = Color(0xFFF8FAFC);   // Soft neutral grey
const kBorder = Color(0xFFE2E8F0);       // Subtle divider
const kTextMain = Color(0xFF0F172A);     // Slate 900
const kTextMuted = Color(0xFF64748B);    // Slate 500
const kTextSubtle = Color(0xFF94A3B8);   // Slate 400

const kColorSuccess = Color(0xFF15803D); // Forest green
const kBgSuccess = Color(0xFFF0FDF4);
const kColorWarning = Color(0xFFB45309); // Warm amber
const kBgWarning = Color(0xFFFFFBEB);
const kColorDanger = Color(0xFFB91C1C);  // Soft red
const kBgDanger = Color(0xFFFEF2F2);
const kColorInfo = Color(0xFF0369A1);    // Soft sky
const kBgInfo = Color(0xFFF0F9FF);

// ─── Status Badge (Modern Pill with Indicator Dot) ─────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'menunggu':
        bg = kBgWarning;
        fg = kColorWarning;
        label = 'Menunggu';
        break;
      case 'disetujui':
        bg = kBgSuccess;
        fg = kColorSuccess;
        label = 'Disetujui';
        break;
      case 'ditolak':
        bg = kBgDanger;
        fg = kColorDanger;
        label = 'Ditolak';
        break;
      case 'dipinjam':
        bg = kBgInfo;
        fg = kColorInfo;
        label = 'Dipinjam';
        break;
      case 'selesai':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kondisi Badge ───────────────────────────────
class KondisiBadge extends StatelessWidget {
  final String kondisi;
  const KondisiBadge(this.kondisi, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (kondisi.toLowerCase()) {
      case 'baik':
        bg = kBgSuccess;
        fg = kColorSuccess;
        label = 'Kondisi Baik';
        break;
      case 'rusak':
        bg = kBgDanger;
        fg = kColorDanger;
        label = 'Rusak';
        break;
      case 'perawatan':
        bg = kBgWarning;
        fg = kColorWarning;
        label = 'Perawatan';
        break;
      case 'hilang':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = kondisi;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Metric Card (Elevated & Refined) ──────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? kBrandAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextMain,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ─── Clean Card Container (Modern Soft Shadow) ────
class CleanCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? color;

  const CleanCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      );
    }
    return card;
  }
}

// ─── Simple Info Line ────────────────────────────
class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const InfoLine({super.key, required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: kTextMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: kTextMain),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─── App Button (Minimal & Solid) ────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? kBrandAccent;

    Widget btn;
    if (isOutlined) {
      btn = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _content(effectiveColor),
      );
    } else {
      btn = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor,
          foregroundColor: textColor ?? Colors.white,
          elevation: 1,
          shadowColor: effectiveColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _content(textColor ?? Colors.white),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }

  Widget _content(Color fgColor) {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ─────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: kTextSubtle),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextMain),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: kTextMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Loading Widget ──────────────────────────────
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: kBrandAccent),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: const TextStyle(fontSize: 12.5, color: kTextMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── SnackBar Feedback ───────────────────────────
void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 13, color: Colors.white)),
    backgroundColor: kColorSuccess,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: const Duration(seconds: 3),
  ));
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 13, color: Colors.white)),
    backgroundColor: kColorDanger,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: const Duration(seconds: 3),
  ));
}

// ─── Helpers ─────────────────────────────────────
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final d = DateTime.parse(dateStr);
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  } catch (_) {
    return dateStr;
  }
}

String formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final d = DateTime.parse(dateStr).toLocal();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year}, $h:$m';
  } catch (_) {
    return dateStr;
  }
}

String getInitial(String name) {
  return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}
