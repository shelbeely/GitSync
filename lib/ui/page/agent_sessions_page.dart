import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/agent_progress_notification.dart';
import 'package:GitSync/api/github_agent_channel.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/type/agent_session.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/ui/page/agent_session_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class AgentSessionsPage extends ConsumerStatefulWidget {
  const AgentSessionsPage({super.key});

  @override
  ConsumerState<AgentSessionsPage> createState() => _AgentSessionsPageState();
}

class _AgentSessionsPageState extends ConsumerState<AgentSessionsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<AgentSession> _sessions = [];
  bool _loading = false;
  String _stateFilter = "all";
  int _fetchGeneration = 0;

  String? _accessToken;
  String? _remoteWebUrl;
  GitProvider? _gitProvider;
  bool _githubAppOauth = false;

  GithubAgentChannel? _agentChannel;
  StreamSubscription<AgentSession>? _channelSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _channelSub?.cancel();
    _agentChannel?.disconnect();
    AgentProgressNotification.instance.cancelProgress();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final creds = await uiSettingsManager.getGitHttpAuthCredentials();
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    if (!mounted) return;
    setState(() {
      _accessToken = creds.$2;
      _githubAppOauth = githubAppOauth;
    });
    _fetchSessions();
    _startChannel();
  }

  (String, String)? _parseOwnerRepo() {
    if (_remoteWebUrl == null || _remoteWebUrl!.isEmpty) return null;
    final segments = Uri.parse(_remoteWebUrl!).pathSegments;
    if (segments.length < 2) return null;
    return (segments[0], segments[1].replaceAll(".git", ""));
  }

  bool get _isGithubWithOauth =>
      (_gitProvider == GitProvider.GITHUB) && (_accessToken?.isNotEmpty == true);

  void _fetchSessions() {
    if (!_isGithubWithOauth) return;

    final ownerRepo = _parseOwnerRepo();
    if (ownerRepo == null) return;
    final (owner, repo) = ownerRepo;

    final generation = ++_fetchGeneration;
    setState(() {
      _sessions.clear();
      _loading = true;
    });

    final manager = GitProviderManager.getGitProviderManager(_gitProvider!, _githubAppOauth);
    if (manager == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    manager.getCopilotAgentSessions(_accessToken!, owner, repo).then((sessions) {
      if (!mounted || generation != _fetchGeneration) return;
      setState(() {
        _sessions.addAll(sessions);
        _loading = false;
      });
    });
  }

  void _startChannel() {
    if (!_isGithubWithOauth) return;
    final ownerRepo = _parseOwnerRepo();
    if (ownerRepo == null) return;
    final (owner, repo) = ownerRepo;

    // Cancel any existing channel before creating a new one.
    _channelSub?.cancel();
    _agentChannel?.disconnect();

    _agentChannel = GithubAgentChannel(
      accessToken: _accessToken!,
      owner: owner,
      repo: repo,
    );
    _channelSub = _agentChannel!.events.listen(_onChannelEvent);
    _agentChannel!.connect();
  }

  void _onChannelEvent(AgentSession session) {
    if (!mounted) return;
    setState(() {
      final idx = _sessions.indexWhere((s) => s.issueNumber == session.issueNumber);
      if (idx >= 0) {
        final prev = _sessions[idx];
        _sessions[idx] = session;
        // Session just closed → complete notification.
        if (prev.isOpen && !session.isOpen) {
          AgentProgressNotification.instance.completeProgress(
            success: true,
            title: session.title,
            text: '#${session.issueNumber}',
          );
          return;
        }
      } else {
        _sessions.insert(0, session);
      }
    });
    if (session.isOpen) {
      AgentProgressNotification.instance.showProgress(
        stage: 'working',
        title: session.title,
        text: '#${session.issueNumber}',
      );
    }
  }
    if (_stateFilter == "active") return _sessions.where((s) => s.isOpen).toList();
    if (_stateFilter == "completed") return _sessions.where((s) => !s.isOpen).toList();
    return _sessions;
  }

  @override
  Widget build(BuildContext context) {
    final remoteUrlLink = ref.watch(remoteUrlLinkProvider).valueOrNull;
    final gitProvider = ref.watch(gitProviderProvider).valueOrNull;

    if (remoteUrlLink?.$2 != _remoteWebUrl || gitProvider != _gitProvider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final changed = remoteUrlLink?.$2 != _remoteWebUrl || gitProvider != _gitProvider;
        if (changed) {
          _remoteWebUrl = remoteUrlLink?.$2;
          _gitProvider = gitProvider;
          _init();
        }
      });
    }

    return Scaffold(
      backgroundColor: colours.primaryDark,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isGithubWithOauth) _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _isGithubWithOauth
          ? FloatingActionButton(
              backgroundColor: colours.tertiaryInfo,
              foregroundColor: colours.primaryDark,
              onPressed: _openCreateSession,
              child: const FaIcon(FontAwesomeIcons.plus),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(spaceMD, spaceMD, spaceMD, spaceXS),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.robot, color: colours.tertiaryInfo, size: textLG),
          SizedBox(width: spaceSM),
          Text(
            t.tabAgent,
            style: TextStyle(color: colours.primaryLight, fontSize: textXL, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_isGithubWithOauth && !_loading)
            GestureDetector(
              onTap: _fetchSessions,
              child: FaIcon(FontAwesomeIcons.arrowsRotate, color: colours.secondaryLight, size: textMD),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXXS),
      child: Row(
        children: [
          _filterChip(t.agentFilterAll, "all"),
          SizedBox(width: spaceXS),
          _filterChip(t.agentFilterActive, "active"),
          SizedBox(width: spaceXS),
          _filterChip(t.agentFilterCompleted, "completed"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _stateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _stateFilter = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXXS),
        decoration: BoxDecoration(
          color: selected ? colours.tertiaryInfo : colours.secondaryDark,
          borderRadius: BorderRadius.all(cornerRadiusMax),
          border: Border.all(color: selected ? colours.tertiaryInfo : colours.tertiaryDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colours.primaryDark : colours.secondaryLight,
            fontSize: textSM,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isGithubWithOauth) {
      return _emptyState(
        icon: FontAwesomeIcons.github,
        title: t.agentNotAvailableTitle,
        subtitle: t.agentNotAvailableSubtitle,
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colours.tertiaryInfo));
    }

    final sessions = _filteredSessions;
    if (sessions.isEmpty) {
      return _emptyState(
        icon: FontAwesomeIcons.robot,
        title: t.agentNoSessionsTitle,
        subtitle: t.agentNoSessionsSubtitle,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: spaceXL),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
    );
  }

  Widget _emptyState({required FaIconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: colours.tertiaryDark, size: 48),
            SizedBox(height: spaceMD),
            Text(title, style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: spaceXS),
            Text(subtitle, style: TextStyle(color: colours.secondaryLight, fontSize: textSM), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(AgentSession session) {
    return GestureDetector(
      onTap: () => _openSession(session),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXXXS),
        padding: EdgeInsets.all(spaceSM),
        decoration: BoxDecoration(
          color: colours.secondaryDark,
          borderRadius: BorderRadius.all(cornerRadiusSM),
          border: Border.all(color: colours.tertiaryDark),
        ),
        child: Row(
          children: [
            FaIcon(
              session.isOpen ? FontAwesomeIcons.circleNotch : FontAwesomeIcons.circleCheck,
              color: session.isOpen ? colours.tertiaryInfo : colours.tertiaryPositive,
              size: textMD,
            ),
            SizedBox(width: spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spaceXXXS),
                  Row(
                    children: [
                      Text(
                        '#${session.issueNumber}',
                        style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                      ),
                      if (session.sessionCount > 0) ...[
                        Text('  ·  ', style: TextStyle(color: colours.tertiaryDark, fontSize: textXS)),
                        Text(
                          '${session.sessionCount} ${t.agentSessions}',
                          style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                        ),
                      ],
                      if (session.premiumRequests > 0) ...[
                        Text('  ·  ', style: TextStyle(color: colours.tertiaryDark, fontSize: textXS)),
                        Text(
                          '${session.premiumRequests} ${t.agentPremiumRequests}',
                          style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: spaceXS),
            Text(
              timeago.format(session.createdAt, allowFromNow: true),
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
            ),
          ],
        ),
      ),
    );
  }

  void _openSession(AgentSession session) {
    final ownerRepo = _parseOwnerRepo();
    if (ownerRepo == null) return;
    final (owner, repo) = ownerRepo;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentSessionDetailPage(
          gitProvider: _gitProvider!,
          remoteWebUrl: _remoteWebUrl!,
          accessToken: _accessToken!,
          githubAppOauth: _githubAppOauth,
          session: session,
          owner: owner,
          repo: repo,
        ),
      ),
    );
  }

  void _openCreateSession() {
    final ownerRepo = _parseOwnerRepo();
    if (ownerRepo == null) return;
    final (owner, repo) = ownerRepo;
    showModalBottomSheet<AgentSession?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colours.secondaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: cornerRadiusMD),
      ),
      builder: (_) => _CreateSessionSheet(
        gitProvider: _gitProvider!,
        accessToken: _accessToken!,
        githubAppOauth: _githubAppOauth,
        owner: owner,
        repo: repo,
      ),
    ).then((newSession) {
      if (newSession != null) {
        _fetchSessions();
        _openSession(newSession);
      }
    });
  }
}

class _CreateSessionSheet extends StatefulWidget {
  final GitProvider gitProvider;
  final String accessToken;
  final bool githubAppOauth;
  final String owner;
  final String repo;

  const _CreateSessionSheet({
    required this.gitProvider,
    required this.accessToken,
    required this.githubAppOauth,
    required this.owner,
    required this.repo,
  });

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _submitting = true);

    final manager = GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);
    if (manager == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final session = await manager.createAgentSession(
      widget.accessToken,
      widget.owner,
      widget.repo,
      title,
      _bodyController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: spaceMD,
        right: spaceMD,
        top: spaceMD,
        bottom: MediaQuery.of(context).viewInsets.bottom + spaceMD,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.robot, color: colours.tertiaryInfo, size: textMD),
              SizedBox(width: spaceSM),
              Text(
                t.agentCreateTitle,
                style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: FaIcon(FontAwesomeIcons.xmark, color: colours.secondaryLight, size: textMD),
              ),
            ],
          ),
          SizedBox(height: spaceMD),
          TextField(
            controller: _titleController,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM),
            decoration: InputDecoration(
              hintText: t.agentCreateTitleHint,
              hintStyle: TextStyle(color: colours.tertiaryDark),
              filled: true,
              fillColor: colours.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(cornerRadiusSM),
                borderSide: BorderSide(color: colours.tertiaryDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(cornerRadiusSM),
                borderSide: BorderSide(color: colours.tertiaryDark),
              ),
            ),
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          SizedBox(height: spaceXS),
          TextField(
            controller: _bodyController,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM),
            decoration: InputDecoration(
              hintText: t.agentCreateBodyHint,
              hintStyle: TextStyle(color: colours.tertiaryDark),
              filled: true,
              fillColor: colours.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(cornerRadiusSM),
                borderSide: BorderSide(color: colours.tertiaryDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(cornerRadiusSM),
                borderSide: BorderSide(color: colours.tertiaryDark),
              ),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: spaceMD),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colours.tertiaryInfo,
                foregroundColor: colours.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                padding: EdgeInsets.symmetric(vertical: spaceSM),
              ),
              icon: _submitting
                  ? SizedBox(
                      width: textMD,
                      height: textMD,
                      child: CircularProgressIndicator(color: colours.primaryDark, strokeWidth: 2),
                    )
                  : FaIcon(FontAwesomeIcons.robot, size: textMD),
              label: Text(
                t.agentAskCopilot,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: textSM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

