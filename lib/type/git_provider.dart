enum GitProvider {
  GITHUB,
  HTTPS,
  SSH;

  bool get isOAuthProvider => this == GITHUB;

  String? commitUrl(String webBaseUrl, String sha) => switch (this) {
    GITHUB => '$webBaseUrl/commit/$sha',
    HTTPS || SSH => null,
  };
}
