// Tests for pure type models: issue_template, issue_detail, pr_detail, etc.
// Pure-Dart unit tests that run without a device or the Rust bridge.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/type/issue_template.dart';
import 'package:GitSync/type/issue.dart';
import 'package:GitSync/type/issue_detail.dart';
import 'package:GitSync/type/pull_request.dart';
import 'package:GitSync/type/pr_detail.dart';
import 'package:GitSync/type/release.dart';
import 'package:GitSync/type/tag.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:GitSync/type/agent_message.dart';

void main() {
  // ---------------------------------------------------------------------------
  // CreateIssueResult
  // ---------------------------------------------------------------------------
  group('CreateIssueResult', () {
    test('isSuccess is true on successful result', () {
      const r = CreateIssueResult(number: 42, htmlUrl: 'https://github.com/x/y/issues/42');
      expect(r.isSuccess, isTrue);
      expect(r.error, isNull);
      expect(r.number, 42);
    });

    test('isSuccess is false on failure result', () {
      const r = CreateIssueResult.failure('Something went wrong');
      expect(r.isSuccess, isFalse);
      expect(r.error, 'Something went wrong');
      expect(r.number, -1);
      expect(r.htmlUrl, isNull);
    });

    test('successful result stores htmlUrl', () {
      const url = 'https://github.com/x/y/issues/1';
      const r = CreateIssueResult(number: 1, htmlUrl: url);
      expect(r.htmlUrl, url);
    });
  });

  // ---------------------------------------------------------------------------
  // IssueTemplate
  // ---------------------------------------------------------------------------
  group('IssueTemplate', () {
    test('defaults: empty labels, assignees, fields; null title and body', () {
      const t = IssueTemplate(name: 'T', description: 'D');
      expect(t.title, isNull);
      expect(t.body, isNull);
      expect(t.labels, isEmpty);
      expect(t.assignees, isEmpty);
      expect(t.fields, isEmpty);
    });

    test('stores all provided values', () {
      final t = IssueTemplate(
        name: 'Bug',
        description: 'Desc',
        title: '[Bug]',
        labels: ['bug'],
        assignees: ['alice'],
        fields: [
          IssueTemplateField(type: IssueTemplateFieldType.input, id: 'id', label: 'Label'),
        ],
        body: 'Body text',
      );
      expect(t.name, 'Bug');
      expect(t.description, 'Desc');
      expect(t.title, '[Bug]');
      expect(t.labels, ['bug']);
      expect(t.assignees, ['alice']);
      expect(t.fields.length, 1);
      expect(t.body, 'Body text');
    });
  });

  // ---------------------------------------------------------------------------
  // IssueTemplateField
  // ---------------------------------------------------------------------------
  group('IssueTemplateField', () {
    test('required defaults to false', () {
      const f = IssueTemplateField(type: IssueTemplateFieldType.input, id: 'x', label: 'X');
      expect(f.required, isFalse);
    });

    test('all nullable fields default to null', () {
      const f = IssueTemplateField(type: IssueTemplateFieldType.input, id: 'x', label: 'X');
      expect(f.description, isNull);
      expect(f.placeholder, isNull);
      expect(f.value, isNull);
      expect(f.options, isNull);
      expect(f.checkboxes, isNull);
      expect(f.render, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // IssueTemplateCheckbox
  // ---------------------------------------------------------------------------
  group('IssueTemplateCheckbox', () {
    test('stores label and required correctly', () {
      const cb = IssueTemplateCheckbox(label: 'Agree', required: true);
      expect(cb.label, 'Agree');
      expect(cb.required, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // IssueDetail
  // ---------------------------------------------------------------------------
  group('IssueDetail', () {
    IssueDetail makeDetail({ViewerPermission permission = ViewerPermission.read}) {
      return IssueDetail(
        id: '1',
        title: 'Test Issue',
        number: 1,
        isOpen: true,
        authorUsername: 'user',
        createdAt: DateTime(2024),
        body: 'body',
        viewerPermission: permission,
      );
    }

    group('canComment', () {
      test('returns true for admin permission', () {
        expect(makeDetail(permission: ViewerPermission.admin).canComment, isTrue);
      });

      test('returns true for write permission', () {
        expect(makeDetail(permission: ViewerPermission.write).canComment, isTrue);
      });

      test('returns true for read permission', () {
        expect(makeDetail(permission: ViewerPermission.read).canComment, isTrue);
      });

      test('returns true for maintain permission', () {
        expect(makeDetail(permission: ViewerPermission.maintain).canComment, isTrue);
      });

      test('returns true for triage permission', () {
        expect(makeDetail(permission: ViewerPermission.triage).canComment, isTrue);
      });

      test('returns false for none permission', () {
        expect(makeDetail(permission: ViewerPermission.none).canComment, isFalse);
      });
    });

    group('canWrite', () {
      test('returns true for admin', () {
        expect(makeDetail(permission: ViewerPermission.admin).canWrite, isTrue);
      });

      test('returns true for maintain', () {
        expect(makeDetail(permission: ViewerPermission.maintain).canWrite, isTrue);
      });

      test('returns true for write', () {
        expect(makeDetail(permission: ViewerPermission.write).canWrite, isTrue);
      });

      test('returns true for triage', () {
        expect(makeDetail(permission: ViewerPermission.triage).canWrite, isTrue);
      });

      test('returns false for read', () {
        expect(makeDetail(permission: ViewerPermission.read).canWrite, isFalse);
      });

      test('returns false for none', () {
        expect(makeDetail(permission: ViewerPermission.none).canWrite, isFalse);
      });
    });

    group('copyWith', () {
      test('copyWith without args returns equivalent object', () {
        final detail = makeDetail();
        final copy = detail.copyWith();
        expect(copy.id, detail.id);
        expect(copy.title, detail.title);
        expect(copy.number, detail.number);
        expect(copy.isOpen, detail.isOpen);
        expect(copy.body, detail.body);
      });

      test('copyWith overrides specified fields', () {
        final detail = makeDetail();
        final copy = detail.copyWith(title: 'New Title', isOpen: false);
        expect(copy.title, 'New Title');
        expect(copy.isOpen, isFalse);
        expect(copy.id, detail.id); // unchanged
      });

      test('copyWith overrides viewerPermission', () {
        final detail = makeDetail(permission: ViewerPermission.read);
        final copy = detail.copyWith(viewerPermission: ViewerPermission.admin);
        expect(copy.viewerPermission, ViewerPermission.admin);
        expect(copy.canWrite, isTrue);
      });

      test('copyWith with labels replaces labels list', () {
        final detail = makeDetail();
        final label = IssueLabel(name: 'bug', color: 'ff0000');
        final copy = detail.copyWith(labels: [label]);
        expect(copy.labels.length, 1);
        expect(copy.labels.first.name, 'bug');
      });
    });

    test('default viewerPermission is read', () {
      final detail = IssueDetail(
        id: '1',
        title: 'T',
        number: 1,
        isOpen: true,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        body: 'b',
      );
      expect(detail.viewerPermission, ViewerPermission.read);
    });

    test('default labels, reactions, comments are empty', () {
      final detail = IssueDetail(
        id: '1',
        title: 'T',
        number: 1,
        isOpen: true,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        body: 'b',
      );
      expect(detail.labels, isEmpty);
      expect(detail.reactions, isEmpty);
      expect(detail.comments, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // PrDetail
  // ---------------------------------------------------------------------------
  group('PrDetail', () {
    PrDetail makePrDetail({ViewerPermission permission = ViewerPermission.read}) {
      return PrDetail(
        id: 'pr1',
        title: 'My PR',
        body: '',
        authorUsername: 'user',
        baseBranch: 'main',
        headBranch: 'feature',
        headRepoOwner: 'user',
        number: 1,
        additions: 10,
        deletions: 5,
        changedFileCount: 2,
        state: PrState.open,
        createdAt: DateTime(2024),
        viewerPermission: permission,
      );
    }

    test('canComment returns true when permission is not none', () {
      expect(makePrDetail(permission: ViewerPermission.read).canComment, isTrue);
      expect(makePrDetail(permission: ViewerPermission.admin).canComment, isTrue);
    });

    test('canComment returns false when permission is none', () {
      expect(makePrDetail(permission: ViewerPermission.none).canComment, isFalse);
    });

    group('copyWith', () {
      test('copyWith without args preserves all fields', () {
        final pr = makePrDetail();
        final copy = pr.copyWith();
        expect(copy.id, pr.id);
        expect(copy.title, pr.title);
        expect(copy.number, pr.number);
        expect(copy.state, pr.state);
        expect(copy.additions, pr.additions);
        expect(copy.deletions, pr.deletions);
      });

      test('copyWith overrides title and state', () {
        final pr = makePrDetail();
        final copy = pr.copyWith(title: 'Updated', state: PrState.merged);
        expect(copy.title, 'Updated');
        expect(copy.state, PrState.merged);
        expect(copy.id, pr.id);
      });

      test('copyWith overrides overallCheckStatus', () {
        final pr = makePrDetail();
        final copy = pr.copyWith(overallCheckStatus: CheckStatus.success);
        expect(copy.overallCheckStatus, CheckStatus.success);
      });

      test('copyWith overrides viewerPermission and affects canComment', () {
        final pr = makePrDetail(permission: ViewerPermission.none);
        expect(pr.canComment, isFalse);
        final copy = pr.copyWith(viewerPermission: ViewerPermission.write);
        expect(copy.canComment, isTrue);
      });
    });

    test('default overallCheckStatus is none', () {
      expect(makePrDetail().overallCheckStatus, CheckStatus.none);
    });

    test('default viewerPermission is read', () {
      final pr = PrDetail(
        id: 'p',
        title: 'T',
        body: '',
        authorUsername: 'u',
        baseBranch: 'main',
        headBranch: 'feat',
        headRepoOwner: 'u',
        number: 1,
        additions: 0,
        deletions: 0,
        changedFileCount: 0,
        state: PrState.open,
        createdAt: DateTime(2024),
      );
      expect(pr.viewerPermission, ViewerPermission.read);
    });

    test('all list fields default to empty', () {
      final pr = makePrDetail();
      expect(pr.labels, isEmpty);
      expect(pr.reactions, isEmpty);
      expect(pr.timelineItems, isEmpty);
      expect(pr.commits, isEmpty);
      expect(pr.checkRuns, isEmpty);
      expect(pr.changedFiles, isEmpty);
      expect(pr.reviews, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Issue
  // ---------------------------------------------------------------------------
  group('Issue', () {
    test('stores all required fields', () {
      final issue = Issue(
        title: 'Test',
        number: 5,
        isOpen: true,
        authorUsername: 'dev',
        createdAt: DateTime(2024),
        commentCount: 3,
        labels: const [],
      );
      expect(issue.number, 5);
      expect(issue.isOpen, isTrue);
      expect(issue.commentCount, 3);
    });

    test('linkedPrCount defaults to 0', () {
      final issue = Issue(
        title: 'X',
        number: 1,
        isOpen: false,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        commentCount: 0,
        labels: const [],
      );
      expect(issue.linkedPrCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // IssueLabel
  // ---------------------------------------------------------------------------
  group('IssueLabel', () {
    test('color can be null', () {
      const label = IssueLabel(name: 'triage');
      expect(label.color, isNull);
    });

    test('stores name and color', () {
      const label = IssueLabel(name: 'bug', color: 'ff0000');
      expect(label.name, 'bug');
      expect(label.color, 'ff0000');
    });
  });

  // ---------------------------------------------------------------------------
  // IssueReaction
  // ---------------------------------------------------------------------------
  group('IssueReaction', () {
    test('viewerHasReacted defaults to false', () {
      const r = IssueReaction(content: '+1', count: 5);
      expect(r.viewerHasReacted, isFalse);
    });

    test('awardId defaults to null', () {
      const r = IssueReaction(content: '+1', count: 5);
      expect(r.awardId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // IssueComment
  // ---------------------------------------------------------------------------
  group('IssueComment', () {
    test('reactions default to empty', () {
      final c = IssueComment(
        id: '1',
        authorUsername: 'user',
        body: 'text',
        createdAt: DateTime(2024),
      );
      expect(c.reactions, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // PullRequest
  // ---------------------------------------------------------------------------
  group('PullRequest', () {
    test('linkedIssueCount defaults to 0', () {
      final pr = PullRequest(
        title: 'PR',
        number: 1,
        state: PrState.open,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        commentCount: 0,
        labels: const [],
      );
      expect(pr.linkedIssueCount, 0);
    });

    test('checkStatus defaults to none', () {
      final pr = PullRequest(
        title: 'PR',
        number: 1,
        state: PrState.open,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        commentCount: 0,
        labels: const [],
      );
      expect(pr.checkStatus, CheckStatus.none);
    });
  });

  // ---------------------------------------------------------------------------
  // Release / ReleaseAsset
  // ---------------------------------------------------------------------------
  group('Release', () {
    test('isPrerelease and isDraft default to false', () {
      final r = Release(
        name: 'v1.0',
        tagName: 'v1.0',
        description: '',
        authorUsername: 'u',
        createdAt: DateTime(2024),
        assets: const [],
      );
      expect(r.isPrerelease, isFalse);
      expect(r.isDraft, isFalse);
    });

    test('commitSha defaults to null', () {
      final r = Release(
        name: 'v1.0',
        tagName: 'v1.0',
        description: '',
        authorUsername: 'u',
        createdAt: DateTime(2024),
        assets: const [],
      );
      expect(r.commitSha, isNull);
    });
  });

  group('ReleaseAsset', () {
    test('size and downloadCount default to null', () {
      const a = ReleaseAsset(name: 'app.apk', downloadUrl: 'https://example.com/app.apk');
      expect(a.size, isNull);
      expect(a.downloadCount, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Tag
  // ---------------------------------------------------------------------------
  group('Tag', () {
    test('message is null for lightweight tag', () {
      final t = Tag(name: 'v1.0', sha: 'abc123', createdAt: DateTime(2024));
      expect(t.message, isNull);
    });

    test('stores annotation message', () {
      final t = Tag(name: 'v1.0', sha: 'abc123', createdAt: DateTime(2024), message: 'Release v1.0');
      expect(t.message, 'Release v1.0');
    });
  });

  // ---------------------------------------------------------------------------
  // ActionRun
  // ---------------------------------------------------------------------------
  group('ActionRun', () {
    test('prNumber, duration, branch default to null', () {
      final a = ActionRun(
        name: 'CI',
        number: 1,
        status: ActionRunStatus.success,
        event: 'push',
        authorUsername: 'u',
        createdAt: DateTime(2024),
      );
      expect(a.prNumber, isNull);
      expect(a.duration, isNull);
      expect(a.branch, isNull);
    });

    test('stores optional fields when provided', () {
      final a = ActionRun(
        name: 'CI',
        number: 1,
        status: ActionRunStatus.failure,
        event: 'pull_request',
        prNumber: 42,
        authorUsername: 'u',
        createdAt: DateTime(2024),
        duration: const Duration(minutes: 3),
        branch: 'feature/x',
      );
      expect(a.prNumber, 42);
      expect(a.duration, const Duration(minutes: 3));
      expect(a.branch, 'feature/x');
    });
  });

  // ---------------------------------------------------------------------------
  // AgentMessage / AgentAction
  // ---------------------------------------------------------------------------
  group('AgentMessage', () {
    test('actions defaults to empty list', () {
      final msg = AgentMessage(
        id: 1,
        body: 'Hello',
        authorLogin: 'ai',
        isAgent: true,
        createdAt: DateTime(2024),
      );
      expect(msg.actions, isEmpty);
    });
  });

  group('AgentAction', () {
    test('isCompleted defaults to true', () {
      const action = AgentAction(title: 'git_status', durationSeconds: 1);
      expect(action.isCompleted, isTrue);
    });
  });
}
