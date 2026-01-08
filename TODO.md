# CCPM TODO List

This document outlines the development roadmap for the ComputerCraft Package Manager (CCPM).

## Core Package Management

### Package Operations
- [ ] Implement package installation system
  - [ ] Download package from repository
  - [ ] Verify package integrity (digest verification)
  - [ ] Extract package to temporary location
  - [ ] Install files to target directory
  - [ ] Register package in local database
  - [ ] Handle file conflicts during installation
  - [ ] Support dry-run mode for testing installations

- [ ] Implement package uninstallation system
  - [ ] Remove package files from filesystem
  - [ ] Unregister package from local database
  - [ ] Handle orphaned dependencies (packages no longer needed)
  - [ ] Preserve user configuration files during uninstall
  - [ ] Support force-uninstall for broken packages

- [ ] Implement package upgrade/update system
  - [ ] Check for newer versions in repositories
  - [ ] Download and install newer versions
  - [ ] Handle dependency changes during upgrades
  - [ ] Rollback capability for failed upgrades

- [ ] Implement package verification
  - [ ] Verify installed files match expected digests
  - [ ] Detect corrupted or modified files
  - [ ] Report missing files

### Dependency Resolution
- [ ] Implement dependency resolver
  - [ ] Build dependency tree for package installation
  - [ ] Detect circular dependencies
  - [ ] Choose optimal package versions when conflicts exist
  - [ ] Handle version constraints (>=, <=, ==, etc.)
  - [ ] Resolve dependencies recursively
  - [ ] Support optional dependencies
  
- [ ] Implement reverse dependency tracking
  - [ ] Track which packages depend on a given package
  - [ ] Uninstall all dependent packages together
  - [ ] Detect and report orphaned packages

### Transaction System
- [ ] Implement transaction framework
  - [ ] Create transaction object to track planned operations
  - [ ] Validate all dependencies before starting transaction
  - [ ] Check disk space requirements
  - [ ] Check for file conflicts across all packages
  - [ ] Execute transaction steps atomically
  - [ ] Implement rollback mechanism for failed transactions
  - [ ] Persist transaction state to disk (resume after crash/reboot)
  - [ ] Clear transaction lock after completion

- [ ] Transaction validation
  - [ ] Verify all required dependencies are available
  - [ ] Ensure no circular dependencies exist
  - [ ] Check that no required packages will be removed
  - [ ] Validate repository availability
  - [ ] Check write permissions for target directories

## Repository Management

### Repository Operations
- [ ] Complete `repository.add()` implementation
  - [ ] Validate repository URL format
  - [ ] Download and parse repository index
  - [ ] Store repository in repositories_index
  - [ ] Handle repository already exists
  - [ ] Support repository metadata (name, description)
  - [ ] Verify repository authenticity (optional signatures)

- [ ] Complete `repository.remove()` implementation
  - [ ] Remove repository from repositories_index
  - [ ] Handle canonical vs. alternative URLs
  - [ ] Optionally mark packages from removed repository as unavailable
  - [ ] Prevent removal if installed packages depend on it

- [ ] Implement repository update system
  - [ ] Refresh index from all repositories
  - [ ] Merge multiple repository indices
  - [ ] Handle repository conflicts (same package in multiple repos)
  - [ ] Cache repository data with expiration
  - [ ] Support incremental updates

- [ ] Implement repository prioritization
  - [ ] Assign priority levels to repositories
  - [ ] Use priority to resolve package conflicts
  - [ ] Allow user to set repository preferences
  - [ ] Support pinning packages to specific repositories

### Repository Index
- [ ] Enhance index management
  - [ ] Store package metadata from all repositories
  - [ ] Track which repository provides each package
  - [ ] Handle multiple versions of same package
  - [ ] Support searching packages by name/description
  - [ ] Cache repository indices locally

## Package Resolution & Download

### Package Discovery
- [ ] Implement package search functionality
  - [ ] Search by package name
  - [ ] Search by description/tags
  - [ ] Search by author
  - [ ] Filter by installed/available status

- [ ] Implement package information retrieval
  - [ ] Show package details (version, size, dependencies)
  - [ ] Display package metadata (authors, license, maintainers)
  - [ ] Show package files list
  - [ ] Display reverse dependencies

### Download System
- [ ] Implement package downloader
  - [ ] Download packages from HTTP/HTTPS repositories
  - [ ] Verify download integrity (digest check)
  - [ ] Handle download failures and retries
  - [ ] Support resumable downloads
  - [ ] Cache downloaded packages
  - [ ] Download all dependencies recursively before installing

- [ ] Implement download queue
  - [ ] Queue multiple packages for download
  - [ ] Download packages in parallel (if possible)
  - [ ] Show download progress
  - [ ] Handle download cancellation

## Event System

### Core Events
- [x] `ccpm_loading` - Loading local database
- [x] `ccpm_backup` - Created backup of unparsable storage file
- [x] `ccpm_saving` - Saving local database
- [x] `ccpm_not_saved` - Could not save storage file

### Package Operation Events
- [ ] `ccpm_package_installing` - Installing package [name, version]
- [ ] `ccpm_package_installed` - Package installed successfully [name, version]
- [ ] `ccpm_package_install_failed` - Package installation failed [name, version, error]
- [ ] `ccpm_package_uninstalling` - Uninstalling package [name, version]
- [ ] `ccpm_package_uninstalled` - Package uninstalled successfully [name, version]
- [ ] `ccpm_package_uninstall_failed` - Package uninstallation failed [name, version, error]
- [ ] `ccpm_package_upgrading` - Upgrading package [name, old_version, new_version]
- [ ] `ccpm_package_upgraded` - Package upgraded successfully [name, new_version]

### Dependency Events
- [ ] `ccpm_resolving_dependencies` - Resolving dependencies [package_name]
- [ ] `ccpm_dependencies_resolved` - Dependencies resolved [dependency_list]
- [ ] `ccpm_dependency_conflict` - Dependency conflict detected [details]
- [ ] `ccpm_circular_dependency` - Circular dependency detected [cycle]

### Transaction Events
- [ ] `ccpm_transaction_start` - Transaction started [transaction_id]
- [ ] `ccpm_transaction_validating` - Validating transaction [transaction_id]
- [ ] `ccpm_transaction_executing` - Executing transaction [transaction_id]
- [ ] `ccpm_transaction_complete` - Transaction completed successfully [transaction_id]
- [ ] `ccpm_transaction_failed` - Transaction failed [transaction_id, error]
- [ ] `ccpm_transaction_rollback` - Rolling back transaction [transaction_id]
- [ ] `ccpm_transaction_rolled_back` - Transaction rolled back [transaction_id]

### Repository Events
- [ ] `ccpm_repository_adding` - Adding repository [url]
- [ ] `ccpm_repository_added` - Repository added [url, name]
- [ ] `ccpm_repository_removing` - Removing repository [url]
- [ ] `ccpm_repository_removed` - Repository removed [url]
- [ ] `ccpm_repository_updating` - Updating repository index [url]
- [ ] `ccpm_repository_updated` - Repository index updated [url, package_count]
- [ ] `ccpm_repository_failed` - Repository operation failed [url, error]

### Download Events
- [ ] `ccpm_download_start` - Download started [package_name, url]
- [ ] `ccpm_download_progress` - Download progress [package_name, bytes_downloaded, total_bytes]
- [ ] `ccpm_download_complete` - Download completed [package_name, path]
- [ ] `ccpm_download_failed` - Download failed [package_name, error]
- [ ] `ccpm_download_verifying` - Verifying download [package_name]
- [ ] `ccpm_download_verified` - Download verified [package_name]

## Database & Storage

### Local Database
- [ ] Enhance packages_database structure
  - [ ] Store installed package manifests
  - [ ] Track installation date/time
  - [ ] Store installation reason (explicit/dependency)
  - [ ] Track file ownership per package
  - [ ] Support package metadata updates

- [ ] Implement database queries
  - [ ] List all installed packages
  - [ ] Find package by name
  - [ ] List packages by installation date
  - [ ] List explicitly installed vs dependencies
  - [ ] Query reverse dependencies

### File System Management
- [ ] Define package installation directories
  - [ ] System packages location (e.g., /usr/lib/)
  - [ ] User packages location (e.g., ~/.local/lib/)
  - [ ] Binary/executable location (e.g., /usr/bin/)
  - [ ] Configuration location (e.g., /etc/ccpm/)

- [ ] Implement file conflict detection
  - [ ] Check if files already exist before installation
  - [ ] Support file replacement with user confirmation
  - [ ] Handle symlinks and directories

## CLI Interface (Future)

- [ ] Design command-line interface
  - [ ] `ccpm install <package>` - Install package
  - [ ] `ccpm remove <package>` - Remove package
  - [ ] `ccpm update` - Update repository indices
  - [ ] `ccpm upgrade` - Upgrade all packages
  - [ ] `ccpm search <query>` - Search packages
  - [ ] `ccpm info <package>` - Show package information
  - [ ] `ccpm list` - List installed packages
  - [ ] `ccpm repo add <url>` - Add repository
  - [ ] `ccpm repo remove <url>` - Remove repository
  - [ ] `ccpm repo list` - List repositories

## Testing & Quality

- [ ] Create test suite
  - [ ] Test package unpacking
  - [ ] Test dependency resolution
  - [ ] Test transaction rollback
  - [ ] Test repository management
  - [ ] Test database persistence
  - [ ] Test event generation

- [ ] Error handling improvements
  - [ ] Graceful handling of network failures
  - [ ] Handle filesystem errors (disk full, permissions)
  - [ ] Validate user inputs
  - [ ] Provide meaningful error messages

## Documentation

- [ ] Write user documentation
  - [ ] Installation guide
  - [ ] Usage examples
  - [ ] Package manifest format specification
  - [ ] Repository format specification
  - [ ] Event system documentation

- [ ] Write developer documentation
  - [ ] API reference for libccpm
  - [ ] Package creation guide
  - [ ] Repository setup guide
  - [ ] Contributing guidelines
