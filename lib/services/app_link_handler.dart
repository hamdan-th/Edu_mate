import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/groups/invite_group_screen.dart';

class AppLinkHandler {
  AppLinkHandler._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static Future<void> init(BuildContext context) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(context, initialUri);
      }

      _sub?.cancel();
      _sub = _appLinks.uriLinkStream.listen(
            (uri) {
          _handleUri(context, uri);
        },
      );
    } catch (_) {}
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  static void _handleUri(BuildContext context, Uri uri) {
    if (uri.scheme != 'edumate') return;
    if (uri.host != 'invite') return;

    final groupId = uri.queryParameters['groupId'];
    final code = uri.queryParameters['code'];

    if ((groupId ?? '').isEmpty || (code ?? '').isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteGroupScreen(
          groupId: groupId!,
          code: code!,
        ),
      ),
    );
  }
}