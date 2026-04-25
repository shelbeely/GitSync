import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/type/git_provider.dart';

enum ShowcaseFeature {
  issues(icon: FontAwesomeIcons.solidCircleDot, label: 'ISSUES', storageKey: 'issues'),
  pullRequests(icon: FontAwesomeIcons.codePullRequest, label: 'PULL REQUESTS', storageKey: 'pull_requests'),
  tags(icon: FontAwesomeIcons.tag, label: 'TAGS', storageKey: 'tags'),
  releases(icon: FontAwesomeIcons.rocket, label: 'RELEASES', storageKey: 'releases'),
  actions(icon: FontAwesomeIcons.bolt, label: 'ACTIONS', storageKey: 'actions');
  // snippets(icon: FontAwesomeIcons.code, label: 'SNIPPETS', storageKey: 'snippets');

  const ShowcaseFeature({required this.icon, required this.label, required this.storageKey});

  final FaIconData icon;
  final String label;
  final String storageKey;

  Color tintColor(bool darkMode) => switch (this) {
    ShowcaseFeature.issues => darkMode ? const Color(0xFF3E1515) : const Color(0xFFFFEBEE),
    ShowcaseFeature.pullRequests => darkMode ? const Color(0xFF0D2137) : const Color(0xFFE3F2FD),
    ShowcaseFeature.tags => darkMode ? const Color(0xFF1A1A2E) : const Color(0xFFEDE7F6),
    ShowcaseFeature.releases => darkMode ? const Color(0xFF0A2A14) : const Color(0xFFE8F5E9),
    ShowcaseFeature.actions => darkMode ? const Color(0xFF2D1B00) : const Color(0xFFFFF3E0),
  };

  Color iconColor(bool darkMode) => switch (this) {
    ShowcaseFeature.issues => darkMode ? const Color(0xFFFDA4AF) : const Color(0xFFC62828),
    ShowcaseFeature.pullRequests => darkMode ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
    ShowcaseFeature.tags => darkMode ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
    ShowcaseFeature.releases => darkMode ? const Color(0xFFA7F3D0) : const Color(0xFF2E7D32),
    ShowcaseFeature.actions => darkMode ? const Color(0xFFFFE082) : const Color(0xFFE65100),
  };

  static const defaultPinned = [ShowcaseFeature.issues, ShowcaseFeature.pullRequests];

  static ShowcaseFeature? fromStorageKey(String key) {
    for (final feature in ShowcaseFeature.values) {
      if (feature.storageKey == key) return feature;
    }
    return null;
  }

  static List<ShowcaseFeature> fromStorageKeys(List<String> keys) {
    final features = <ShowcaseFeature>[];
    for (final key in keys) {
      final feature = fromStorageKey(key);
      if (feature != null) features.add(feature);
    }
    return features;
  }

  static List<String> toStorageKeys(List<ShowcaseFeature> features) {
    return features.map((f) => f.storageKey).toList();
  }

  String labelForProvider(GitProvider? provider) => switch ((this, provider)) {
    (ShowcaseFeature.pullRequests, GitProvider.GITLAB) => 'MERGE REQUESTS',
    // (ShowcaseFeature.snippets, GitProvider.GITHUB) => 'GISTS',
    (ShowcaseFeature.actions, GitProvider.GITLAB) => 'JOBS',
    _ => label,
  };

  static List<ShowcaseFeature> availableFor(GitProvider? provider) => switch (provider) {
    GitProvider.GITEA || GitProvider.CODEBERG => values,
    _ => values,
  };
}
