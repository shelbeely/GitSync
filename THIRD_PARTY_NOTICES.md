# Third-Party Notices

This file lists the third-party software included in or used by **GitSync** together with
their licence identifiers and source locations.

Transitive (indirect) dependencies pulled in through pub.dev are not listed individually
here; their licences are discoverable at `https://pub.dev/packages/<name>/license`.

---

## Contents

1. [Dart / Flutter packages (pub.dev — direct)](#1-dart--flutter-packages-pubdev--direct)
2. [Git-sourced packages](#2-git-sourced-packages)
3. [Rust crates (direct)](#3-rust-crates-direct)
4. [Vendored native libraries](#4-vendored-native-libraries)
5. [Bundled fonts and assets](#5-bundled-fonts-and-assets)
6. [Planned / future inclusions](#6-planned--future-inclusions)

---

## 1. Dart / Flutter packages (pub.dev — direct)

All packages below are fetched from [pub.dev](https://pub.dev) and are listed by
the version recorded in `pubspec.lock`.

| Package | Version | Licence | pub.dev page |
|---|---|---|---|
| `anchor_scroll_controller` | 0.4.4 | MIT | <https://pub.dev/packages/anchor_scroll_controller> |
| `animated_reorderable_list` | 1.3.0 | MIT | <https://pub.dev/packages/animated_reorderable_list> |
| `archive` | 4.0.9 | Apache-2.0 | <https://pub.dev/packages/archive> |
| `async` | 2.13.1 | BSD-3-Clause | <https://pub.dev/packages/async> |
| `collection` | 1.19.1 | BSD-3-Clause | <https://pub.dev/packages/collection> |
| `connectivity_plus` | 6.1.4 | BSD-3-Clause | <https://pub.dev/packages/connectivity_plus> |
| `convert` | 3.1.2 | BSD-3-Clause | <https://pub.dev/packages/convert> |
| `cryptography` | 2.9.0 | Apache-2.0 | <https://pub.dev/packages/cryptography> |
| `device_info_plus` | 11.3.3 | BSD-2-Clause | <https://pub.dev/packages/device_info_plus> |
| `dynamic_color` | 1.8.1 | Apache-2.0 | <https://pub.dev/packages/dynamic_color> |
| `encrypt` | 5.0.3 | BSD-3-Clause | <https://pub.dev/packages/encrypt> |
| `extended_text` | 15.0.2 | MIT | <https://pub.dev/packages/extended_text> |
| `file_manager` | 1.0.2 | MIT | <https://pub.dev/packages/file_manager> |
| `file_picker` | 10.3.10 | MIT | <https://pub.dev/packages/file_picker> |
| `flutter_email_sender` | 7.0.0 | MIT | <https://pub.dev/packages/flutter_email_sender> |
| `flutter_highlight` | 0.7.0 | MIT | <https://pub.dev/packages/flutter_highlight> |
| `flutter_local_notifications` | 18.0.1 | BSD-3-Clause | <https://pub.dev/packages/flutter_local_notifications> |
| `flutter_localized_locales` | 2.0.5 | MIT | <https://pub.dev/packages/flutter_localized_locales> |
| `flutter_riverpod` | 2.6.1 | MIT | <https://pub.dev/packages/flutter_riverpod> |
| `flutter_rust_bridge` | 2.12.0 | MIT | <https://pub.dev/packages/flutter_rust_bridge> |
| `flutter_secure_storage` | 10.0.0 | BSD-3-Clause | <https://pub.dev/packages/flutter_secure_storage> |
| `fluttertoast` | 8.2.12 | MIT | <https://pub.dev/packages/fluttertoast> |
| `font_awesome_flutter` | 11.0.0 | MIT (code) · SIL OFL 1.1 (icons) | <https://pub.dev/packages/font_awesome_flutter> |
| `highlight` | 0.7.0 | MIT | <https://pub.dev/packages/highlight> |
| `home_widget` | 0.9.1 | MIT | <https://pub.dev/packages/home_widget> |
| `html` | 0.15.6 | BSD-3-Clause | <https://pub.dev/packages/html> |
| `http` | 1.6.0 | BSD-3-Clause | <https://pub.dev/packages/http> |
| `intl` | 0.20.2 | BSD-3-Clause | <https://pub.dev/packages/intl> |
| `markdown_widget` | 2.3.2+8 | MIT | <https://pub.dev/packages/markdown_widget> |
| `mixin_logger` | 0.1.3 | MIT | <https://pub.dev/packages/mixin_logger> |
| `mmap2` | 0.1.0 | MIT | <https://pub.dev/packages/mmap2> |
| `mmap2_flutter` | 0.2.1 | MIT | <https://pub.dev/packages/mmap2_flutter> |
| `oauth2_client` | 4.2.5 | MIT | <https://pub.dev/packages/oauth2_client> |
| `open_file` | 3.5.11 | BSD-3-Clause | <https://pub.dev/packages/open_file> |
| `package_info_plus` | 8.3.0 | BSD-2-Clause | <https://pub.dev/packages/package_info_plus> |
| `path` | 1.9.1 | BSD-3-Clause | <https://pub.dev/packages/path> |
| `path_provider` | 2.1.5 | BSD-3-Clause | <https://pub.dev/packages/path_provider> |
| `permission_handler` | 11.4.0 | MIT | <https://pub.dev/packages/permission_handler> |
| `quick_actions` | 1.1.0 | BSD-3-Clause | <https://pub.dev/packages/quick_actions> |
| `re_editor` | 0.8.0 | Apache-2.0 | <https://pub.dev/packages/re_editor> |
| `re_highlight` | 0.0.3 | MIT | <https://pub.dev/packages/re_highlight> |
| `shared_preferences` | 2.5.5 | BSD-3-Clause | <https://pub.dev/packages/shared_preferences> |
| `showcaseview` | 4.0.1 | MIT | <https://pub.dev/packages/showcaseview> |
| `sprintf` | 7.0.0 | MIT | <https://pub.dev/packages/sprintf> |
| `timeago` | 3.7.1 | MIT | <https://pub.dev/packages/timeago> |
| `url_launcher` | 6.3.2 | BSD-3-Clause | <https://pub.dev/packages/url_launcher> |
| `web_socket_channel` | 3.0.3 | BSD-3-Clause | <https://pub.dev/packages/web_socket_channel> |
| `yaml` | 3.1.3 | BSD-3-Clause | <https://pub.dev/packages/yaml> |

> **Dev-only packages** (`flutter_lints`, `flutter_test`, `integration_test`) are not
> shipped in the app binary and are not listed above.

---

## 2. Git-sourced packages

These packages are referenced directly from Git repositories rather than pub.dev.

### flutter_background_service (ViscousPot fork)

- **Packages:** `flutter_background_service`, `flutter_background_service_android`,
  `flutter_background_service_ios`, `flutter_background_service_platform_interface`
- **Version (resolved ref):** `fe783b40c0cba7331dda5a2e4987e1c739d0dbf9`
- **Licence:** MIT
- **Source:** <https://github.com/ViscousPot/flutter_background_service_with_intents>
- **Note:** Fork of the upstream `flutter_background_service` package
  (<https://github.com/ReinBentdal/flutter_background_service>).

### ios_document_picker

- **Version (resolved ref):** `cc19fd549f23dd1f2ce3f4dd287cc653e84fd6b6`
- **Licence:** MIT
- **Source:** <https://github.com/ViscousPot/ios_document_picker>

### workmanager

- **Version:** 0.5.2 (resolved ref `4ce065135dc1b91fee918f81596b42a56850391d`)
- **Licence:** MIT
- **Source:** <https://github.com/fluttercommunity/flutter_workmanager>

---

## 3. Rust crates (direct)

These crates are declared as direct dependencies in `rust/Cargo.toml`.

| Crate | Version | Licence | crates.io |
|---|---|---|---|
| `flutter_rust_bridge` | 2.12.0 | MIT | <https://crates.io/crates/flutter_rust_bridge> |
| `git2` | 0.20.4 | MIT | <https://crates.io/crates/git2> |
| `libssh2-sys` | 0.3.1 | MIT | <https://crates.io/crates/libssh2-sys> |
| `nix` | 0.31.2 | MIT | <https://crates.io/crates/nix> |
| `osshkeys` | 0.7.0 | MIT | <https://crates.io/crates/osshkeys> |
| `regex` | 1.12.3 | MIT OR Apache-2.0 | <https://crates.io/crates/regex> |
| `ssh-key` | 0.6.7 | Apache-2.0 OR MIT | <https://crates.io/crates/ssh-key> |
| `tokio` | 1.x | MIT | <https://crates.io/crates/tokio> |
| `uuid` | 1.22 | Apache-2.0 OR MIT | <https://crates.io/crates/uuid> |

---

## 4. Vendored native libraries

The Rust build enables `git2/vendored-libgit2` and `git2/vendored-openssl`, which
compile and statically link the following C libraries into the GitSync binary:

### libgit2

- **Licence:** GPL-2.0-only WITH GCC-exception-2.0
  (the linking exception permits use from non-GPL code)
- **Source:** <https://github.com/libgit2/libgit2>
- **Copyright:** Copyright © 2009–present, the libgit2 contributors

### OpenSSL

- **Licence:** Apache-2.0 (OpenSSL 3.x)
- **Source:** <https://github.com/openssl/openssl>
- **Copyright:** Copyright © 1998–present, The OpenSSL Project Authors

### libssh2

Included transitively through `libssh2-sys`.

- **Licence:** BSD-3-Clause
- **Source:** <https://github.com/libssh2/libssh2>
- **Copyright:** Copyright © 2004–2007 Sara Golemon, et al.

---

## 5. Bundled fonts and assets

### Roboto Mono

- **Files:** `fonts/RobotoMono/RobotoMono-*.ttf`
- **Licence:** Apache-2.0
- **Source:** <https://fonts.google.com/specimen/Roboto+Mono>
- **Copyright:** Copyright © Google LLC

### Atkinson Hyperlegible

- **Files:** `fonts/AtkinsonHyperlegible/AtkinsonHyperlegible-*.ttf`
- **Licence:** SIL Open Font Licence 1.1 (SIL OFL 1.1)
- **Source:** <https://brailleinstitute.org/freefont>
- **Copyright:** Copyright © 2020 Braille Institute of America, Inc.

---

## 6. Planned / future inclusions

The items below are not yet present in the codebase. They are documented here
prospectively as part of the kelivo integration plan
(see `docs/kelivo_integration_spec.md §8`).

### kelivo (Chevey339/kelivo)

- **Planned use:** MCP provider, built-in fetch server, MCP tool service, MCP settings
  UI, enhanced markdown rendering widgets — see spec §3–§5 for the full file list.
- **Licence:** GNU Affero General Public License v3.0 (AGPL-3.0)
- **Source:** <https://github.com/Chevey339/kelivo>
- **Compliance requirement:** Incorporating AGPL-3.0 code into this GPL-3.0 repository
  requires the combined work to be distributed under AGPL-3.0. See spec §8.2 for the
  three resolution options. Every ported Dart file must carry the attribution header
  specified in spec §8.3.

### mermaid.min.js

- **Planned use:** Bundled JS asset for in-app Mermaid diagram rendering (`assets/mermaid.min.js`).
- **Licence:** MIT
- **Source:** <https://github.com/mermaid-js/mermaid>
- **Copyright:** Copyright © 2014–present Knut Sveidqvist and contributors
- **Compliance requirement:** The file must carry or be accompanied by a
  `mermaid.min.js.LICENSE.txt` sidecar with the MIT licence text.

### mcp_client (vendored)

- **Planned use:** Vendored fork in `dependencies/mcp_client/` providing MCP protocol
  client transport types.
- **Licence:** MIT (confirm against the vendored version before committing)
- **Source:** <https://pub.dev/packages/mcp_client>
- **Compliance requirement:** Confirm the licence of the exact vendored revision and
  update this entry accordingly before the first commit of the vendored code.
