// Tests for the pure-Dart helper formatDiffParts in ai_completion_service.
// (The networked aiComplete() function is not unit-tested here because it
// depends on global storage and live HTTP.)

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/ai_completion_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // formatDiffParts
  // ---------------------------------------------------------------------------
  group('formatDiffParts', () {
    test('returns empty string for empty input', () {
      expect(formatDiffParts({}), '');
    });

    test('emits "File: <path>" header for each file', () {
      final input = {
        'README.md': {'h1': 'line'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('File: README.md'));
    });

    test('replaces +++++insertion+++++ with "+ "', () {
      final input = {
        'a.dart': {'h1': '+++++insertion+++++hello'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('+ hello'));
      expect(out, isNot(contains('+++++insertion+++++')));
    });

    test('replaces -----deletion----- with "- "', () {
      final input = {
        'a.dart': {'h1': '-----deletion-----gone'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('- gone'));
      expect(out, isNot(contains('-----deletion-----')));
    });

    test('replaces both insertion and deletion markers in the same hunk', () {
      final input = {
        'a.dart': {'h1': '-----deletion-----old\n+++++insertion+++++new'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('- old'));
      expect(out, contains('+ new'));
    });

    test('emits multiple files in order', () {
      final input = <String, Map<String, String>>{
        'a.dart': {'h1': 'one'},
        'b.dart': {'h1': 'two'},
      };
      final out = formatDiffParts(input);
      final aIdx = out.indexOf('File: a.dart');
      final bIdx = out.indexOf('File: b.dart');
      expect(aIdx, greaterThanOrEqualTo(0));
      expect(bIdx, greaterThan(aIdx));
    });

    test('emits multiple hunks for the same file', () {
      final input = {
        'a.dart': {'h1': 'first', 'h2': 'second'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('first'));
      expect(out, contains('second'));
    });

    test('respects maxChars and stops adding files once reached', () {
      final big = 'x' * 5000;
      final input = <String, Map<String, String>>{
        'a.dart': {'h1': big},
        'b.dart': {'h1': 'should be excluded'},
      };
      final out = formatDiffParts(input, maxChars: 1000);
      expect(out.length, lessThanOrEqualTo(1100)); // small overhead for headers
      expect(out, isNot(contains('File: b.dart')));
    });

    test('truncates a single hunk when it overflows the remaining budget', () {
      final big = 'y' * 5000;
      final input = {
        'a.dart': {'h1': big},
      };
      final out = formatDiffParts(input, maxChars: 200);
      expect(out, contains('File: a.dart'));
      // Output should be reasonably bounded near maxChars (allow a small slack
      // for the file header + final newlines that the buffer adds after the loop).
      expect(out.length, lessThanOrEqualTo(400));
    });

    test('default maxChars is 4000', () {
      final input = {
        'a.dart': {'h1': 'z' * 10000},
      };
      final out = formatDiffParts(input);
      // Default cap should keep it well under the input size.
      expect(out.length, lessThan(5000));
    });

    test('preserves arbitrary non-marker text verbatim', () {
      final input = {
        'a.dart': {'h1': 'some unchanged context line'},
      };
      final out = formatDiffParts(input);
      expect(out, contains('some unchanged context line'));
    });
  });
}
