# GitSync × kelivo Integration Spec

**Source repo:** [Chevey339/kelivo](https://github.com/Chevey339/kelivo)  
**Target repo:** shelbeely/GitSync  
**Scope:** MCP Server support · Enhanced Markdown Rendering · Multimodal Input  
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

---

## 1. Context & Goals

GitSync is a Flutter Git client with an AI chat assistant backed by an internal `ToolRegistry` / `AiTool` / `ToolExecutor` system. The AI renders its responses via `markdown_widget` and currently accepts only plain text input. Kelivo is a full-featured Flutter LLM chat client that has already solved three problems GitSync needs:

| Goal | Kelivo source |
|---|---|
| Allow the AI to connect to any external MCP server | `lib/core/providers/mcp_provider.dart`, `lib/core/services/mcp/` |
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
