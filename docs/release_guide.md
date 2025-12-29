# Release Guide

This guide describes how to build, package, and release **JustSend**.

## Prerequisites

- Xcode installed.
- `gh` (GitHub CLI) installed (optional, for CLI release).
- `git` installed.

## Steps

### 1. Update Version

Ensure the `MARKETING_VERSION` is updated in `JustSend.xcodeproj`.

```bash
# Example: Set version to 1.1
sed -i '' 's/MARKETING_VERSION = .*;/MARKETING_VERSION = 1.1;/g' JustSend.xcodeproj/project.pbxproj
```

### 2. Commit and Tag

Commit the version bump and create a git tag.

```bash
git add .
git commit -m "Bump version to 1.1"
git push
git tag v1.1
git push origin v1.1
```

### 3. Build and Package

### 3. Build and Package

1.  In Xcode, go to **Product > Archive**.
2.  Once archived, click **Distribute App**.
3.  Choose **Custom**, then **Copy App**.
4.  Export the app to a known location (or let the script find the latest export in the current directory).
5.  Run the deployment script:

```bash
# Finds the latest export in the current directory or specified path
./scripts/manual_deploy.sh [optional_path_to_export_folder]
```

This script will:

- Find the latest exported `JustSend.app`.
- Create a `JustSend.dmg`.
- Generate the appcast.
- Commit/Push changes.
- Create a GitHub release.

### 4. Create Release

You can create a release via GitHub Web UI or CLI.

**Using CLI:**

```bash
gh release create v1.1 JustSend.dmg --title "v1.1" --notes "Release notes here..."
```

**Using Web UI:**

1.  Go to [Releases](https://github.com/PrajeetShrestha/JustSend/releases).
2.  Draft a new release.
3.  Select the tag `v1.1`.
4.  Upload `JustSend.dmg`.
5.  Publish.
