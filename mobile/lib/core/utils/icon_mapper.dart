import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icon Mapper - Chuyển đổi CupertinoIcons & Material Icons → Lucide Icons
/// Đảm bảo 100% icons trong app dùng Lucide với morphing animation support
class IconMapper {
  IconMapper._();

  /// Map CupertinoIcons to Lucide Icons
  static final Map<IconData, IconData> cupertinoToLucide = {
    // Navigation
    CupertinoIcons.chevron_forward: LucideIcons.chevronRight,
    CupertinoIcons.chevron_back: LucideIcons.chevronLeft,
    CupertinoIcons.arrow_right: LucideIcons.arrowRight,
    CupertinoIcons.arrow_left: LucideIcons.arrowLeft,
    CupertinoIcons.arrow_up_right: LucideIcons.arrowUpRight,
    CupertinoIcons.arrow_down_left: LucideIcons.arrowDownLeft,

    // Status & Alerts
    CupertinoIcons.checkmark_circle_fill: LucideIcons.checkCircle2,
    CupertinoIcons.xmark_circle_fill: LucideIcons.xCircle,
    CupertinoIcons.exclamationmark_triangle_fill: LucideIcons.alertTriangle,
    CupertinoIcons.info_circle_fill: LucideIcons.info,

    // Security & Auth
    CupertinoIcons.lock_shield_fill: LucideIcons.shieldCheck,
    CupertinoIcons.shield_lefthalf_fill: LucideIcons.shield,
    CupertinoIcons.checkmark_shield_fill: LucideIcons.shieldCheck,
    CupertinoIcons.lock_fill: LucideIcons.lock,
    CupertinoIcons.lock: LucideIcons.lock,
    CupertinoIcons.eye_fill: LucideIcons.eye,
    CupertinoIcons.eye_slash_fill: LucideIcons.eyeOff,
    CupertinoIcons.viewfinder: LucideIcons.scan,

    // Finance & Money
    CupertinoIcons.creditcard_fill: LucideIcons.creditCard,
    CupertinoIcons.money_dollar_circle_fill: LucideIcons.dollarSign,
    CupertinoIcons.money_dollar: LucideIcons.dollarSign,

    // Documents
    CupertinoIcons.doc_text_fill: LucideIcons.fileText,
    CupertinoIcons.doc_on_doc_fill: LucideIcons.copy,
    CupertinoIcons.doc_text_search: LucideIcons.fileSearch,
    CupertinoIcons.doc_text: LucideIcons.file,

    // Communication
    CupertinoIcons.phone_circle_fill: LucideIcons.phone,
    CupertinoIcons.phone_fill: LucideIcons.phone,
    CupertinoIcons.phone: LucideIcons.phone,
    CupertinoIcons.bell_fill: LucideIcons.bell,
    CupertinoIcons.bell: LucideIcons.bell,
    CupertinoIcons.mail: LucideIcons.mail,
    CupertinoIcons.mail_solid: LucideIcons.mail,

    // UI & Navigation
    CupertinoIcons.qrcode_viewfinder: LucideIcons.qrCode,
    CupertinoIcons.search: LucideIcons.search,
    CupertinoIcons.settings: LucideIcons.settings,
    CupertinoIcons.person_fill: LucideIcons.user,
    CupertinoIcons.person: LucideIcons.user,
    CupertinoIcons.house_fill: LucideIcons.home,
    CupertinoIcons.house: LucideIcons.home,
    CupertinoIcons.cloud_upload_fill: LucideIcons.cloudUpload,
    CupertinoIcons.paintbrush_fill: LucideIcons.palette,

    // Actions
    CupertinoIcons.paperplane_fill: LucideIcons.send,
    CupertinoIcons.plus_circle_fill: LucideIcons.plusCircle,
    CupertinoIcons.minus_circle_fill: LucideIcons.minusCircle,
    CupertinoIcons.pencil: LucideIcons.edit,
    CupertinoIcons.trash_fill: LucideIcons.trash2,
    CupertinoIcons.number_circle_fill: LucideIcons.hash,

    // Time & Calendar
    CupertinoIcons.clock_fill: LucideIcons.clock,
    CupertinoIcons.clock: LucideIcons.clock,
    CupertinoIcons.calendar: LucideIcons.calendar,

    // More UI
    CupertinoIcons.square_grid_2x2_fill: LucideIcons.grid,
    CupertinoIcons.gift_fill: LucideIcons.gift,
    CupertinoIcons.gift: LucideIcons.gift,
    CupertinoIcons.tickets_fill: LucideIcons.ticket,
    CupertinoIcons.chart_bar_alt_fill: LucideIcons.barChart3,
    CupertinoIcons.device_phone_portrait: LucideIcons.smartphone,

    // Building & Location
    CupertinoIcons.building_2_fill: LucideIcons.building2,
    CupertinoIcons.location_fill: LucideIcons.mapPin,

    // Media & Content
    CupertinoIcons.radiowaves_right: LucideIcons.radio,
  };

  /// Convert any icon to Lucide
  static IconData toLucide(IconData icon) {
    return cupertinoToLucide[icon] ?? LucideIcons.helpCircle;
  }

  /// Check if icon needs migration
  static bool needsMigration(IconData icon) {
    return cupertinoToLucide.containsKey(icon);
  }

  /// Get all mapped icons count
  static int get mappedIconsCount => cupertinoToLucide.length;
}
