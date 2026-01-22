# ComputerCraft Package Manager (CCPM)

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
- Python 3.x (for local testing)

#### For Other Git Forges

- An account on your chosen Git forge (GitLab, Bitbucket, Codeberg, Gitea/Forgejo, SourceHut, etc.)
- Basic knowledge of Git
- Python 3.x installed locally

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
├── build.py
└── manifest.json  (repository metadata)
```

Copy `build.py` and the root `manifest.json` from this repository. For GitHub, also copy `.github/workflows/build.yml`.
For other forges, you'll need to create your own CI/CD configuration or deploy manually.

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

To test your repository locally before pushing:

```sh
python build.py
```

This will create a `pool/` directory with all built packages and the index.

> [!NOTE]
> The `pool/` directory is included in `.gitignore` to prevent it from being committed to the `main` branch during
> local testing. The build process on the `dist` branch will generate this directory automatically.

To repair a corrupted index:

```sh
python build.py --repair
```

### CI/CD and Deployment

> [!NOTE]
> Running `build.py` with an existing `pool/` directory will update the index and keep older versions of packages
> alongside the new ones. This allows CCPM to maintain a version history. If you prefer to clean the repository at
> each build, you can add a deletion step in your CI/CD workflow or manually remove the `pool/` directory before
> running the build script.

#### GitHub Actions (Automated)

When you push to the `main` branch, the GitHub Actions workflow (`build.yml`) automatically:
- Checks out your code
- Switches to the `dist` branch
- Runs `build.py` to:
  - Read all packages from `packages/`
  - Compress and package each one as `.ccp` files
  - Generate an `index.json` with package metadata
  - Store everything in the `pool/` directory
- Commits and pushes the built packages to the `dist` branch

Users can then configure CCPM to use your repository by pointing to the `dist` branch.

#### Other CI/CD Platforms (Automated, for experienced users)

Most Git forges provide CI/CD capabilities. Adapt the workflow from `.github/workflows/build.yml` to your platform:

- GitLab CI: Create `.gitlab-ci.yml`
- Gitea/Forgejo Actions: Similar to GitHub Actions syntax
- Bitbucket Pipelines: Create `bitbucket-pipelines.yml`

Key CI/CD requirements:
- Trigger on pushes to `main` branch
- Check out repository with full history
- Switch to `dist` branch
- Run `python build.py`
- Commit and push changes to `dist` branch
- Configure write permissions and authentication (SSH keys, access tokens, etc.)

The `build.py` script is platform-agnostic and works on any system with Python 3.x.

#### Manual Deployment

If you prefer not to set up CI/CD, you can deploy manually:

```sh
# On main branch, build packages locally
python build.py

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
- Python 3.x installed locally for building packages
- A way to upload/deploy files to your hosting service

### Setup Process

1. Build your packages locally using the same structure and `build.py` script:

```sh
python build.py
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

1. Run `python build.py` locally
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
