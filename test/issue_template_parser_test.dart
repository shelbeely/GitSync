// Tests for lib/api/issue_template_parser.dart
// Pure-Dart unit tests that run without a device or the Rust bridge.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/issue_template_parser.dart';
import 'package:GitSync/type/issue_template.dart';

void main() {
  // ---------------------------------------------------------------------------
  // parseYamlTemplate
  // ---------------------------------------------------------------------------
  group('parseYamlTemplate', () {
    test('parses name, description, and title from YAML front-matter', () {
      const yaml = '''
name: Bug Report
description: File a bug
title: "[Bug]: "
body: []
''';
      final t = parseYamlTemplate(yaml, 'bug_report.yml');
      expect(t.name, 'Bug Report');
      expect(t.description, 'File a bug');
      expect(t.title, '[Bug]: ');
    });

    test('falls back to fileName when name is absent', () {
      const yaml = 'body: []';
      final t = parseYamlTemplate(yaml, 'my_template.yml');
      expect(t.name, 'my_template.yml');
    });

    test('description defaults to empty string when absent', () {
      const yaml = 'name: Foo\nbody: []';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.description, '');
    });

    test('title is null when absent', () {
      const yaml = 'name: Foo\nbody: []';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.title, isNull);
    });

    test('parses labels list', () {
      const yaml = '''
name: Foo
labels:
  - bug
  - enhancement
body: []
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.labels, ['bug', 'enhancement']);
    });

    test('parses assignees list', () {
      const yaml = '''
name: Foo
assignees:
  - alice
  - bob
body: []
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.assignees, ['alice', 'bob']);
    });

    test('parses empty body list', () {
      const yaml = 'name: Foo\nbody: []';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields, isEmpty);
    });

    test('parses input field', () {
      const yaml = '''
name: Foo
body:
  - type: input
    id: my_input
    attributes:
      label: "My Input"
      description: "Enter something"
      placeholder: "e.g. hello"
    validations:
      required: true
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.length, 1);
      final field = t.fields.first;
      expect(field.type, IssueTemplateFieldType.input);
      expect(field.id, 'my_input');
      expect(field.label, 'My Input');
      expect(field.description, 'Enter something');
      expect(field.placeholder, 'e.g. hello');
      expect(field.required, isTrue);
    });

    test('parses textarea field with render', () {
      const yaml = '''
name: Foo
body:
  - type: textarea
    id: logs
    attributes:
      label: "Logs"
      render: shell
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      final field = t.fields.first;
      expect(field.type, IssueTemplateFieldType.textarea);
      expect(field.render, 'shell');
    });

    test('parses dropdown field with options', () {
      const yaml = '''
name: Foo
body:
  - type: dropdown
    id: version
    attributes:
      label: "Version"
      options:
        - "1.0"
        - "2.0"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      final field = t.fields.first;
      expect(field.type, IssueTemplateFieldType.dropdown);
      expect(field.options, ['1.0', '2.0']);
    });

    test('parses checkboxes field', () {
      const yaml = '''
name: Foo
body:
  - type: checkboxes
    id: checks
    attributes:
      label: "Checks"
      options:
        - label: "I agree"
          required: true
        - label: "Optional"
          required: false
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      final field = t.fields.first;
      expect(field.type, IssueTemplateFieldType.checkboxes);
      expect(field.checkboxes, isNotNull);
      expect(field.checkboxes!.length, 2);
      expect(field.checkboxes![0].label, 'I agree');
      expect(field.checkboxes![0].required, isTrue);
      expect(field.checkboxes![1].required, isFalse);
      // options should be null for checkboxes
      expect(field.options, isNull);
    });

    test('parses markdown field', () {
      const yaml = '''
name: Foo
body:
  - type: markdown
    attributes:
      value: "**Please fill out the form**"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      final field = t.fields.first;
      expect(field.type, IssueTemplateFieldType.markdown);
      expect(field.value, '**Please fill out the form**');
    });

    test('skips fields with unknown type', () {
      const yaml = '''
name: Foo
body:
  - type: unknown_type
    attributes:
      label: "X"
  - type: input
    attributes:
      label: "Y"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.length, 1);
      expect(t.fields.first.type, IssueTemplateFieldType.input);
    });

    test('skips non-map body items', () {
      const yaml = '''
name: Foo
body:
  - "just a string"
  - type: input
    attributes:
      label: "Y"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.length, 1);
    });

    test('id falls back to label then typeStr when id absent', () {
      const yaml = '''
name: Foo
body:
  - type: input
    attributes:
      label: "My Label"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.first.id, 'My Label');
    });

    test('required defaults to false when validations absent', () {
      const yaml = '''
name: Foo
body:
  - type: input
    attributes:
      label: "X"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.first.required, isFalse);
    });

    test('parses multiple fields in order', () {
      const yaml = '''
name: Foo
body:
  - type: input
    attributes:
      label: "First"
  - type: textarea
    attributes:
      label: "Second"
  - type: markdown
    attributes:
      value: "Third"
''';
      final t = parseYamlTemplate(yaml, 'f.yml');
      expect(t.fields.length, 3);
      expect(t.fields[0].type, IssueTemplateFieldType.input);
      expect(t.fields[1].type, IssueTemplateFieldType.textarea);
      expect(t.fields[2].type, IssueTemplateFieldType.markdown);
    });
  });

  // ---------------------------------------------------------------------------
  // parseMarkdownTemplate
  // ---------------------------------------------------------------------------
  group('parseMarkdownTemplate', () {
    test('uses fileName (stripped) as name when no front-matter', () {
      const md = 'Some body text.';
      final t = parseMarkdownTemplate(md, 'bug_report.md');
      expect(t.name, 'bug_report');
    });

    test('strips .markdown extension from name', () {
      final t = parseMarkdownTemplate('body', 'feature_request.markdown');
      expect(t.name, 'feature_request');
    });

    test('body is full content when no front-matter', () {
      const md = 'Hello world';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.body, 'Hello world');
    });

    test('parses name from front-matter', () {
      const md = '''---
name: My Template
about: A template description
---
Body content here.
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.name, 'My Template');
    });

    test('parses description from about field', () {
      const md = '''---
about: Some description
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.description, 'Some description');
    });

    test('parses description from description field', () {
      const md = '''---
description: Desc here
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.description, 'Desc here');
    });

    test('parses title from front-matter', () {
      const md = '''---
title: "[Feature]: "
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.title, '[Feature]: ');
    });

    test('title is null when absent from front-matter', () {
      const md = '''---
name: Foo
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.title, isNull);
    });

    test('parses labels as YAML list', () {
      const md = '''---
labels:
  - bug
  - triage
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.labels, ['bug', 'triage']);
    });

    test('parses labels as comma-separated string', () {
      const md = '''---
labels: bug, enhancement, wontfix
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.labels, ['bug', 'enhancement', 'wontfix']);
    });

    test('parses assignees list', () {
      const md = '''---
assignees:
  - alice
  - bob
---
Body
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.assignees, ['alice', 'bob']);
    });

    test('body is trimmed content after front-matter', () {
      const md = '''---
name: Foo
---

Body content here.
''';
      final t = parseMarkdownTemplate(md, 'template.md');
      expect(t.body, 'Body content here.');
    });

    test('tolerates malformed front-matter YAML gracefully', () {
      const md = '''---
: [invalid: yaml: {{
---
Body
''';
      // Should not throw; falls back to fileName-derived name
      final t = parseMarkdownTemplate(md, 'fallback.md');
      expect(t, isNotNull);
    });

    test('produces empty labels and assignees when absent from front-matter', () {
      const md = '''---
name: Foo
---
Body
''';
      final t = parseMarkdownTemplate(md, 't.md');
      expect(t.labels, isEmpty);
      expect(t.assignees, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // buildIssueBodyFromTemplate
  // ---------------------------------------------------------------------------
  group('buildIssueBodyFromTemplate', () {
    test('emits heading and value for input field', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'title_field', label: 'Title'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'title_field': 'My title'});
      expect(body, contains('### Title'));
      expect(body, contains('My title'));
    });

    test('emits empty string for missing input value', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'x', label: 'X'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {});
      expect(body, contains('### X'));
    });

    test('wraps textarea value in code fence when render is set', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.textarea, id: 'logs', label: 'Logs', render: 'shell'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'logs': 'error output'});
      expect(body, contains('```shell'));
      expect(body, contains('error output'));
      expect(body, contains('```'));
    });

    test('does not wrap textarea in fence when render is null', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.textarea, id: 'desc', label: 'Desc'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'desc': 'plain text'});
      expect(body, contains('plain text'));
      expect(body, isNot(contains('```')));
    });

    test('does not wrap textarea in fence when render is set but value is empty', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.textarea, id: 'logs', label: 'Logs', render: 'shell'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'logs': ''});
      expect(body, isNot(contains('```')));
    });

    test('emits checkboxes with checked/unchecked state', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(
            type: IssueTemplateFieldType.checkboxes,
            id: 'boxes',
            label: 'Agree',
            checkboxes: [
              IssueTemplateCheckbox(label: 'I agree', required: true),
              IssueTemplateCheckbox(label: 'Optional', required: false),
            ],
          ),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {
        'boxes': {0: true, 1: false},
      });
      expect(body, contains('- [x] I agree'));
      expect(body, contains('- [ ] Optional'));
    });

    test('emits unchecked for checkboxes when value is null', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(
            type: IssueTemplateFieldType.checkboxes,
            id: 'boxes',
            label: 'Agree',
            checkboxes: [
              IssueTemplateCheckbox(label: 'I agree', required: false),
            ],
          ),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'boxes': <int, bool>{}});
      expect(body, contains('- [ ] I agree'));
    });

    test('skips markdown fields entirely', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.markdown, id: 'note', label: 'Note', value: 'Read me'),
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'x', label: 'X'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'x': 'hello'});
      expect(body, isNot(contains('Read me')));
      expect(body, contains('### X'));
    });

    test('handles dropdown the same as input', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(
            type: IssueTemplateFieldType.dropdown,
            id: 'version',
            label: 'Version',
            options: ['1.0', '2.0'],
          ),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'version': '2.0'});
      expect(body, contains('### Version'));
      expect(body, contains('2.0'));
    });

    test('trimRight removes trailing whitespace from result', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'x', label: 'X'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'x': 'val'});
      expect(body, isNot(endsWith('\n')));
    });

    test('returns empty string for template with no fields', () {
      final template = IssueTemplate(name: 'Test', description: '');
      final body = buildIssueBodyFromTemplate(template, {});
      expect(body, isEmpty);
    });

    test('processes multiple fields in order', () {
      final template = IssueTemplate(
        name: 'Test',
        description: '',
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'a', label: 'A'),
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'b', label: 'B'),
        ],
      );
      final body = buildIssueBodyFromTemplate(template, {'a': 'first', 'b': 'second'});
      final aIndex = body.indexOf('### A');
      final bIndex = body.indexOf('### B');
      expect(aIndex, lessThan(bIndex));
    });
  });
}
