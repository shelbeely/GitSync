# GitSync × kelivo Integration Spec

**Source repo:** [Chevey339/kelivo](https://github.com/Chevey339/kelivo)  
**Target repo:** shelbeely/GitSync  
**Scope:** MCP Server support · Built-in GitHub MCP Server · Enhanced Markdown Rendering · Multimodal Input  
**Type:** Spec only — no code changes in this document

---

## Table of Contents

1. [Context & Goals](#1-context--goals)
2. [Current State Audit](#2-current-state-audit)
3. [Feature A — MCP Server Support](#3-feature-a--mcp-server-support)
4. [Feature B — Enhanced Markdown Rendering](#4-feature-b--enhanced-markdown-rendering)
5. [Feature C — Multimodal Input](#5-feature-c--multimodal-input)
6. [Dependency Delta](#6-dependency-delta)
7. [Out of Scope](#7-out-of-scope)
8. [License & Attribution](#8-license--attribution)

> **Amendment (2026-04-26):** Section 3.5 has been added to specify the GitHub MCP Server as a second built-in server alongside the kelivo fetch server.
>
> **Amendment (2026-04-26):** Section 3.6 has been added to specify the in-memory `@app/github-mcp-apps` server — a fully app-local MCP proxy that wraps the upstream GitHub MCP server and layers MCP Apps UI on top of every discovered tool.

---

## 1. Context & Goals

GitSync is a Flutter Git client with an AI chat assistant backed by an internal `ToolRegistry` / `AiTool` / `ToolExecutor` system. The AI renders its responses via `markdown_widget` and currently accepts only plain text input. Kelivo is a full-featured Flutter LLM chat client that has already solved three problems GitSync needs:

| Goal | Kelivo source |
|---|---|
| Allow the AI to connect to any external MCP server | `lib/core/providers/mcp_provider.dart`, `lib/core/services/mcp/` |
| Ship a built-in web-fetch MCP server | `lib/core/services/mcp/kelivo_fetch/` |
| Ship the official GitHub MCP server as a built-in, pre-configured server | [github/github-mcp-server](https://github.com/github/github-mcp-server) |
| Ship a built-in in-memory GitHub MCP proxy server with full MCP Apps UI for every GitHub tool | `lib/core/services/mcp/github_apps/` (new — modeled after `kelivo_fetch` pattern) |
| Render code blocks with syntax highlighting, LaTeX, diagrams, and more | `lib/shared/widgets/markdown_with_highlight.dart`, `lib/shared/widgets/mermaid_*`, `lib/shared/widgets/plantuml_block.dart` |
| Accept images, PDFs, Word docs, and other files as AI input | `lib/features/chat/widgets/image_preview_sheet.dart`, `lib/core/models/chat_message.dart` |

---

## 2. Current State Audit

### Markdown rendering (GitSync today)

- **Package:** `markdown_widget ^2.3.2`
- **Config:** `lib/ui/component/markdown_config.dart` — custom heading/paragraph/code/table styles, `DetailsBlockSyntax`, HTML inline passthrough
- **Gaps:**
  - `PreConfig.theme` is an empty map `{}` — no syntax highlighting at all
  - No LaTeX / math formula support
  - No Mermaid diagram support
  - No copy-button on code blocks
  - No PlantUML support

### Message input (GitSync today)

- `lib/ui/page/ai_features_page.dart` — single `TextField`, plain text only
- `lib/type/ai_chat.dart` — `ContentBlock` sealed class with only `TextBlock` and `ToolUseBlock`; no image or file block type exists

### MCP (GitSync today)

- No MCP support exists. The AI only calls tools from the internal `ToolRegistry`.

---

## 3. Feature A — MCP Server Support

### 3.1 MCP Protocol Foundation

**Kelivo sources:**
- `lib/core/providers/mcp_provider.dart` (48 KB) — the main provider
- `dependencies/mcp_client/` — vendored fork of the `mcp_client` pub package

**What `McpProvider` does:**
- Holds a list of `McpServerConfig` models (name, transport, URL or command+args, env vars, headers, per-tool enabled/disabled state, timeout)
- Manages connect/disconnect lifecycle for each server
- Supports two transports:
  - **SSE** — connects to a remote HTTP server via Server-Sent Events
  - **Stdio** — spawns a local subprocess and communicates over stdin/stdout
- Discovers and caches tool schemas from each connected server
- Exposes `callTool(serverId, toolName, arguments)` and per-server error state

**What needs to be ported:**
- `McpServerConfig` data model — serialisable to/from JSON so configs survive app restarts
- `McpProvider` ChangeNotifier, adapted to work alongside GitSync's existing Riverpod providers (expose via `ChangeNotifierProvider` or a `StateNotifierProvider`)
- Add `mcp_client` dependency (vendored or from pub.dev once stable)

### 3.2 Built-in Fetch MCP Server

**Kelivo sources:**
- `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_server.dart`
- `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_inmemory.dart`

**What it does:**
An in-memory MCP server that runs in the same isolate as the app. It exposes four tools:

| Tool | Description |
|---|---|
| `fetch_html` | Returns raw HTML from a URL |
| `fetch_markdown` | Converts fetched HTML to Markdown via `html2md` |
| `fetch_txt` | Plain-text extraction (strips `<script>` / `<style>`) |
| `fetch_json` | Fetches and pretty-prints a JSON endpoint |

The `KelivoInMemoryClientTransport` connects the MCP client directly to the engine with no network or subprocess overhead.

**What needs to be ported:**
- `KelivoFetchMcpServerEngine` — pure Dart, minimal adaptation needed
- `KelivoInMemoryClientTransport` — wire as an always-on, pre-registered MCP server so users get web-fetch capability out of the box
- Adds `html2md` dependency (GitSync already has `html`)

### 3.3 MCP Tool Bridge (McpToolService)

**Kelivo source:** `lib/core/services/mcp/mcp_tool_service.dart`

**What it does:**
Bridges `McpProvider`'s connected servers into the chat loop. For a given conversation context it:
- Lists all MCP tools available
- Calls a named tool and normalises the result to a plain string (handles `TextContent`, `ResourceContent`, `ImageContent` response variants)
- Returns a structured error JSON when a call fails so the AI can self-correct and retry

**What needs to be ported:**
- Adapt `McpToolService` to work with GitSync's `ToolRegistry` — wrap each active MCP tool as a dynamic `AiTool` registered into the existing registry, **or** add a parallel MCP dispatch path in `ToolExecutor.execute()` (fallthrough after the native `registry.get()` lookup returns null)
- Carry over the `_renderToolErrorForModel` structured error format verbatim

### 3.4 MCP Settings UI

**Kelivo sources:**
- `lib/features/mcp/pages/mcp_page.dart` (28 KB) — server list, per-server connect/disconnect toggle, tool expansion, error indicators
- `lib/features/mcp/widgets/mcp_server_edit_sheet.dart` (43 KB) — full server config editor (name, SSE URL vs. stdio command+args, env vars, HTTP headers, auth tokens)
- `lib/features/mcp/widgets/mcp_json_edit_sheet.dart` — raw JSON paste mode for power users (imports a Claude `mcp_config.json`-style block)
- `lib/features/mcp/widgets/mcp_timeout_sheet.dart` — per-server timeout slider

**What needs to be ported:**
- Adapt navigation to GitSync's routing style
- Surface as a new page reachable from the existing AI settings section
- Replace kelivo's `Provider` state lookups with Riverpod equivalents

### 3.5 Built-in GitHub MCP Server

**External source:** [github/github-mcp-server](https://github.com/github/github-mcp-server)  
**Transport:** SSE (remote) at `https://api.githubcopilot.com/mcp/`  
**Authentication:** GitHub Personal Access Token (PAT) — GitSync already stores and manages PATs per provider

#### Overview

The official GitHub MCP Server is hosted by GitHub and exposes GitHub's entire platform surface as MCP tools. It is the ideal second built-in server for GitSync because GitSync is a GitHub/Gitea/GitLab client; the AI agent already has a PAT for the authenticated user, so no extra credentials are required.

The server uses standard SSE transport, meaning it connects over a single HTTPS endpoint — no subprocess, no binary bundling. It is pre-registered as a hidden, always-available server (users can disable individual toolsets from the settings UI but cannot delete it).

#### How it fits the existing MCP stack

The GitHub MCP server is registered via the same `McpProvider` and `McpServerConfig` model described in §3.1. The only difference from a user-added SSE server is that:
- It is created programmatically at app startup with `isBuiltIn: true`
- The `Authorization: Bearer <token>` header is populated from the PAT already stored in GitSync's `FlutterSecureStorage` for the active provider
- It is shown in the MCP settings UI under a "Built-in Servers" section, separately from user-added servers

#### Tool surface

The GitHub MCP server exposes tools grouped into **toolsets**. The default toolset selection on first launch is pre-configured to the tools most relevant to a Git client:

| Toolset | Default state | Key tools included |
|---|---|---|
| `context` | **Enabled** | `get_me`, `get_teams` |
| `repos` | **Enabled** | `get_file_contents`, `list_commits`, `get_commit`, `create_or_update_file`, `push_files`, `search_repositories`, `create_repository`, `fork_repository`, `list_branches` |
| `issues` | **Enabled** | `list_issues`, `get_issue`, `create_issue`, `update_issue`, `add_issue_comment`, `search_issues` |
| `pull_requests` | **Enabled** | `list_pull_requests`, `get_pull_request`, `create_pull_request`, `merge_pull_request`, `get_pull_request_diff`, `list_pull_request_files`, `get_pull_request_reviews` |
| `actions` | **Enabled** | `actions_list`, `actions_get`, `get_job_logs`, `actions_run_trigger` |
| `notifications` | **Enabled** | `list_notifications`, `get_notification_details`, `mark_notification_as_read`, `dismiss_notification` |
| `git` | **Enabled** | `get_tag`, `list_tags`, `list_branches` (low-level Git API) |
| `code_security` | Disabled | `list_code_scanning_alerts`, `get_code_scanning_alert` |
| `dependabot` | Disabled | `list_dependabot_alerts`, `get_dependabot_alert` |
| `secret_protection` | Disabled | `list_secret_scanning_alerts`, `get_secret_scanning_alert` |
| `discussions` | Disabled | `list_discussions`, `get_discussion`, `get_discussion_comments` |
| `labels` | Disabled | `create_label`, `list_labels_for_repo`, `get_label` |
| `orgs` | Disabled | `list_org_repositories`, `get_org_members` |
| `projects` | Disabled | `get_project`, `list_projects` |
| `gists` | Disabled | `list_gists`, `get_gist`, `create_gist` |
| `users` | Disabled | `search_users`, `get_user` |
| `stargazers` | Disabled | `list_stargazers` |
| `security_advisories` | Disabled | `list_global_security_advisories` |

All toolsets remain individually toggle-able by the user in the MCP settings UI.

#### Authentication flow

1. On startup, `McpProvider` checks for a stored PAT for the currently active provider
2. If a GitHub/GitHub Enterprise PAT is present, the built-in server is auto-created with `Authorization: Bearer <PAT>` in its header map
3. If no PAT is present (e.g. Gitea-only user), the built-in server is registered but shown as "Not configured" with a prompt linking to the AI provider settings
4. When the user rotates their PAT in GitSync settings, `McpProvider` updates the header on the live server config and reconnects

#### Overlap with GitSync's existing native tools

GitSync already has native `AiTool` implementations for some Git operations (`ai_tools_git.dart`, `ai_tools_provider.dart`). The GitHub MCP server overlaps with several of these. The resolution strategy:

- Native tools take precedence for local Git operations (clone, commit, push, diff, merge) — these require filesystem access that an HTTP MCP server cannot provide
- GitHub MCP server tools are preferred for remote GitHub API operations (issues, PRs, Actions, notifications) where the MCP server has broader scope and richer output than the existing native tools
- For operations that exist in both (e.g. listing branches), the native tool is kept and the MCP duplicate is disabled by default; users can enable it if desired

#### GitHub Enterprise support

The `McpServerConfig` for the built-in server reads the base URL from GitSync's existing provider config:
- **GitHub.com:** `https://api.githubcopilot.com/mcp/`
- **GitHub Enterprise Cloud (ghe.com):** `https://api.{hostname}/mcp/`
- **GitHub Enterprise Server (GHES):** The remote MCP server is not available for GHES; the built-in entry is hidden and replaced by a prompt to add the locally-hosted GHES MCP server binary as a stdio server instead

---

### 3.6 Built-in GitHub MCP Apps Server (`@app/github-mcp-apps`)

**Architecture:** In-memory proxy with MCP Apps UI layer  
**Transport:** `GithubMcpAppsInMemoryClientTransport` (new `InMemory` transport variant)  
**Upstream:** `https://api.githubcopilot.com/mcp/x/all` (GitHub's remote MCP server)

#### 3.6.1 Overview & Architecture

§3.5 registers a raw SSE connection to the upstream GitHub MCP server through `McpProvider`. §3.6 is a fundamentally different approach: it is a fully app-local MCP server engine that *proxies* the upstream GitHub MCP server and layers MCP Apps UI metadata on top of every tool it discovers. This gives the app a rich, interactive UI for every GitHub MCP tool without any external daemon or subprocess.

**Two-tier architecture:**

```
App
 └─ mcp.Client
     └─ GithubMcpAppsInMemoryClientTransport   (implements mcp.ClientTransport)
         └─ GithubMcpAppsServerEngine           (in-process MCP server)
             └─ GithubUpstreamClient            (outbound MCP client, SSE)
                 └─ https://api.githubcopilot.com/mcp/x/all
```

The server is registered as `@app/github-mcp-apps` via the existing `McpProvider`. A new `InMemory` transport variant is added to `McpServerConfig` alongside the existing `SSE` and `Stdio` variants. No network port or subprocess is involved on the local side.

§3.5 and §3.6 can be active simultaneously. They share the same token from `FlutterSecureStorage`. §3.6 is the preferred built-in for users who interact with GitHub tools through the MCP Apps UI; §3.5 is retained for programmatic/AI-only access patterns.

#### 3.6.2 New source files

| File | Purpose |
|---|---|
| `lib/core/services/mcp/github_apps/github_mcp_apps_server.dart` | `GithubMcpAppsServerEngine` — handles `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read` |
| `lib/core/services/mcp/github_apps/github_upstream_client.dart` | `GithubUpstreamClient` — MCP client connecting to upstream SSE endpoint; manages token, optional headers, and reconnect |
| `lib/core/services/mcp/github_apps/github_tool_manifest.dart` | `GithubToolManifest` — cached tool list; each entry holds name, description, inputSchema, annotations, safety class, and generated `_meta.ui.resourceUri` |
| `lib/core/services/mcp/github_apps/github_tool_safety.dart` | `GithubToolSafety` — classifies each tool as `read`, `write`, `destructive`, or `unknown` by name-prefix heuristic and upstream annotations |
| `lib/core/services/mcp/github_apps/resources/tool_runner_app_html.dart` | `ToolRunnerAppHtml` — single-file bundled HTML app served by `resources/read`; receives boot config as injected JSON |

#### 3.6.3 Upstream connection

- **Default URL:** `https://api.githubcopilot.com/mcp/x/all` (also configurable per-server)
- **Token source:** `GITHUB_MCP_TOKEN` env var or the app setting; falls back to the PAT already stored in `FlutterSecureStorage` for the active GitHub provider (same as §3.5)
- **Required header when token is present:** `Authorization: Bearer <token>`
- **Optional pass-through headers:**
  - `X-MCP-Toolsets` — filter which GitHub toolsets are returned
  - `X-MCP-Tools` — filter which individual tools are returned
  - `X-MCP-Readonly` — restrict server to read-only tools
  - `X-MCP-Insiders` — opt in to Insiders-only tools
  - `X-MCP-Lockdown` — enable lockdown mode
- The token is **never** embedded in generated HTML, log output, or tool results.

#### 3.6.4 Tool discovery and wrapping

The manifest is built lazily on first `tools/list` (or eagerly when `github_apps_refresh_manifest` is called):

1. `GithubUpstreamClient` connects to the upstream SSE endpoint and calls upstream `tools/list`.
2. Each upstream tool is stored in `GithubToolManifest` with its `name`, `description`, `inputSchema`, and any `annotations`/metadata preserved verbatim.
3. Each cached entry gains a `_meta.ui.resourceUri` of the form `ui://github-mcp-apps/tool/<url-encoded-tool-name>`.
4. `GithubToolSafety` assigns a safety classification (`read`, `write`, `destructive`, or `unknown`) to each entry.
5. The local server's `tools/list` returns all wrapped tools together with the four local helper tools (§3.6.5).
6. The upstream manifest is the **source of truth** — the full GitHub tool list is never hardcoded. New GitHub MCP tools are exposed automatically on the next manifest refresh.

#### 3.6.5 Local helper tools

Four built-in wrapper tools are added to the local server's `tools/list` in addition to all proxied GitHub tools:

| Tool | Inputs | Purpose |
|---|---|---|
| `github_apps_refresh_manifest` | *(none)* | Re-fetches upstream `tools/list` and rebuilds the cached manifest |
| `github_apps_open_tool` | `tool_name: string` | Returns `_meta.ui.resourceUri` for the named tool so the caller can open its UI |
| `github_apps_search_tools` | `query: string` | Full-text search across tool name, description, and inputSchema field names |
| `github_apps_tool_catalog` | *(none)* | Returns all available tools grouped by GitHub toolset/category |

#### 3.6.6 MCP Apps resources

**`resources/list`** returns:

- One entry per wrapped upstream tool: `uri = ui://github-mcp-apps/tool/<toolName>`
- The generic tool-runner entry: `uri = ui://github-mcp-apps/tool-runner`
- All curated app entries listed in §3.6.7

**`resources/read`** for a `ui://github-mcp-apps/tool/<toolName>` URI:

- Returns the `ToolRunnerAppHtml` bundle
- MIME type: `text/html;profile=mcp-app`
- Injects a boot-config JSON block (as an inline `<script>` tag) containing:
  - selected tool name
  - selected tool inputSchema
  - read/write/destructive/unknown safety classification
  - upstream tool description
- Does **not** inject the GitHub token or any credentials

#### 3.6.7 Curated MCP Apps resources

In addition to the per-tool generated resources, the following named app resources are included in `resources/list` and handled by `resources/read`:

| URI | Purpose |
|---|---|
| `ui://github-mcp-apps/catalog` | Browsable catalog of all available GitHub tools |
| `ui://github-mcp-apps/repo-dashboard` | Repository overview — issues, PRs, and Actions at a glance |
| `ui://github-mcp-apps/issues` | Issue list and creation form |
| `ui://github-mcp-apps/pull-requests` | PR list, review, and merge UI |
| `ui://github-mcp-apps/actions` | Workflow runs and job logs |
| `ui://github-mcp-apps/notifications` | Notification inbox and mark-as-read controls |
| `ui://github-mcp-apps/security` | Code scanning, Dependabot, and secret scanning alerts |
| `ui://github-mcp-apps/copilot-task` | Copilot task creation and tracking |
| `ui://github-mcp-apps/copilot-spaces` | Copilot Spaces management |
| `ui://github-mcp-apps/support-docs-search` | GitHub docs search via the `support_docs_search` tool |

These curated apps pre-configure context, filtering, and layout for each GitHub surface. They may call the same wrapped upstream tools internally. They are not required to cover every possible field up front because the universal `ToolRunnerApp` (§3.6.8) already covers every tool automatically.

#### 3.6.8 ToolRunnerApp (`tool_runner_app_html.dart`)

`ToolRunnerAppHtml` is a single-file, self-contained HTML application served by `resources/read`. It receives its configuration through an injected boot-config JSON block and communicates with the native app exclusively through the MCP Apps bridge/postMessage API — it has no direct network access and never touches the GitHub token.

Required capabilities:

- Render the tool name and description clearly
- Build a form from the tool's inputSchema, supporting:
  - `string`, `number`, `integer`, `boolean`
  - `array` (simple item-add UI)
  - `object` (nested field set)
  - `enum` (dropdown/radio selection)
  - nullable/optional fields (checkbox to include/exclude)
  - required fields clearly marked
- Validate all inputs client-side before allowing submission; block submission on validation failure
- For **write** tools: show an explicit confirmation step before calling
- For **destructive** tools: show a confirmation step and require the user to type a confirmation string before calling
- Call the tool via the MCP Apps bridge/postMessage API
- Display results as:
  - rendered readable text
  - formatted/pretty-printed JSON
  - a copy-to-clipboard block
- Provide a "View raw schema" toggle
- Provide a "View raw result" toggle
- Never display the GitHub token or any credential

#### 3.6.9 Safety classification (`GithubToolSafety`)

Every entry in `GithubToolManifest` is assigned one of four safety classes:

| Class | UI behaviour | Detection heuristic |
|---|---|---|
| `read` | Execute directly, no confirmation | Name has no write-signal prefix; or upstream readonly mode active (`X-MCP-Readonly`) |
| `write` | Require explicit confirmation before executing | Name prefix: `create`, `update`, `fork`, `add`, `lock`, `unlock`, `manage`, `run`, `trigger`, `merge`, `mark` |
| `destructive` | Require confirmation + typed confirmation string | Name prefix: `delete`, `remove`, `dismiss` |
| `unknown` | Require explicit confirmation | Insufficient signal from name or annotations |

Upstream tool annotations (if present) take precedence over the name-prefix heuristic. When `X-MCP-Readonly` is active, all tools are downgraded to `read` class regardless of name.

#### 3.6.10 Relation to §3.5

| Aspect | §3.5 (remote SSE server) | §3.6 (`@app/github-mcp-apps`) |
|---|---|---|
| Transport | SSE registered in `McpProvider` directly | `InMemory` — `GithubMcpAppsInMemoryClientTransport` |
| MCP Apps UI | None | Full — every tool has a generated form |
| Token handling | Header on SSE connection config | Header on upstream SSE leg only; never in local responses |
| Use case | Programmatic / AI-only tool access | Interactive MCP Apps UI access |
| Coexistence | Can run alongside §3.6 | Can run alongside §3.5 |

#### 3.6.11 Coverage requirement

Every tool returned by upstream `tools/list` automatically receives:

- A callable local proxy in `tools/list`
- A generated `_meta.ui.resourceUri` of the form `ui://github-mcp-apps/tool/<toolName>`
- A `resources/list` entry with that URI
- A `resources/read` response that renders successfully
- A schema-rendered form via `ToolRunnerApp`
- A result display
- A safety classification from `GithubToolSafety`

No code change is required when GitHub adds new MCP tools upstream.

#### 3.6.12 Testing requirements

| # | Test case |
|---|---|
| 1 | `initialize` returns correct server info and capability set |
| 2 | `tools/list` includes all four local helper tools |
| 3 | `tools/list` wraps all tools returned by the mock upstream |
| 4 | Every wrapped tool has `_meta.ui.resourceUri` set |
| 5 | `resources/list` contains exactly one entry per wrapped tool plus all curated entries |
| 6 | `resources/read` for a valid tool URI returns MIME type `text/html;profile=mcp-app` |
| 7 | A `read`-classified tool calls upstream directly without a confirmation gate |
| 8 | A `write`-classified tool blocks the upstream call until confirmation is present in arguments |
| 9 | A `destructive`-classified tool requires a typed confirmation string before executing |
| 10 | The GitHub token never appears in returned HTML, logs, or tool results |
| 11 | Upstream connection failure returns a structured MCP error content block instead of throwing |
| 12 | After `github_apps_refresh_manifest`, newly added tools appear and removed tools disappear from both `tools/list` and `resources/list` |

---

## 4. Feature B — Enhanced Markdown Rendering

### 4.1 Syntax-highlighted Code Blocks

**Kelivo source:** `lib/shared/widgets/markdown_with_highlight.dart` (100 KB)

**What it does:**
A full replacement markdown widget that wires `flutter_highlight` into `markdown_widget`'s `PreConfig`. Key capabilities:

- Per-language syntax highlighting with automatic language detection from the fenced code block info string
- Light/dark theme aware — switches highlight theme when `ThemeMode` changes
- Copy-to-clipboard button overlaid in the top-right corner of every code block
- Scrollable horizontal overflow for wide code without wrapping

**What needs to be ported:**
- Replace the empty `theme: {}` in GitSync's `PreConfig` with a proper highlight theme map (e.g. `atomOneDarkTheme` / `atomOneLightTheme` from `flutter_highlight`)
- Add a copy button overlay — currently absent in GitSync
- Add `flutter_highlight` and `highlight` dependencies (already in kelivo's pubspec)

### 4.2 LaTeX / Math Formulas

**Kelivo source:** uses `flutter_math_fork` package; formula blocks wired into `markdown_with_highlight.dart`

**What it does:**
Renders inline (`$…$`) and display-mode (`$$…$$`) LaTeX math expressions natively in Flutter without a WebView.

**What needs to be ported:**
- Add a custom `SpanNodeGeneratorWithTag` (or `blockSyntaxList` entry) in GitSync's `buildMarkdownGenerator()` that detects `$` / `$$` delimiters and delegates to `flutter_math_fork`'s `Math.tex()` widget
- Add `flutter_math_fork` dependency

### 4.3 Mermaid Diagrams

**Kelivo sources:**
- `lib/shared/widgets/mermaid_bridge.dart` — platform conditional entry point
- `lib/shared/widgets/mermaid_bridge_stub.dart` (23 KB) — desktop/mobile renderer using an in-app WebView with the Mermaid JS bundle
- `lib/shared/widgets/mermaid_bridge_web.dart` (6 KB) — web platform variant
- `lib/shared/widgets/mermaid_cache.dart` / `mermaid_image_cache.dart` — render caching to avoid re-rendering on every rebuild
- `assets/mermaid.min.js` — bundled Mermaid JS (no CDN dependency)

**What it does:**
When the AI (or a diff) outputs a fenced code block tagged ` ```mermaid `, renders a live Mermaid diagram (flowcharts, sequence diagrams, Gantt charts, etc.) via an embedded WebView running the bundled JS.

**What needs to be ported:**
- Wire a custom generator in `buildMarkdownGenerator()` that intercepts `mermaid`-tagged blocks and returns a `MermaidBridgeWidget` instead of a plain `PreConfig` block
- Bundle `mermaid.min.js` as a Flutter asset
- Add `webview_flutter` dependency (already used by kelivo; needed on Android/iOS/desktop)
- Add `webview_windows` for Windows desktop support

### 4.4 PlantUML Diagrams

**Kelivo source:** `lib/shared/widgets/plantuml_block.dart` (10 KB)

**What it does:**
Renders ` ```plantuml ` blocks by sending the diagram source to the PlantUML public server (or a user-configurable self-hosted instance) and displaying the returned SVG/PNG image. Includes error handling and a loading indicator.

**What needs to be ported:**
- Same custom generator hook as Mermaid, detecting `plantuml`-tagged blocks
- No additional package dependency — uses the existing `http` package

---

## 5. Feature C — Multimodal Input

### 5.1 Message Content Model Extension

**Kelivo source:** `lib/core/models/chat_message.dart`

**What it does:**
Kelivo's `ChatMessage` content list supports multiple block types beyond plain text:

| Block type | Purpose |
|---|---|
| `TextContent` | Plain text (matches GitSync's `TextBlock`) |
| `ImageContent` | Inline image — stores either a local file path (base64 encoded on send) or a remote URL |
| `FileContent` | Arbitrary document — stores display name, MIME type, and extracted text content |

**What needs to be ported:**
- Extend GitSync's `ContentBlock` sealed class with `ImageBlock` and `FileBlock` variants
- Update `ChatMessage.toJson()` / `fromJson()` to serialise and deserialise the new block types
- Update `AiStreamClient` to include image/file content in the messages array sent to the AI provider (Anthropic Vision format: `{"type": "image", "source": {"type": "base64", ...}}`)

### 5.2 Image Attachment

**Kelivo source:** `lib/features/chat/widgets/image_preview_sheet.dart` (25 KB)

**What it does:**
- Adds an attachment button to the chat input row
- Opens a bottom sheet allowing the user to pick an image from the gallery (`image_picker`) or take a photo
- Shows thumbnail previews of attached images in a horizontal strip above the text field
- Allows removing individual attachments before sending
- On send: reads the file, base64-encodes it, and includes it in the message as an `ImageContent` block

**What needs to be ported:**
- Add an attachment icon button to GitSync's `AiFeaturesPage` input row
- Port the image preview strip widget
- Wire image picking to `image_picker` (already in kelivo's pubspec; needs to be added to GitSync)

### 5.3 Document / File Attachment

**Kelivo source:** `lib/core/services/api/` document processing utilities, `lib/features/chat/widgets/bottom_tools_sheet.dart`

**What it does:**
Supports attaching and extracting text from:

| Format | Extraction method |
|---|---|
| `.txt`, `.md`, `.csv`, `.json`, `.xml`, `.yaml` | Direct UTF-8 read |
| `.pdf` | `syncfusion_flutter_pdf` page-by-page text extraction |
| `.docx` | `archive` package to unzip + XML parse `word/document.xml` |
| Images (`.png`, `.jpg`, `.webp`) | Passed as `ImageContent`; text extraction via AI vision |

The bottom tools sheet presents a file picker (`file_picker`, already in GitSync) and routes each file to the correct extractor, capping text at a configurable token limit.

**What needs to be ported:**
- Port the per-format text extraction logic; for PDF, add `syncfusion_flutter_pdf` dependency (kelivo already uses it)
- Reuse GitSync's existing `file_picker` dependency
- Add extracted document content as `FileBlock` instances in the `ContentBlock` list before sending
- Add a "document" attachment chip to the input row (similar to the image strip, but showing filename + type icon)

### 5.4 Drag-and-Drop File Input (Desktop)

**Kelivo source:** uses `desktop_drop` package

**What it does:**
On Windows, macOS, and Linux, wraps the chat input area in a `DropTarget` widget. Files dragged onto the input area are automatically processed through the same extraction pipeline as files picked via the file picker.

**What needs to be ported:**
- Wrap GitSync's chat input widget tree in a `DropTarget` on desktop platforms
- Route dropped files through the same extraction logic as the manual file picker path
- Add `desktop_drop` dependency (already in kelivo)

---

## 6. Dependency Delta

The following packages need to be added to GitSync's `pubspec.yaml`. All are either already used by kelivo or are widely-used packages on pub.dev.

| Package | Feature | Notes |
|---|---|---|
| `mcp_client` | MCP — Feature A | Vendor or use pub.dev release |
| `html2md` | MCP built-in fetch server — Feature A.2 | `html` already present |
| *(no new package)* | GitHub MCP server — Feature A.5 | Pure SSE over HTTPS; uses existing `http` package |
| *(no new package)* | GitHub MCP Apps server — Feature A.6 | In-memory transport; minor vendored extension to `mcp_client` to add `InMemory` transport variant; no additional pub package |
| `flutter_highlight` | Code highlighting — Feature B.1 | |
| `highlight` | Code highlighting — Feature B.1 | |
| `flutter_math_fork` | LaTeX rendering — Feature B.2 | |
| `webview_flutter` | Mermaid diagrams — Feature B.3 | Android/iOS/desktop |
| `webview_windows` | Mermaid diagrams — Feature B.3 | Windows only |
| `image_picker` | Image attachment — Feature C.2 | |
| `syncfusion_flutter_pdf` | PDF text extraction — Feature C.3 | |
| `desktop_drop` | Drag-and-drop — Feature C.4 | Desktop platforms only |

Packages GitSync already has that overlap with kelivo features:
- `file_picker` — already present, covers document attachment
- `http` — already present, covers PlantUML fetch and fetch MCP server
- `html` — already present
- `archive` — already present, covers `.docx` extraction
- `markdown_widget` — already present, is the rendering foundation

---

## 7. Out of Scope

The following kelivo features are explicitly excluded from this spec because they are unrelated to GitSync's core Git client purpose:

| Feature | Reason |
|---|---|
| Web search integration (12+ providers) | Standalone feature, no Git relevance |
| TTS / Voice providers | No relevance to a Git client |
| Custom Assistants system | Tightly coupled to kelivo's chat identity model |
| World book / Instruction injection | Roleplay/LLM-specific, not needed |
| QR code provider config sharing | GitSync uses a different settings model |
| Backup / restore chat history to S3 | GitSync already has its own sync mechanism |
| Android background generation | GitSync has its own `flutter_background_service` setup |

---

## 8. License & Attribution

### 8.1 Upstream license

[Chevey339/kelivo](https://github.com/Chevey339/kelivo) is distributed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. The full text of the AGPL-3.0 is available in the kelivo repository at [`LICENSE`](https://github.com/Chevey339/kelivo/blob/main/LICENSE).

GitSync is currently distributed under the **GNU General Public License v3.0 (GPL-3.0)** (see [`LICENSE.md`](../LICENSE.md) in this repository).

### 8.2 Compatibility and licensing impact

AGPL-3.0 and GPL-3.0 are compatible copyleft licences in the sense that code from each may be combined. However, per the [FSF compatibility matrix](https://www.gnu.org/licenses/license-list.html#AGPLv3.0), when AGPL-3.0-licensed code is incorporated into a GPL-3.0 project the resulting **combined work must be distributed under AGPL-3.0**. The key practical difference is the AGPL-3.0 network-use clause: if the application is made available to users over a network, the corresponding source code must also be made available under AGPL-3.0 terms.

**Required action before any kelivo code is ported:** The project maintainer must decide one of:

1. **Re-license GitSync as AGPL-3.0** for the combined repository — the simplest path given that GitSync is already fully open-source and the AGPL-3.0 network-use clause is not a material restriction for a local desktop Git client.
2. **Isolate ported code in a separately-licensed sub-package** — keep the kelivo-derived files in a distinct Dart package within the monorepo, declaring that package as AGPL-3.0 while the rest of GitSync remains GPL-3.0.
3. **Obtain a separate licence from the kelivo author** — request a written GPL-3.0 (or MIT/Apache-2.0) re-licence grant from Chevey339 for the specific files to be ported.

Option 1 is recommended. This spec proceeds on the assumption that the repository licence will be updated to AGPL-3.0 before any kelivo source is committed.

### 8.3 Per-file copyright and attribution headers

Every Dart source file ported from kelivo **must** begin with an attribution comment that preserves the original copyright and identifies the upstream source. Use the following format:

```dart
// Ported from Chevey339/kelivo (AGPL-3.0)
// Original source: <path/to/original/file.dart>
// https://github.com/Chevey339/kelivo
//
// Modifications © <year> shelbeely/GitSync contributors.
// This file is part of GitSync and is distributed under the AGPL-3.0 licence.
// See LICENSE.md in the repository root for the full licence text.
```

The `<path/to/original/file.dart>` value for each file is the "Kelivo source:" path already documented in the relevant section of this spec (§3–§5). For convenience the mapping is reproduced below:

| GitSync destination (proposed) | Kelivo source |
|---|---|
| `lib/core/providers/mcp_provider.dart` | `lib/core/providers/mcp_provider.dart` |
| `dependencies/mcp_client/` | `dependencies/mcp_client/` |
| `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_server.dart` | `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_server.dart` |
| `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_inmemory.dart` | `lib/core/services/mcp/kelivo_fetch/kelivo_fetch_inmemory.dart` |
| `lib/core/services/mcp/mcp_tool_service.dart` | `lib/core/services/mcp/mcp_tool_service.dart` |
| `lib/features/mcp/pages/mcp_page.dart` | `lib/features/mcp/pages/mcp_page.dart` |
| `lib/features/mcp/widgets/mcp_server_edit_sheet.dart` | `lib/features/mcp/widgets/mcp_server_edit_sheet.dart` |
| `lib/features/mcp/widgets/mcp_json_edit_sheet.dart` | `lib/features/mcp/widgets/mcp_json_edit_sheet.dart` |
| `lib/features/mcp/widgets/mcp_timeout_sheet.dart` | `lib/features/mcp/widgets/mcp_timeout_sheet.dart` |
| `lib/shared/widgets/markdown_with_highlight.dart` | `lib/shared/widgets/markdown_with_highlight.dart` |
| `lib/shared/widgets/mermaid_bridge.dart` | `lib/shared/widgets/mermaid_bridge.dart` |
| `lib/shared/widgets/mermaid_bridge_stub.dart` | `lib/shared/widgets/mermaid_bridge_stub.dart` |
| `lib/shared/widgets/mermaid_bridge_web.dart` | `lib/shared/widgets/mermaid_bridge_web.dart` |
| `lib/shared/widgets/mermaid_cache.dart` | `lib/shared/widgets/mermaid_cache.dart` |
| `lib/shared/widgets/mermaid_image_cache.dart` | `lib/shared/widgets/mermaid_image_cache.dart` |
| `lib/shared/widgets/plantuml_block.dart` | `lib/shared/widgets/plantuml_block.dart` |
| `lib/features/chat/widgets/image_preview_sheet.dart` | `lib/features/chat/widgets/image_preview_sheet.dart` |
| `lib/core/models/chat_message.dart` | `lib/core/models/chat_message.dart` (multimodal content types only) |

### 8.4 Third-party asset: `mermaid.min.js`

The bundled `assets/mermaid.min.js` file (§4.3) originates from the [mermaid](https://github.com/mermaid-js/mermaid) project, **not** from kelivo. Mermaid is distributed under the **MIT licence**:

> Copyright © 2014–present Knut Sveidqvist and contributors  
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software …

When the file is copied into GitSync's `assets/` directory, add a comment in the first line of the file (or in a sidecar `mermaid.min.js.LICENSE.txt` file, following the convention used by webpack and other bundlers):

```
/*! mermaid.min.js — MIT Licence — https://github.com/mermaid-js/mermaid */
```

Also add an entry in the repository's third-party notices file (create `THIRD_PARTY_NOTICES.md` if it does not already exist).

### 8.5 Vendored `mcp_client` dependency

The `dependencies/mcp_client/` directory (§3.1) is a vendored fork of the [`mcp_client`](https://pub.dev/packages/mcp_client) pub.dev package. Before vendoring, confirm the `mcp_client` package licence (currently MIT at time of writing) and add the original package copyright to `THIRD_PARTY_NOTICES.md`.

### 8.6 Summary checklist for implementers

Before merging any PR that ports code from kelivo, verify:

- [ ] Repository `LICENSE.md` has been updated to AGPL-3.0 (or the chosen sub-package isolation strategy has been applied)
- [ ] Every ported Dart file carries the attribution header described in §8.3
- [ ] `assets/mermaid.min.js` carries or is accompanied by its MIT licence notice (§8.4)
- [ ] `THIRD_PARTY_NOTICES.md` lists kelivo (AGPL-3.0) and mermaid (MIT) and mcp_client (confirm licence)
- [ ] No ported file has had its original copyright comment removed or replaced
