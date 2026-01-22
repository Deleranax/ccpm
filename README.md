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

## Setting Up Your Own Repository

You can set up your own CCPM repository to distribute packages for CC:Tweaked. This repository uses a GitHub Actions workflow to automatically build and publish packages.

### Prerequisites

- A GitHub account
- Basic knowledge of Git and GitHub
- Python 3.x (for local testing)

### Initial Setup

1. Create a new repository on GitHub. Clone it and add files to the `main` branch based on this template structure:
```
your-repo/
├── .github/
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

You can copy the files (`build.py`, `.github/workflows/build.yml`, and `manifest.json`) from this repository and modify them as needed.
You can (but don't need to) copy the packages (`packages/`) from this repository and modify them as needed. The user will most likely have
this repository configured as package source in their CCPM instances. You can override the default packages by setting a lower priority in
your repository's `manifest.json` file.

> [!IMPORTANT]
> As per the GNU General Public License v3.0, you are free to use, modify, and distribute this software but you must also provide the source
> code for any modifications you make and state the changes you have made. You must also include a copy of the GNU General Public License v3.0
> in your repository and credit the original authors (`Alexandre Leconte <aleconte@dwightstudio.fr>`).

2. Configure the repository `manifest.json` at the root of your repository:
```json
{
  "name": "Your Repository Name",
  "url": "https://raw.githubusercontent.com/your-username/your-repo/refs/heads/dist/",
  "priority": -10
}
```

- `name`: A friendly name for your repository
- `url`: The URL to your `dist` branch (this should match the actual URL users will use)
- `priority`: Repository priority (lower numbers = higher priority, `0` is the priority of the official CCPM repository)

3. Create the `dist` branch (required before the first build):
```sh
git checkout --orphan dist
git rm -rf .
git commit --allow-empty -m "Initialize dist branch"
git push origin dist
git checkout main
```

4. Configure GitHub Actions permissions:
- Go to your repository settings
- Navigate to `Actions` → `General`
- Under "Workflow permissions", select `Read and write permissions`
- Save the changes

5. Push the `dist` and `main` branches (in this order):
```sh
git push origin dist
git push origin main
```

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

### How It Works

1. When you push to the `main` branch, the GitHub Actions workflow (`build.yml`) automatically:
- Checks out your code
- Switches to the `dist` branch
- Runs `build.py` to:
  - Read all packages from `packages/`
  - Compress and package each one as `.ccp` files
  - Generate an `index.json` with package metadata
  - Store everything in the `pool/` directory
- Commits and pushes the built packages to the `dist` branch

2. Users can then configure CCPM to use your repository by pointing to the `dist` branch

### Building Locally

To test your repository locally before pushing:

```sh
python build.py
```

This will create a `pool/` directory with all built packages and the index.

**Note:** The `pool/` directory is included in `.gitignore` to prevent it from being committed to the `main` branch during local testing. The build process on the `dist` branch will generate this directory automatically.

To repair a corrupted index:

```sh
python build.py --repair
```

### Using Your Repository

Once set up, users can add your repository to their local CCPM installation with the following commands:

```sh
ccpm repo add https://raw.githubusercontent.com/your-username/your-repo/refs/heads/dist/
ccpm update
```

The `ccpm repo add` command adds your repository to the user's CCPM configuration, and `ccpm update` refreshes the package index to include packages from your repository.

## License

CCPM is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for more information.

This repository contains packages composed of modified or unmodified third-party code, which may be subject to their
own licenses. Please refer to the individual package's manifest, documentation or source code for more information.
