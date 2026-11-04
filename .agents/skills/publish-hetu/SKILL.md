---
name: publish-hetu
description: Coordinate and publish hetu_script, hetu_script_dev_tools and hetu_script_flutter to pub.dev, then restore local development dependencies
type: prompt
whenToUse: When the user explicitly asks to publish a coordinated release of the Hetu Script packages
disableModelInvocation: true
arguments:
  - main_version
  - dev_tools_version
  - flutter_version
---

# Publish coordinated Hetu packages

Publish these packages in order:

1. `packages/hetu_script`
2. `packages/hetu_script_dev_tools`
3. `packages/hetu_script_flutter`

Requested versions are `$main_version`, `$dev_tools_version`, and `$flutter_version`. If any version argument is missing, read the current manifests and determine the intended build-number increment with the user before publishing. Do not guess a version after publication has started.

Publishing is irreversible. Treat explicit invocation with confirmed versions as authorization to publish all three packages. Do not commit or push unless the user separately requests it.

## 1. Inspect before editing

- Read all three `pubspec.yaml` files and their CHANGELOGs.
- Read `packages/hetu_script/lib/version.dart`. Package build versions do not require changing `kHetuVersion`; change it only for a deliberate bytecode compatibility decision.
- Check the current Git status without deleting unrelated or user-created files.
- Record the original `publish_to` and path dependency settings that must be restored.
- Add or update the CHANGELOG entry for every published package.
- Published packages need an SDK upper bound. For the current Dart 3 packages use `sdk: ">=3.0.0 <4.0.0"` unless the project has deliberately selected another range.
- Keep runtime bytecode version and precompiled standard library unchanged when the bytecode format is unchanged.

## 2. Apply temporary publication configuration

- Set each manifest to the confirmed package version.
- Set `hetu_script_dev_tools` to depend on `hetu_script: ^<main_version>`.
- Set `hetu_script_flutter` to depend on `hetu_script: ^<main_version>`.
- Temporarily set `packages/hetu_script_flutter/example/pubspec.yaml` to use the same hosted main package version. The example itself remains `publish_to: none`.
- Remove `publish_to: none` only from packages being published. Do not remove it from examples or other local-only packages.
- Do not permanently modify environment variables. Before running hosted commands, configure the local proxy for the current shell. In PowerShell, run `$env:https_proxy="http://127.0.0.1:10080"`. In Bash, run `export https_proxy="http://127.0.0.1:10080"`.
- Prefix each hosted command with `PUB_HOSTED_URL=https://pub.dev/`. When running Bash commands without exporting the proxy, also prefix them with `https_proxy=http://127.0.0.1:10080`.

## 3. Validate and publish the main package

Run from `packages/hetu_script`:

```bash
PUB_HOSTED_URL=https://pub.dev/ dart pub get
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --dry-run
```

Resolve validation errors. Ignore Git-dirty warnings only when the user explicitly allows them. Do not ignore dependency, SDK, package-content or network errors.

If authorization is requested, ask the user to complete:

```bash
PUB_HOSTED_URL=https://pub.dev/ dart pub login
```

Do not read credential files or print secret tokens. Do not assume `dart pub token list` alone proves login failure, because interactive login credentials are stored separately.

Publish only after dry-run validation is otherwise acceptable:

```bash
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --force
```

Confirm that the server reports successful upload before continuing. The hosted version may take several minutes to become available.

## 4. Publish dev tools

Run from `packages/hetu_script_dev_tools`:

```bash
PUB_HOSTED_URL=https://pub.dev/ dart pub get
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --dry-run
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --force
```

The dependency solver must select the newly published main package version. If it is not visible yet, stop and retry later rather than silently publishing against an older main package.

## 5. Publish the Flutter package

Confirm Flutter is installed. Run from `packages/hetu_script_flutter`:

```bash
PUB_HOSTED_URL=https://pub.dev/ flutter pub get
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --dry-run
PUB_HOSTED_URL=https://pub.dev/ dart pub publish --force
```

`flutter pub get` also resolves the nested example. A local path dependency on the main package inside the example conflicts with the parent package's hosted dependency, so apply the temporary example change described above.

Track files modified automatically by Flutter. Do not use blanket cleanup commands. Only restore files confirmed to have been changed by this release process, such as generated Windows plugin files, analysis options or example lockfiles.

## 6. Restore local development settings

After all three uploads succeed:

- Restore `publish_to: none` in `packages/hetu_script_dev_tools/pubspec.yaml` and `packages/hetu_script_flutter/pubspec.yaml`.
- Restore the main dependency in both packages to `hetu_script: { path: ../hetu_script }` using normal multiline YAML.
- Restore `packages/hetu_script_flutter/example/pubspec.yaml` to `hetu_script: { path: ../../hetu_script }` using normal multiline YAML.
- Keep the released package versions, CHANGELOG entries and SDK upper bounds.
- Keep `kHetuVersion` unchanged unless a separate bytecode compatibility change was intentionally included.
- Remove only temporary artifacts created by this process. Leave unrelated user files alone.

Run from the repository root:

```bash
dart pub get
dart test
git diff --check
git status --short
```

The root lockfile should continue using local path packages and may retain their newly released version numbers. Report the uploaded versions and URLs, restoration status, test result and remaining uncommitted files. Do not commit or push unless the user explicitly asks.
