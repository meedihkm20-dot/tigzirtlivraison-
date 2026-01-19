import 'package:intl/intl.dart';

/// Utilitaire pour formater les dates de manière cohérente
class DateFormatter {
  /// Format court: "19/01/2025"
  static String formatShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format court depuis une string ISO
  static String formatShortFromString(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return formatShort(date);
    } catch (e) {
      return '';
    }
  }

  /// Format long: "19 janvier 2025"
  static String formatLong(DateTime date, {String locale = 'fr_FR'}) {
    try {
      return DateFormat.yMMMMd(locale).format(date);
    } catch (e) {
      return formatShort(date);
    }
  }

  /// Format avec heure: "19/01/2025 14:30"
  static String formatWithTime(DateTime date) {
    return '${formatShort(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format relatif: "il y a 2 heures", "hier", etc.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return formatShort(date);
    }
  }

  /// Format pour durée: "25 min", "1h 30min"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
    }
  }
}
