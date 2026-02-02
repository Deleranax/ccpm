# ComputerCraft Package Manager (CCPM)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CC:Tweaked](https://img.shields.io/badge/CC%3ATweaked-Compatible-green.svg?logo=lua&logoColor=white)](https://tweaked.cc/)
[![Built with ccpmbuild](https://img.shields.io/badge/Built%20with-ccpmbuild-orange.svg)](https://github.com/deleranax/ccpmbuild)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/Deleranax/ccpm/build.yml?branch=main&label=Build)](https://github.com/Deleranax/ccpm/actions)

## About

CCPM is a package manager for [CC:Tweaked](https://tweaked.cc/), which simplifies the process of managing code across your in-game computers.
It allows you to easily install, update, and manage Lua programs and libraries on your ComputerCraft computers.

**Key Features:**
- ⚡ **Intuitive Interface** - Install, update, and manage packages with an intuitive CLI
- 🛡️ **Transaction System** - Provides a transaction system with automatic recovery from interruptions
- 🔗 **Automatic Dependencies** - Resolve package dependencies automatically across multiple repositories with priority-based resolution
- 🌐 **Multiple Repositories** - Support for custom package repositories hosted on GitHub, GitLab, or any static web server

CCPM simplifies the process of managing code across your in-game computers. The dependency resolution system ensures that all required packages are installed and up-to-date, making it easy to manage complex projects.
The dependency resolution is unversioned, meaning that it will always use the latest version of a package (meaning that unmaintained packages may break at any time).

## Packages

The official CCPM repository includes a variety of packages to help you build projects in CC:Tweaked. Here's a quick overview of some packages:

**Core Packages:**
- `ccpm-cli` - The CCPM command-line interface for managing packages
- `libccpm` - Core library providing CCPM's package management functionality

**User Interface:**
- `cuicui` - Modular immediate mode GUI library for building interactive interfaces

**Utilities:**
- `flagger` - Simple flag utility library
- `commons-fileutils` - File manipulation utilities
- `commons-string` - String manipulation utilities
- `commons-table` - Table manipulation utilities
- `commons-textutils` - Text formatting and manipulation utilities

**Networking:**
- `rednet-router` - Router for Rednet packets
- `rednet-utils` - Additional Rednet utilities

**Data & Encryption:**
- `lockbox` - Library for encrypting and decrypting data
- `libdeflate` - Library for deflating and inflating data (compression)
- `uuid` - UUID generation library
- `schematics` - Lua structure schema definition library

**Specialized:**
- `scada-rtu` - SCADA Remote Terminal Unit for industrial control systems

This is not an exhaustive list. To see all available packages, use `ccpm list available` on your computer or explore the [packages directory](https://github.com/Deleranax/ccpm/tree/main/packages) on GitHub.

## Installation

You can install CCPM with the latest version of the installer downloaded directly from GitHub using the following command:

```sh
wget run https://raw.githubusercontent.com/Deleranax/ccpm/refs/heads/main/installer.lua
```

You can also install CCPM from Pastebin using the following command:

```sh
pastebin run 1JCdz59p
```

The installer will add this repository to your CCPM configuration and download the latest version of CCPM.

## Usage

CCPM provides a simple command-line interface for managing packages. Here are some basic commands:

```sh
ccpm install <package>      # Install a package
ccpm uninstall <package>    # Uninstall a package
ccpm update                 # Update package index and repository manifests
ccpm upgrade                # Upgrade all packages (or specific packages)
ccpm list <available|installed> [query]  # List packages
ccpm repo <add|remove|list> # Manage repositories
ccpm status                 # Show current status
ccpm recover                # Recover a stopped transaction
ccpm help                   # Show detailed help
```

For more detailed information about each command, use `ccpm help` on any CCPM-enabled computer.

### Multiple Repository Support

CCPM supports multiple package repositories with configurable priorities. You can add custom repositories to distribute
your own packages alongside the official CCPM repository. See the [Setting Up Your Own Repository](#setting-up-your-own-repository-git-forges)
section for detailed instructions on creating and hosting your own package repository.

### Transaction System

CCPM uses a transaction system to ensure safe package operations. If an installation or uninstallation is interrupted,
you can recover the transaction using `ccpm recover`. CCPM stores its data (package database, repository information,
and transaction state) in `~/.data/ccpm`.

### Directory Structure

CCPM can manage files anywhere on the system, but follows these recommended conventions:

- `/lib/your-lib.lua` or `/lib/your-lib/init.lua` - Library files that can be imported with `require("your-lib")`.
  Submodules can be accessed using dot-separated paths (e.g., `require("your-lib.submodule")`).
- `/bin/your-bin.lua` - Executable programs that can be run directly from the shell using `your-bin`
- `/startup/50-your-startup.lua` - Startup scripts that run automatically at boot. The leading number dictates
  priority (lower numbers run first). It is recommended not to use numbers below 10 as they may interfere with CCPM's
  startup sequence.

When you install a package, CCPM automatically places its files in the appropriate directories based on the package
structure.

## Setting Up Your Own Repository (Git Forges)

You can set up your own CCPM repository to distribute packages for CC:Tweaked on any Git hosting platform. GitHub is
the easiest option with full automation support, but CCPM also natively supports URL conversion for public instances
of GitLab, Bitbucket, Codeberg, and SourceHut. For self-hosted instances (Gitea, Forgejo, self-hosted GitLab, etc.),
you'll need to use the raw URL directly.

### Prerequisites

#### For GitHub

- A GitHub account
- Basic knowledge of Git and GitHub

#### For Other Git Forges

- An account on your chosen Git forge (GitLab, Bitbucket, Codeberg, Gitea/Forgejo, SourceHut, etc.)
- Basic knowledge of Git

### Repository Structure

All Git forges use the same basic structure:

```
your-repo/
├── .github/           (GitHub only)
│   └── workflows/
│       └── build.yml
├── packages/
│   └── your-package/
│       ├── manifest.json
│       └── source/
│           └── (your package files)
└── manifest.json  (repository metadata)
```

Copy the root `manifest.json` from this repository. For GitHub, also copy `.github/workflows/build.yml` (which uses the `ccpmbuild-action`).
For other forges, you'll need to create your own CI/CD configuration or build manually using `ccpmbuild`.

The user will most likely have this repository configured as package source in their CCPM instances, which means that you
**don't need to copy** this repository's packages in your own repository if you just wish to add them as dependencies for
your own packages. However, you can override the default packages if you need to by setting a lower priority in your
repository's `manifest.json` file and adding packages with the same name in your own repository.

> [!IMPORTANT]
> As per the GNU General Public License v3.0, you are free to use, modify, and distribute this software but you must
> also provide the source code for any modifications you make and state the changes you have made. You must also
> include a copy of the GNU General Public License v3.0 in your repository and credit the original authors
> (`Alexandre Leconte <aleconte@dwightstudio.fr>`).

### Initial Setup

1. Create a new repository on your Git forge and clone it locally

2. Add the repository structure files to the `main` branch

3. Configure the repository `manifest.json` at the root with the correct URL for your Git forge:

```json
{
  "name": "Your Repository Name",
  "url": "https://raw.githubusercontent.com/your-username/your-repo/refs/heads/dist/",
  "priority": -10
}
```

- `name`: A friendly name for your repository
- `url`: The URL to your `dist` branch (see URL patterns below)
- `priority`: Repository priority (lower numbers = higher priority, `0` is the priority of the official CCPM repository)

Common URL patterns for supported Git forges:
- GitHub: `https://raw.githubusercontent.com/username/repo/refs/heads/dist/`
- GitLab (gitlab.com): `https://gitlab.com/username/repo/-/raw/dist/`
- Bitbucket: `https://bitbucket.org/username/repo/raw/dist/`
- Codeberg: `https://codeberg.org/username/repo/raw/branch/dist/`
- SourceHut: `https://git.sr.ht/~username/repo/blob/dist/`

For self-hosted instances (Gitea, Forgejo, self-hosted GitLab, etc.), use the pattern appropriate for your instance:
- Gitea/Forgejo: `https://your-instance.com/username/repo/raw/branch/dist/`
- Self-hosted GitLab: `https://your-gitlab.com/username/repo/-/raw/dist/`

> [!NOTE]
> The `url` field in the manifest enables seamless migration between hosting services. When users run `ccpm update`,
> CCPM fetches and updates the manifest from each repository. This means if you move to a different hosting platform,
> you only need to host the updated manifest (with the new URL) on your old platform, and users will automatically
> follow to the new location on their next update.

4. Create the `dist` branch and push it (required before the first build):

```sh
git checkout --orphan dist
git rm -rf .
git commit --allow-empty -m "Initialize dist branch"
git push origin dist
git checkout main
```

5. Configure permissions and push `main`:

#### For GitHub

Configure GitHub Actions permissions:
- Go to your repository settings
- Navigate to `Actions` → `General`
- Under "Workflow permissions", select `Read and write permissions`
- Save the changes

Finally, push the `main` branch:
```sh
git push origin main
```

#### For Other Git Forges

```sh
git push origin main
```

> [!NOTE]
> For other Git forges, using a separate `dist` branch is recommended but not required. If you prefer to use the same
> branch for both source and built packages, you can skip creating the `dist` branch and modify your repository's
> `manifest.json` URL to point to `main` instead (e.g., change `/dist/` to `/main/` in the URL). However, this may
> clutter your main branch with built artifacts.

You'll need to configure CI/CD permissions separately if using automated builds (see CI/CD section below).

### Adding Packages

Each package in the `packages/` directory must have:

1. A `manifest.json` file with the following required fields:
```json
{
  "description": "Your package description",
  "license": "GPL-3.0-or-later",
  "authors": ["Your Name <email@example.com>"],
  "maintainers": ["Your Name <email@example.com>"],
  "version": "1.0.0",
  "dependencies": ["other-package"]
}
```

> [!NOTE]
> The `license` field should be a valid [SPDX identifier](https://spdx.org/licenses/).

2. A `source/` directory containing your Lua files and resources

### Building Locally

CCPM uses [`ccpmbuild`](https://github.com/deleranax/ccpmbuild), a Rust-based build tool for building and managing CCPM repositories.

#### Installing ccpmbuild

Download pre-built binaries from the [ccpmbuild releases page](https://github.com/deleranax/ccpmbuild/releases), use the container image, or build from source:

```sh
# Using the container
docker pull ghcr.io/deleranax/ccpmbuild:latest

# Or build from source
git clone https://github.com/deleranax/ccpmbuild.git
cd ccpmbuild
cargo build --release
```

#### Building Your Repository

To test your repository locally before pushing:

```sh
ccpmbuild build <SOURCE_PATH> <DEST_PATH>
```

Where:
- `<SOURCE_PATH>` is the path to the directory containing your `manifest.json` and `packages/` directory (typically `.`)
- `<DEST_PATH>` is the path where the `pool/` directory will be created

To build with minification:

```sh
ccpmbuild build --minify <SOURCE_PATH> <DEST_PATH>
```

This will create a `pool/` directory with all built packages and the index.

> [!NOTE]
> The `pool/` directory is included in `.gitignore` to prevent it from being committed to the `main` branch during
> local testing. The build process on the `dist` branch will generate this directory automatically.

### CI/CD and Deployment

> [!NOTE]
> Running `ccpmbuild` with an existing `pool/` directory will update the index. By default, old package versions are removed.
> If you want to keep older versions alongside new ones to maintain a version history, use the `keep` option in your CI/CD configuration.

#### GitHub Actions (Automated)

CCPM uses the [`ccpmbuild-action`](https://github.com/deleranax/ccpmbuild-action) for automated builds on GitHub.

When you push to the `main` branch, the GitHub Actions workflow automatically:
- Checks out your code
- Switches to the `dist` branch
- Runs `ccpmbuild` to:
  - Read all packages from `packages/`
  - Compress and package each one as `.ccp` files
  - Generate an `index.json` with package metadata
  - Store everything in the `pool/` directory
- Commits and pushes the built packages to the `dist` branch

The `ccpmbuild-action` supports several options:
- `minify`: Whether to minify Lua source code (default: `true`)
- `source-path`: Repository source path containing `manifest.json` and `packages/` (default: `.`)
- `branch-name`: Distribution branch name for built packages (default: `dist`)
- `keep`: Whether to keep old package versions in the pool (default: `false`)
- `keep-history`: Whether to maintain git history in the distribution branch (default: `false`)

For detailed usage and examples, see the [ccpmbuild-action documentation](https://github.com/deleranax/ccpmbuild-action).

Users can then configure CCPM to use your repository by pointing to the `dist` branch.

#### Other CI/CD Platforms (Automated, for experienced users)

Most Git forges provide CI/CD capabilities. You can use `ccpmbuild` in your CI/CD pipelines:

- GitLab CI: Create `.gitlab-ci.yml`
- Gitea/Forgejo Actions: Similar to GitHub Actions syntax
- Bitbucket Pipelines: Create `bitbucket-pipelines.yml`

Key CI/CD requirements:
- Trigger on pushes to `main` branch
- Check out repository with full history
- Install or use pre-built `ccpmbuild` binary (or use the container image)
- Switch to `dist` branch
- Run `ccpmbuild build [--minify] <SOURCE_PATH> <DEST_PATH>`
- Commit and push changes to `dist` branch
- Configure write permissions and authentication (SSH keys, access tokens, etc.)

You can download pre-built `ccpmbuild` binaries from the [releases page](https://github.com/deleranax/ccpmbuild/releases), use the container image at `ghcr.io/deleranax/ccpmbuild:latest`, or build from source using the provided Dockerfile.

#### Manual Deployment

If you prefer not to set up CI/CD, you can deploy manually:

```sh
# On main branch, build packages locally
ccpmbuild build --minify . .

# Switch to dist branch and deploy
git checkout dist
git add pool/
git commit -m "Update packages"
git push origin dist
git checkout main
```

### Using Your Repository

Once set up, users can add your repository to their local CCPM installation with the following commands:

For supported Git forges (GitHub, public GitLab, Bitbucket, Codeberg, SourceHut), users can use the public-facing
repository URL:

```sh
ccpm repo add https://github.com/your-username/your-repo.git
ccpm update
```

Or for other forges:
```sh
ccpm repo add https://your-forge.com/username/repo.git
ccpm update
```

CCPM will automatically convert these URLs to the appropriate raw file URLs. For self-hosted Git forges (Gitea,
Forgejo, self-hosted GitLab, etc.) or if automatic conversion doesn't work, users must directly use the raw URL
specified in your repository's `manifest.json` file:

```sh
ccpm repo add https://raw.githubusercontent.com/your-username/your-repo/refs/heads/dist/
ccpm update
```

The `ccpm repo add` command adds your repository to the user's CCPM configuration, and `ccpm update` refreshes the
package index to include packages from your repository.

## Setting Up Your Own Repository (Other Hosting Methods)

You can host a CCPM repository on any web server or hosting service that can serve files over HTTP/HTTPS, even if
it's not a Git forge. This provides maximum flexibility for custom hosting solutions.

### Prerequisites

- A web server or hosting service (static file hosting, CDN, custom server, etc.)
- `ccpmbuild` installed locally for building packages (see [ccpmbuild repository](https://github.com/deleranax/ccpmbuild))
- A way to upload/deploy files to your hosting service

### Setup Process

1. Build your packages locally using `ccpmbuild`:

```sh
ccpmbuild build --minify <SOURCE_PATH> <DEST_PATH>
```

This generates a `pool/` directory containing:
- Compressed `.ccp` package files
- An `index.json` file with package metadata
- A `manifest.json` file

2. Configure the `manifest.json` with your hosting URL:

```json
{
  "name": "Your Repository Name",
  "url": "https://your-hosting-service.com/path/to/packages/",
  "priority": -10
}
```

The `url` should point to where you'll host the `pool/` directory contents (the URL should end with a trailing
slash).

3. Upload the entire `pool/` directory contents to your hosting service at the specified URL path

4. Users can add your repository:

```sh
ccpm repo add https://your-hosting-service.com/path/to/packages/
ccpm update
```

### Updating Packages

When you update packages:

1. Run `ccpmbuild build --minify <SOURCE_PATH> <DEST_PATH>` locally
2. Upload the updated `pool/` directory contents to your hosting service

The manual deployment process is the same regardless of your hosting platform. You can automate this with your own
scripts or deployment tools.

> [!NOTE]
> The `url` field in the manifest enables seamless migration between hosting services. When users run `ccpm update`,
> CCPM fetches and updates the manifest from each repository. This means if you move to a different hosting platform,
> you only need to host the updated manifest (with the new URL) on your old platform, and users will automatically
> follow to the new location on their next update.

## License

CCPM is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for more information.

This repository contains packages composed of modified or unmodified third-party code, which may be subject to their own
licenses. Please refer to the individual package's manifest, documentation or source code for more information.
