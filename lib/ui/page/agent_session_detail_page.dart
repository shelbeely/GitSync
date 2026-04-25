import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/agent_message.dart';
import 'package:GitSync/type/agent_session.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

class AgentSessionDetailPage extends StatefulWidget {
  final GitProvider gitProvider;
  final String remoteWebUrl;
  final String accessToken;
  final bool githubAppOauth;
  final AgentSession session;
  final String owner;
  final String repo;

  const AgentSessionDetailPage({
    super.key,
    required this.gitProvider,
    required this.remoteWebUrl,
    required this.accessToken,
    required this.githubAppOauth,
    required this.session,
    required this.owner,
    required this.repo,
  });

  @override
  State<AgentSessionDetailPage> createState() => _AgentSessionDetailPageState();
}

class _AgentSessionDetailPageState extends State<AgentSessionDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _followUpController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  List<AgentMessage> _messages = [];
  bool _loading = true;
  bool _submitting = false;
  final Set<int> _expandedAgentMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _followUpController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  GitProviderManager? get _manager =>
      GitProviderManager.getGitProviderManager(widget.gitProvider, widget.githubAppOauth);

  Future<void> _fetchMessages() async {
    setState(() => _loading = true);
    final manager = _manager;
    if (manager == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final messages = await manager.getAgentSessionMessages(
      widget.accessToken,
      widget.owner,
      widget.repo,
      widget.session.issueNumber,
    );

    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendFollowUp() async {
    final text = _followUpController.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    _followUpController.clear();
    _inputFocusNode.unfocus();

    final manager = _manager;
    if (manager == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final msg = await manager.postAgentFollowUp(
      widget.accessToken,
      widget.owner,
      widget.repo,
      widget.session.issueNumber,
      text,
    );

    if (!mounted) return;
    if (msg != null) {
      setState(() {
        _messages = [..._messages, msg];
        _submitting = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _submitting = false);
      Fluttertoast.showToast(msg: t.agentFollowUpFailed, toastLength: Toast.LENGTH_SHORT);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colours.primaryDark,
      appBar: AppBar(
        backgroundColor: colours.primaryDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: colours.primaryLight, size: textMD),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.owner}/${widget.repo}',
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: spaceSM),
            child: GestureDetector(
              onTap: _fetchMessages,
              child: FaIcon(FontAwesomeIcons.arrowsRotate, color: colours.secondaryLight, size: textMD),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMetaBar(),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colours.tertiaryInfo))
                : RefreshIndicator(
                    onRefresh: _fetchMessages,
                    color: colours.tertiaryInfo,
                    child: _messages.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) => _buildMessage(_messages[i]),
                          ),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMetaBar() {
    final session = widget.session;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXXS),
      color: colours.secondaryDark,
      child: Row(
        children: [
          FaIcon(
            session.isOpen ? FontAwesomeIcons.circleNotch : FontAwesomeIcons.circleCheck,
            color: session.isOpen ? colours.tertiaryInfo : colours.tertiaryPositive,
            size: textXS,
          ),
          SizedBox(width: spaceXXS),
          Text(
            timeago.format(session.createdAt, allowFromNow: true),
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
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        SizedBox(height: spaceXL),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.robot, color: colours.tertiaryDark, size: 40),
              SizedBox(height: spaceMD),
              Text(t.agentNoMessages, style: TextStyle(color: colours.secondaryLight, fontSize: textSM)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(AgentMessage message) {
    if (message.isAgent) {
      return _buildAgentMessage(message);
    }
    return _buildUserMessage(message);
  }

  Widget _buildUserMessage(AgentMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: spaceSM, left: spaceXL),
        padding: EdgeInsets.all(spaceSM),
        decoration: BoxDecoration(
          color: colours.secondaryDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(3),
          ),
        ),
        child: GestureDetector(
          onLongPress: () => Clipboard.setData(ClipboardData(text: message.body))
              .then((_) => Fluttertoast.showToast(msg: t.copiedText, toastLength: Toast.LENGTH_SHORT)),
          child: Text(
            message.body,
            style: TextStyle(color: colours.primaryLight, fontSize: textSM),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentMessage(AgentMessage message) {
    final isExpanded = _expandedAgentMessages.contains(message.id);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.actions.isNotEmpty) _buildAgentSessionRow(message, isExpanded),
          if (message.body.isNotEmpty)
            Container(
              margin: EdgeInsets.only(
                bottom: spaceXS,
                right: spaceXL,
                top: message.actions.isNotEmpty ? spaceXXS : 0,
              ),
              padding: EdgeInsets.all(spaceSM),
              decoration: BoxDecoration(
                color: colours.secondaryDark,
                borderRadius: message.actions.isNotEmpty
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      )
                    : BorderRadius.all(cornerRadiusSM),
              ),
              child: GestureDetector(
                onLongPress: () => Clipboard.setData(ClipboardData(text: message.body))
                    .then((_) => Fluttertoast.showToast(msg: t.copiedText, toastLength: Toast.LENGTH_SHORT)),
                child: Text(
                  message.body,
                  style: TextStyle(color: colours.primaryLight, fontSize: textSM),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgentSessionRow(AgentMessage message, bool isExpanded) {
    final totalSeconds = message.actions.fold<int>(0, (sum, a) => sum + a.durationSeconds);
    final allCompleted = message.actions.every((a) => a.isCompleted);
    final durationLabel = _formatDuration(totalSeconds);

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedAgentMessages.remove(message.id);
        } else {
          _expandedAgentMessages.add(message.id);
        }
      }),
      child: Container(
        margin: EdgeInsets.only(bottom: spaceXXS, right: spaceXL),
        padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
        decoration: BoxDecoration(
          color: colours.secondaryDark,
          borderRadius: BorderRadius.only(
            topLeft: cornerRadiusSM,
            topRight: cornerRadiusSM,
            bottomLeft: isExpanded ? Radius.zero : cornerRadiusSM,
            bottomRight: isExpanded ? Radius.zero : cornerRadiusSM,
          ),
          border: Border.all(color: colours.tertiaryDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  allCompleted ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleNotch,
                  color: allCompleted ? colours.tertiaryPositive : colours.tertiaryInfo,
                  size: textMD,
                ),
                SizedBox(width: spaceSM),
                Expanded(
                  child: Text(
                    message.actions.isNotEmpty ? message.actions.last.title : '',
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spaceXS),
                Text(
                  durationLabel,
                  style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                ),
                SizedBox(width: spaceXXS),
                FaIcon(
                  isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                  color: colours.secondaryLight,
                  size: textXS,
                ),
              ],
            ),
            if (!isExpanded)
              Padding(
                padding: EdgeInsets.only(top: spaceXXXS, left: textMD + spaceSM),
                child: Text(
                  '${message.actions.length} ${t.agentActions}',
                  style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                ),
              ),
            if (isExpanded) ...[
              SizedBox(height: spaceXS),
              ...message.actions.map((action) => _buildActionStep(action)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionStep(AgentAction action) {
    return Padding(
      padding: EdgeInsets.only(left: textMD + spaceSM, bottom: spaceXXXS),
      child: Row(
        children: [
          FaIcon(
            action.isCompleted ? FontAwesomeIcons.check : FontAwesomeIcons.circleNotch,
            color: action.isCompleted ? colours.tertiaryPositive : colours.tertiaryInfo,
            size: textXS,
          ),
          SizedBox(width: spaceXXS),
          Expanded(
            child: Text(
              action.title,
              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action.durationSeconds > 0) ...[
            SizedBox(width: spaceXXS),
            Text(
              _formatDuration(action.durationSeconds),
              style: TextStyle(color: colours.tertiaryDark, fontSize: textXXS),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(spaceMD, spaceXS, spaceMD, spaceXS + MediaQuery.of(context).viewInsets.bottom),
      color: colours.secondaryDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _followUpController,
              focusNode: _inputFocusNode,
              style: TextStyle(color: colours.primaryLight, fontSize: textSM),
              decoration: InputDecoration(
                hintText: t.agentFollowUpHint,
                hintStyle: TextStyle(color: colours.tertiaryDark),
                filled: true,
                fillColor: colours.primaryDark,
                contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMax),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMax),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(cornerRadiusMax),
                  borderSide: BorderSide(color: colours.tertiaryInfo),
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendFollowUp(),
            ),
          ),
          SizedBox(width: spaceXS),
          GestureDetector(
            onTap: _submitting ? null : _sendFollowUp,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colours.tertiaryInfo,
                shape: BoxShape.circle,
              ),
              child: _submitting
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: colours.primaryDark, strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded, color: colours.primaryDark, size: textMD),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
