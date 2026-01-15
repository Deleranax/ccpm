# Package `libccpm`

## Events

CCPM generates a lot of events in order to make the usage of the package manager interractive.

| Event name                     | Description                                                       | Arguments                                                            |
|:------------------------------:|:-----------------------------------------------------------------:|:--------------------------------------------------------------------:|
| `ccpm_backup`                  | Created backup of unparsable storage file.                        | [1] File path                                                        |
| `ccpm_index_update_start`      | Start updating package index.                                     | [1] Number of repositories to update                                 |
| `ccpm_index_updating`          | Downloading repository package index.                             | [1] Repository UUID                                                  |
| `ccpm_index_updated`           | Package index updated.                                            | [1] Repository UUID                                                  |
| `ccpm_index_not_updated`       | Failed to update package index.                                   | [1] Repository UUID, [2] Error message                               |
| `ccpm_index_update_end`        | Finished updating package index.                                  | [1] Number of repositories updated                                   |
| `ccpm_package_downloading`     | Downloading package.                                              | [1] Package name, [2] Package version                                |
| `ccpm_package_downloaded`      | Package downloaded.                                               | [1] Package name, [2] Package version                                |
| `ccpm_package_not_downloaded`  | Failed to download package.                                       | [1] Package name, [2] Package version, [3] Error message             |
| `ccpm_package_installing`      | Installing package.                                               | [1] Package name, [2] Package version                                |
| `ccpm_package_installed`       | Package installed.                                                | [1] Package name, [2] Package version                                |
| `ccpm_package_not_installed`   | Failed to install package.                                        | [1] Package name, [2] Package version, [3] Error message             |
| `ccpm_package_uninstalling`    | Uninstalling package.                                             | [1] Package name, [2] Package version                                |
| `ccpm_package_uninstalled`     | Package uninstalled.                                              | [1] Package name, [2] Package version                                |
| `ccpm_package_not_uninstalled` | Failed to uninstall package.                                      | [1] Package name, [2] Package version, [3] Error message             |
| `ccpm_transaction_checking`    | Checking packages dependencies of  transaction.                   | N/A                                                                  |
| `ccpm_transaction_downloading` | Started downloading packages required by transaction.             | [1] Number of packages to download                                   |
| `ccpm_transaction_uninstalling`| Started uninstalling packages required by transaction.            | [1] Number of packages to uninstall                                  |
| `ccpm_transaction_installing`  | Started installing packages required by transaction.              | [1] Number of packages to install                                    |
| `ccpm_transaction_completed`   | Transaction completed.                                            | [1] Number of packages installed, [2] Number of packages uninstalled |
| `ccpm_transaction_failed`      | Transaction failed.                                               | [1] Error message                                                    |
| `ccpm_transaction_rolled_back` | Transaction rolled back.                                          | N/A                                                                  |
| `ccpm_file_conflict_storage`   | A package file clashes over local storage.                        | [1] Package name, [2] File path                                      |
| `ccpm_file_conflict_package`   | A package file clashes over another package.                      | [1] Package name, [2] Package name, [3] File path                    |
