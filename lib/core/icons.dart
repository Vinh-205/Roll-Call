// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

import 'morphicons.dart';

class RcGlyph {
  final String name;
  const RcGlyph(this.name);
}

class RcIcons {
  static const add = RcGlyph('add');
  static const arrow_forward_ios_rounded = RcGlyph('arrow_forward_ios_rounded');
  static const auto_awesome_rounded = RcGlyph('auto_awesome_rounded');
  static const badge_rounded = RcGlyph('badge_rounded');
  static const check_circle_rounded = RcGlyph('check_circle_rounded');
  static const chevron_right = RcGlyph('chevron_right');
  static const dark_mode_rounded = RcGlyph('dark_mode_rounded');
  static const edit_calendar = RcGlyph('edit_calendar');
  static const edit_note = RcGlyph('edit_note');
  static const edit_rounded = RcGlyph('edit_rounded');
  static const error_outline_rounded = RcGlyph('error_outline_rounded');
  static const event_available_rounded = RcGlyph('event_available_rounded');
  static const fact_check_rounded = RcGlyph('fact_check_rounded');
  static const grid_view_rounded = RcGlyph('grid_view_rounded');
  static const history_rounded = RcGlyph('history_rounded');
  static const inbox_rounded = RcGlyph('inbox_rounded');
  static const light_mode_rounded = RcGlyph('light_mode_rounded');
  static const location_on_rounded = RcGlyph('location_on_rounded');
  static const lock_rounded = RcGlyph('lock_rounded');
  static const logout_rounded = RcGlyph('logout_rounded');
  static const mail_rounded = RcGlyph('mail_rounded');
  static const manage_accounts_rounded = RcGlyph('manage_accounts_rounded');
  static const mark_chat_read_rounded = RcGlyph('mark_chat_read_rounded');
  static const my_location = RcGlyph('my_location');
  static const pause = RcGlyph('pause');
  static const person_add_alt = RcGlyph('person_add_alt');
  static const person_remove_outlined = RcGlyph('person_remove_outlined');
  static const person_rounded = RcGlyph('person_rounded');
  static const pets_rounded = RcGlyph('pets_rounded');
  static const pin_rounded = RcGlyph('pin_rounded');
  static const play_arrow = RcGlyph('play_arrow');
  static const privacy_tip_rounded = RcGlyph('privacy_tip_rounded');
  static const qr_code_2_rounded = RcGlyph('qr_code_2_rounded');
  static const qr_code_scanner = RcGlyph('qr_code_scanner');
  static const qr_code_scanner_rounded = RcGlyph('qr_code_scanner_rounded');
  static const refresh = RcGlyph('refresh');
  static const restart_alt = RcGlyph('restart_alt');
  static const school_outlined = RcGlyph('school_outlined');
  static const school_rounded = RcGlyph('school_rounded');
  static const sensors = RcGlyph('sensors');
  static const sensors_rounded = RcGlyph('sensors_rounded');
  static const verified_user_rounded = RcGlyph('verified_user_rounded');
  static const visibility_off_rounded = RcGlyph('visibility_off_rounded');
  static const visibility_rounded = RcGlyph('visibility_rounded');
  static const fingerprint = RcGlyph('fingerprint');
  static const faceScan = RcGlyph('faceScan');
  static const textSize = RcGlyph('textSize');
  static const palette = RcGlyph('palette');
  static const settings = RcGlyph('settings');
  static const imageAdd = RcGlyph('imageAdd');
  static const arrowBack = RcGlyph('arrowBack');
  static const close = RcGlyph('close');
  static const menu = RcGlyph('menu');
}

class RcIcon extends StatelessWidget {
  final RcGlyph icon;
  final RcGlyph? from;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool autoContrast;
  const RcIcon(
    this.icon, {
    super.key,
    this.from,
    this.size,
    this.color,
    this.semanticLabel,
    this.autoContrast = true,
  });
  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolved =
        autoContrast &&
            color == const Color(0xffb2d5e5) &&
            Theme.of(context).brightness == Brightness.light
        ? const Color(0xff23212c)
        : color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return MorphiconsIcon(
      icon.name,
      from: from?.name,
      size: size ?? theme.size ?? 24,
      color: resolved,
      label: semanticLabel,
    );
  }
}
