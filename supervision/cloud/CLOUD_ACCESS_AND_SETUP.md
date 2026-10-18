# REX — Codex Cloud environment, permissions and connection guide

**Status:** Ready-to-configure repository instructions, **not** an already published cloud environment or automatically granted authorization.

## 1 — What REX needs
Develop against `production/swarm-reviewed-recovery` or its later independently reviewed successor. The production CI currently pins **Go 1.27.2**, **Flutter 3.35.7**, Java 17 and Android API 36. The old `app/rex_mobile` regression workflow uses Flutter 3.47.3; do not confuse the two installations. Inspect `.github/workflows/rex-production.yml` in the actual production branch before changing pins.

The Codex environment should supply Git, Python 3, Go, Dart/Flutter, Java 17, Android SDK 36 and command-line tools, plus optional Blender/Node/Khronos validator where actual art work requires them. Emulator/KVM access is **not** guaranteed inside Codex Cloud; Android device/emulator checks may need GitHub Actions or a connected device.

## 2 — Configure the environment as the human operator
1. Open [Codex](https://chatgpt.com/codex) on **desktop or web**. Create or edit a reusable **Cloud environment** for the GitHub repository `enad86102-debug/rex`, using its setup wizard. Set the working repository and inspect which branch is checked out. Account/workspace eligibility and actual settings vary.
2. Verify the GitHub account connected to that environment can **read the repository, create/update isolated branches, create draft pull requests, and read CI results**. Permission to an environment is not a substitute for permissions on the repository. If a push fails, fix the specific GitHub access error; do not paste a broad personal access token into chat.
3. Configure environment setup commands to inspect this repository and invoke `bash supervision/cloud/setup_rex_cloud.sh --profile android --check`. For a first-time setup where required SDKs are absent, opt in to `--install-go --install-flutter` only after reviewing this script, the official package endpoints, available network settings and storage capacity. `--android-packages` is only suitable when `sdkmanager` already exists and required licenses were accepted separately by the account owner.
4. Enable *temporary/restricted* outbound internet access for required dependency downloads when supported (see `REX_CLOUD_PROFILE.json`). Add exact hostnames observed from redirects. Do not grant unrestricted internet or HTTP methods simply for convenience, and don't mistake a repository JSON file for a platform network policy.
5. Add no secrets for normal source analysis/unit tests. If a staging integration specifically needs credentials later, use the Cloud environment's supported credential/secret mechanism with short-lived test-scoped access. Do not inject production keys, signing materials, bank/personal details or raw GitHub PATs.
6. Test the environment using `python3 supervision/cloud/cloud_doctor.py --profile android --json` and `python3 -m unittest discover -s supervision/cloud -p 'test_*.py' -v`. Confirm capability results rather than assuming environment setup succeeded.
7. Publish/save the environment when the platform reports it ready. New tasks can use its settings; existing tasks don't automatically inherit changes. Start source modifications in a **new isolated branch**.

Official platform guide: https://help.openai.com/en/articles/20001545-using-codex-cloud

## 3 — Important two-branch checkout constraint
Our supervision tools live on `supervision/rex-swarm-control`; the *real* Go/Flutter app lives in `production/swarm-reviewed-recovery`. The cloud task MUST have both. For a clean worktree, if authorization and writable Git are available, create an isolated code branch from the real production head and *only then* bring the review toolkit over:

```bash
git fetch origin supervision/rex-swarm-control production/swarm-reviewed-recovery
git switch -c codex/rex-cloud-integration origin/production/swarm-reviewed-recovery
git restore --source=origin/supervision/rex-swarm-control -- .agents supervision .github/workflows/rex-swarm-policy.yml .github/workflows/rex-cloud-checks.yml
python3 supervision/cloud/cloud_doctor.py --profile core --json
```

This intentionally creates **uncommitted** toolkit additions in the isolated workspace. Codex must inspect `git status`, review these changes and commit them safely in the appropriate PR before continuing. **Do not run on a dirty workspace or overwrite human edits**. If a tool cannot fetch these branches, stop and report the exact permission/repository issue. This is **not** an instruction to merge or replace `main`.

If the setup phase runs before the production branch is checked out, use the doctor to report missing production files; do not claim a production build.

## 4 — Least-privilege access matrix
Full machine-readable policy: `REX_ACCESS_MATRIX.json`.

| Service | Authorized development access | Not authorized by this plan |
|---|---|---|
| GitHub | repository read, isolated branch push, draft PR creation, Actions logs read | force push, repo deletion, org administration, secrets management |
| Package hosts | limited outbound HTTPS for official dependencies during setup | permanent unrestricted egress |
| Cloud filesystem | isolated project workspace and cache | personal computer access, external drives, other projects |
| Android | SDK, emulator **where available**, simulated device testing | physical phone access by assumption, debug signing for release |
| Asset tools | Blender/source files with provenance and rights | paid art subscriptions or unlicensed materials |
| Go database | ephemeral local test database | production DB root/credentials |
| Google Play | prepare release checklist | publishing, key export, user consent substitution |

Read-only/review roles and code-writing roles should be separated when the platform supports permission scoping. An untrusted third-party skill must never receive extra privileges by virtue of being installed.

## 5 — Network allowlist proposal (operator-controlled)
Hosts can include `go.dev`, `proxy.golang.org`, `sum.golang.org`, `github.com`, `api.github.com`, `storage.googleapis.com`, `pub.dev`, `dl.google.com`, `maven.google.com`, `repo.maven.apache.org`, `services.gradle.org`, `objects.githubusercontent.com`, `raw.githubusercontent.com` and any redirect host **actually observed and approved**. Different package tools may require other endpoints. Use the environment's actual available controls: domain allowlists, methods and connected apps vary by product. A denied host is an actionable setup blocker, not authorization to turn off all restrictions.

## 6 — Resource and tool profiles
- **Core:** Go, Python, Git, tests, fuzz/race and source analysis; no Android emulator required.
- **Android:** Flutter 3.35.7, Dart, Java 17, Android API 36, Gradle/SDK, `adb`; native emulator/KVM test can run in existing production GitHub Actions if Cloud VM lacks it.
- **Art:** Blender and appropriate open-source glTF tooling *only if authoring code/tools and rights exist*. Creating photoreal rigged characters is a separate art-production deliverable, not guaranteed by Blender availability.
- **Security:** Go vet/race/fuzz and existing pinned `production/tools/check_security.sh` in an isolated test branch. Additional scanners are candidates and require review before installation.

Prefer sufficient cloud memory for Flutter/Gradle builds (for example 16 GiB when offered). Do not claim this size is selectable in a particular account. Heavy Android emulator tests can be delegated to existing GitHub runners.

## 7 — Acceptance gates
A Cloud environment is READY FOR CODING only when repository access, toolchain versions, environment doctor output, network and code checkout all match the actual task. REAL GAME READY is a different and much later test: approved rules, full server-authoritative match, durable storage, four independent clients, visual/Android acceptance, and human approvals.

**Nothing in these files activates Codex, grants credentials, changes your account's cloud environment, creates a paid service, or starts 1000 agents.**
