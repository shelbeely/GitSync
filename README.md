<div align="center">
  <br/>
  <img 
    src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp" width="140" 
  />

  <h3>GitHub Command Center</h3>
  <h4>Mobile GitHub client for managing and syncing your repositories</h4>
  
  <p align="center">
    <a href="#"><img src="https://img.shields.io/github/license/ViscousPot/GitSync?v=1" alt="license"></a>
    <a href="#"><img src="https://img.shields.io/github/last-commit/ViscousPot/GitSync?v=1" alt="last commit"></a>
    <a href="#"><img src="https://img.shields.io/github/downloads/ViscousPot/GitSync/total" alt="downloads"></a>
    <a href="#"><img src="https://img.shields.io/github/stars/ViscousPot/GitSync?v=1" alt="stars"></a>
    <a href="https://github.com/sponsors/ViscousPot"><img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="sponsor"></a>
  </p>
    <img alt="2024 Gem of the Year (Obsidian Tools)" src="https://img.shields.io/badge/2024%20Gem%20of%20the%20Year%20(Obsidian%20Tools)-black?style=for-the-badge&logo=obsidian&logoColor=hotpink">
  <br />
  <br />

  <p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.shelbeely.gitcommand" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" style="height: 48px" ></a>  
  &nbsp;&nbsp;
  <a href="https://apps.apple.com/us/app/gitsync/id6744980427" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Get it on Google Play" style="height: 48px" ></a>
  &nbsp;&nbsp;
  <a href="https://apt.izzysoft.de/fdroid/index/apk/com.shelbeely.gitcommand" target="_blank"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" alt="Get it on Izzy On Droid" style="height: 48px" ></a>
  <!-- &nbsp;&nbsp; -->
  <!-- <a href="#" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/a/a3/Get_it_on_F-Droid_%28material_design%29.svg" alt="Get it on F-Droid" style="height: 48px" ></a> -->
  </p>

  <p align="center">
    <a href="https://gitsync.viscouspotenti.al/wiki"><img alt="Wiki" src="https://img.shields.io/badge/wiki-white?style=for-the-badge"></a>
  </p>
  <br />

</div>

GitHub Command Center is a cross-platform GitHub client for Android and iOS that aims to simplify the process of syncing a folder between a git remote and a local directory. It works in the background to keep your files synced with a simple one-time setup and a range of options for activating manual syncs.

- **Supports Android 5+ & iOS 13+**
- Authenticate with
  - **HTTP/S**
  - **SSH**
  - **OAuth** (GitHub, GitLab, Gitea)
- Clone a remote repository
- Sync repository
  - Fetch, pull, stage, commit, push
  - Resolve merge conflicts
  - Retry automatically when the network returns
- Sync mechanisms
  - When an app is opened or closed (Android)
  - On a recurring schedule
  - From a quick tile (Android)
  - From a home screen widget
  - From an iOS shortcut or automation
  - From a custom intent (advanced)
- Browse and edit in-app
  - File explorer with code editor and image viewer
  - Recent commits, plus file, line and commit diffs
  - Branch management (create, rename, delete, checkout)
  - Multiple remotes (add, rename, delete, set URL)
- GitHub and GitLab integration (when signed in via OAuth)
  - View, comment on and create issues
  - View, comment on and create pull requests
  - View workflow runs (GitHub Actions)
- AI features
  - Chat about your repository
  - Wand auto-complete on text fields like commit messages
  - Agent that can run repo actions for you
  - Separate model selection for chat, tools and the wand
  - A global toggle to hide all AI features
- Manage multiple repositories with containers
- Repository settings
  - Signed commits
  - Customisable sync commit messages
  - Author details
  - Edit `.gitignore` and `.git/info/exclude`
  - Disable SSL verification per repo

More information can be found at the [wiki](https://gitsync.viscouspotenti.al/wiki)
<br>
Give us a ⭐ if you like our work. Much appreciated!

## Support

For support, email bugs.viscouspotential@gmail.com or create an issue in this repository.

## Build Instructions

If you just want to try the app out, feel free to download a release from an official platform!

GitSync is a Flutter app with a Rust core (via [`flutter_rust_bridge`](https://github.com/fzyzcjy/flutter_rust_bridge)). 

### 1. Prerequisites

- **Flutter**: version pinned in [`.fvmrc`](.fvmrc) (currently 3.35.2). The repo is set up for [FVM](https://fvm.app/); install with `dart pub global activate fvm` and then `fvm install`.
- **Rust**: stable toolchain via [rustup](https://rustup.rs/). The Rust crate lives in [`rust/`](rust/).
- **Android**: Android Studio with a recent SDK (compileSdk follows Flutter, minSdk 21). The Rust crate cross-compiles to `aarch64`, `armv7`, `x86_64` and `i686` targets, which you can add via `rustup target add`.
- **iOS**: Xcode 15+ on macOS, the `aarch64-apple-ios`, `aarch64-apple-ios-sim` and `x86_64-apple-ios` Rust targets, and CocoaPods.

### 2. Clone & install

```bash
git clone https://github.com/ViscousPot/GitSync.git
cd GitSync
fvm flutter pub get
```

### 3. OAuth secrets

OAuth providers (GitHub, GitLab, Gitea, Codeberg) need client IDs/secrets. The repo ships a template:

```bash
cp lib/constant/secrets.dart.template lib/constant/secrets.dart
```

Open the newly created `lib/constant/secrets.dart` and fill in the values as described below. Without these the OAuth sign-in flows won't work, but HTTPS Basic and SSH still do.

#### `oauthRedirectUrl`

Always set this to:

```dart
const oauthRedirectUrl = "gitsync://auth";
```

#### GitHub OAuth App (`gitHubClientId` / `gitHubClientSecret`)

Used for the standard GitHub "Sign in with GitHub" flow.

1. Go to **GitHub → Settings → Developer settings → OAuth Apps → New OAuth App** (direct link: <https://github.com/settings/applications/new>).
2. Fill in the form:
   - **Application name**: anything (e.g. `GitSync Dev`)
   - **Homepage URL**: anything (e.g. `https://github.com/ViscousPot/GitSync`)
   - **Authorization callback URL**: `gitsync://auth`
3. Click **Register application**.
4. Copy the **Client ID** → `gitHubClientId`.
5. Click **Generate a new client secret**, copy the value → `gitHubClientSecret`.

#### GitHub App (`gitHubAppClientId` / `gitHubAppClientSecret`)

Used for the GitHub App OAuth flow (elevated permissions / org access).

1. Go to **GitHub → Settings → Developer settings → GitHub Apps → New GitHub App** (direct link: <https://github.com/settings/apps/new>).
2. Fill in the form:
   - **GitHub App name**: anything (e.g. `GitSync Dev App`)
   - **Homepage URL**: anything
   - **Callback URL**: `gitsync://auth`
   - **Webhook**: uncheck *Active* (not needed for mobile OAuth)
   - Grant any repository/account permissions you need, then click **Create GitHub App**.
3. On the app's settings page, copy the **Client ID** → `gitHubAppClientId`.
4. Under **Client secrets**, click **Generate a new client secret**, copy the value → `gitHubAppClientSecret`.

#### GitLab (`gitlabClientId`)

1. Sign in to GitLab (gitlab.com or your self-hosted instance).
2. Go to **User menu → Preferences → Applications** (direct link: <https://gitlab.com/-/profile/applications>).
3. Fill in the form:
   - **Name**: anything
   - **Redirect URI**: `gitsync://auth`
   - **Scopes**: `read_user`, `api`
4. Click **Save application**.
5. Copy the **Application ID** → `gitlabClientId`.

> GitLab public OAuth apps are client-ID-only for mobile; no secret is stored in this app.

#### Gitea (`giteaClientId`)

The value here is used as a *default* client ID for gitea.com. Each user can also supply their own instance's credentials inside the app.

1. Sign in to your Gitea instance (or <https://gitea.com>).
2. Go to **User menu → Settings → Applications → Manage OAuth2 Applications**.
3. Fill in:
   - **Application Name**: anything
   - **Redirect URIs**: `gitsync://auth`
4. Click **Create Application**.
5. Copy the **Client ID** → `giteaClientId`.

> The client secret is not stored in this file; Gitea's PKCE flow is used instead.

#### Codeberg (`codebergClientId`)

Codeberg runs Gitea, so the steps are identical to the Gitea section above, performed on <https://codeberg.org>.

1. Go to <https://codeberg.org/user/settings/applications>.
2. Under **Manage OAuth2 Applications**, create a new app with redirect URI `gitsync://auth`.
3. Copy the **Client ID** → `codebergClientId`.

#### Completed `secrets.dart` example

```dart
const oauthRedirectUrl = "gitsync://auth";
const gitHubClientId = "Iv1.xxxxxxxxxxxx";
const gitHubClientSecret = "your_github_oauth_app_secret";
const gitHubAppClientId = "Iv23.xxxxxxxxxxxx";
const gitHubAppClientSecret = "your_github_app_secret";
const giteaClientId = "your-gitea-client-id";
const gitlabClientId = "your-gitlab-application-id";
const codebergClientId = "your-codeberg-client-id";
```

> **Security**: `secrets.dart` is listed in `.gitignore` and must never be committed.

---

### CI / GitHub Actions secrets

The build and release workflows read several repository secrets. Set these under **Repository → Settings → Secrets and variables → Actions → New repository secret**.

| Secret | Required by | How to obtain |
|---|---|---|
| `SECRETS` | `build.yml` | The full text content of your completed `secrets.dart` file (see above). Copy-paste the entire file into the secret value. |
| `RELEASE_KEYSTORE_BASE64` | `generate-apk-release.yml` | Your Android release keystore encoded as Base64: `base64 -w 0 release.keystore`. Create a keystore with `keytool -genkey -v -keystore release.keystore -alias <alias> -keyalg RSA -keysize 2048 -validity 10000`. |
| `RELEASE_SIGNING_ALIAS` | `generate-apk-release.yml` | The alias you chose when creating the keystore (the `-alias` value above). |
| `RELEASE_SIGNING_PASSWORD` | `generate-apk-release.yml` | The password you set for both the keystore and the key. |

### 4. Generate the Rust ↔ Dart bindings

The bridge is regenerated when the Rust API changes:

```bash
cargo install flutter_rust_bridge_codegen --version 2.12.0
flutter_rust_bridge_codegen generate
```

### 5. Run

```bash
fvm flutter run
```

## Contributing

Your support means a lot! If you find GitSync useful, please:

- Star the repo to help others discover it
- Share it with friends or communities that might benefit
- Consider becoming a [GitHub Sponsor](https://github.com/sponsors/ViscousPot)

<br>
At this time, code contributions aren’t needed anywhere in particular, but I’d love your help improving <strong><a href="#localization-contributions">localization</a></strong>

<details>
<summary><h3 style="display:inline-block;">Localization Contributions</h3></summary>

If you’d like to contribute translations:

1. Locate the **English strings** in `lib/l10n/app_en.arb`
2. Find the corresponding language file (e.g. `lib/l10n/app_es.arb` for Spanish)
3. Add or refine translations in the appropriate file
4. Submit a pull request or open an issue with your suggestions

Currently supported languages:

- English (`app_en.arb`, the source file)
- Arabic (`app_ar.arb`)
- Chinese, Simplified (`app_zh.arb`)
- Chinese, Traditional (`app_zh_Hant.arb`, early stage)
- French (`app_fr.arb`)
- German (`app.de.arb`)
- Japanese (`app_ja.arb`)
- Russian (`app_ru.arb`)
- Spanish (`app_es.arb`)

If you'd like to know what's still untranslated for a given locale, see [`untranslated.txt`](untranslated.txt). Even small improvements to wording or grammar are welcome.

</details>

## Acknowledgements

- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
- [git2-rs](https://github.com/rust-lang/git2-rs)
