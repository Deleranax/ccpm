# Package `libccpm`

## Events

CCPM generates a lot of events in order to make the usage of the package manager interractive.

| Event name                | Description                                                       | Arguments                                                         |
|:-------------------------:|:-----------------------------------------------------------------:|:-----------------------------------------------------------------:|
| `ccpm_loading`            | Loading local database.                                           | N/A                                                               |
| `ccpm_backup`             | Created backup of unparsable storage file.                        | [1] File path                                                     |
| `ccpm_saving`             | Saving local database.                                            | N/A                                                               |
| `ccpm_not_saved`          | Could not save storage file.                                      | [1] File path                                                     |
| `ccpm_index_update_start` | Start updating package index.                                     | [1] Number of repositories to update                              |
| `ccpm_index_updating`     | Downloading repository package index.                             | [1] Repository UUID                                               |
| `ccpm_index_updated`      | Package index updated.                                            | [1] Repository UUID                                               |
| `ccpm_index_not_updated`  | Failed to update package index.                                   | [1] Repository UUID, [2] Error message                            |
| `ccpm_index_update_end`   | Finished updating package index.                                  | N/A                                                               |
