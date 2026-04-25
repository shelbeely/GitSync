import 'dart:convert';

import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

/// Small reusable avatar component that shows initials derived from a
/// username, with a deterministic background color seeded from the
/// username string. When [email] is provided, a Gravatar (identicon
/// fallback) is loaded over the network and the initials act as the
/// loading/error fallback.
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({
    super.key,
    required this.username,
    this.email,
    this.radius = 14,
  });

  final String username;
  final String? email;
  final double radius;

  static const List<int> _hueAnchors = [340, 25, 50, 90, 140, 175, 200, 240, 280, 310];

  Color _seededColor(BuildContext context) {
    if (username.isEmpty) {
      return colours.tertiaryDark;
    }
    int hash = 0;
    for (final code in username.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    final hue = _hueAnchors[hash % _hueAnchors.length].toDouble();
    final hsl = HSLColor.fromAHSL(1.0, hue, 0.55, colours.darkMode ? 0.35 : 0.65);
    return hsl.toColor();
  }

  String get _initials {
    if (username.isEmpty) return '?';
    final parts = username.split(RegExp(r'[\s\-_.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return username.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String? _gravatarUrl() {
    final e = email?.trim().toLowerCase();
    if (e == null || e.isEmpty) return null;
    final hash = md5.convert(utf8.encode(e)).toString();
    final size = (radius * 4).round().clamp(48, 256);
    // 'd=identicon' provides a deterministic fallback if the user has no
    // Gravatar configured, which means we always get a meaningful image.
    return 'https://www.gravatar.com/avatar/$hash?s=$size&d=identicon';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _seededColor(context);
    final initialsAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: colours.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );
    final gravatarUrl = _gravatarUrl();
    if (gravatarUrl == null) return initialsAvatar;
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      foregroundImage: NetworkImage(gravatarUrl),
      child: Text(
        _initials,
        style: TextStyle(
          color: colours.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

/// M3 FilterChip-style colored status badge used for issues and pull
/// requests ("open", "closed", "merged", "draft"). Uses M3 container
/// colors for ADHD-friendly color anchoring.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.kind});

  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusKind.open => (colours.secondaryContainer, colours.onSecondaryContainer),
      StatusKind.closed => (colours.surfaceContainerHigh, colours.onSurfaceVariant),
      StatusKind.merged => (colours.primaryContainer, colours.onPrimaryContainer),
      StatusKind.draft => (colours.surfaceContainer, colours.onSurfaceVariant),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spaceXS, vertical: spaceXXXS),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.all(cornerRadiusMax)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: fg, fontSize: textXXS, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}

enum StatusKind { open, closed, merged, draft }
