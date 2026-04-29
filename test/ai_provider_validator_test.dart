// Tests for lib/api/ai_provider_validator.dart
// Pure-Dart unit tests covering the synchronous helpers (string normalisation
// and provider-name conversion). The networked validation/fetch helpers are
// not exercised here because they require an HTTP layer to mock.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/ai_provider_validator.dart';

void main() {
  // ---------------------------------------------------------------------------
  // normalizeEndpoint
  // ---------------------------------------------------------------------------
  group('normalizeEndpoint', () {
    test('preserves a fully-qualified https URL', () {
      expect(normalizeEndpoint('https://api.example.com/v1'), 'https://api.example.com/v1');
    });

    test('preserves a fully-qualified http URL', () {
      expect(normalizeEndpoint('http://localhost:8080/v1'), 'http://localhost:8080/v1');
    });

    test('strips a single trailing slash', () {
      expect(normalizeEndpoint('https://api.example.com/v1/'), 'https://api.example.com/v1');
    });

    test('only strips one trailing slash, leaves an extra', () {
      // The function only strips one trailing `/`, so a double-slash leaves one behind.
      expect(normalizeEndpoint('https://api.example.com//'), 'https://api.example.com/');
    });

    test('prepends http:// when no scheme is present', () {
      expect(normalizeEndpoint('localhost:11434/v1'), 'http://localhost:11434/v1');
    });

    test('prepends http:// for a bare host', () {
      expect(normalizeEndpoint('api.example.com'), 'http://api.example.com');
    });

    test('trims surrounding whitespace before processing', () {
      expect(normalizeEndpoint('   https://api.example.com   '), 'https://api.example.com');
    });

    test('does not double-prepend http:// for an already-https URL', () {
      expect(normalizeEndpoint('https://x.com'), 'https://x.com');
    });

    test('strips trailing slash AND prepends http:// when both transformations apply', () {
      expect(normalizeEndpoint('localhost:8080/'), 'http://localhost:8080');
    });

    test('empty string becomes "http://"', () {
      // Edge case: trim leaves empty, no trailing slash, no scheme → bare prefix.
      expect(normalizeEndpoint(''), 'http://');
    });
  });

  // ---------------------------------------------------------------------------
  // aiProviderFromString  (display name → enum)
  // ---------------------------------------------------------------------------
  group('aiProviderFromString', () {
    test('Anthropic maps to AiProvider.anthropic', () {
      expect(aiProviderFromString('Anthropic'), AiProvider.anthropic);
    });

    test('OpenAI maps to AiProvider.openai', () {
      expect(aiProviderFromString('OpenAI'), AiProvider.openai);
    });

    test('Google maps to AiProvider.google', () {
      expect(aiProviderFromString('Google'), AiProvider.google);
    });

    test('Self-hosted maps to AiProvider.selfHosted', () {
      expect(aiProviderFromString('Self-hosted'), AiProvider.selfHosted);
    });

    test('null input returns null', () {
      expect(aiProviderFromString(null), isNull);
    });

    test('unknown name returns null', () {
      expect(aiProviderFromString('Cohere'), isNull);
    });

    test('match is case-sensitive — lowercase does not match', () {
      expect(aiProviderFromString('openai'), isNull);
    });

    test('empty string returns null', () {
      expect(aiProviderFromString(''), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // aiProviderToString  (enum → display name)
  // ---------------------------------------------------------------------------
  group('aiProviderToString', () {
    test('anthropic → "Anthropic"', () {
      expect(aiProviderToString(AiProvider.anthropic), 'Anthropic');
    });

    test('openai → "OpenAI"', () {
      expect(aiProviderToString(AiProvider.openai), 'OpenAI');
    });

    test('google → "Google"', () {
      expect(aiProviderToString(AiProvider.google), 'Google');
    });

    test('selfHosted → "Self-hosted"', () {
      expect(aiProviderToString(AiProvider.selfHosted), 'Self-hosted');
    });

    test('every enum value has a non-empty display name', () {
      for (final p in AiProvider.values) {
        expect(aiProviderToString(p), isNotEmpty, reason: 'Empty display for $p');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: enum → display → enum
  // ---------------------------------------------------------------------------
  group('round-trip enum ↔ display name', () {
    test('every AiProvider survives string round-trip', () {
      for (final p in AiProvider.values) {
        expect(aiProviderFromString(aiProviderToString(p)), p);
      }
    });
  });
}
