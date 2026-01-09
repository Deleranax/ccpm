# Package `libccpm`

## Events

CCPM generates a lot of events in order to make the usage of the package manager interractive.

| Event name                | Description                                                       | Arguments                                                         |
|:-------------------------:|:-----------------------------------------------------------------:|:-----------------------------------------------------------------:|
| `ccpm_loading`            | Loading local database.                                           | N/A                                                               |
| `ccpm_backup`             | Created backup of unparsable storage file.                        | [1] File path                                                     |
| `ccpm_saving`             | Saving local database.                                            | N/A                                                               |
| `ccpm_not_saved`          | Could not save storage file.                                      | [1] File path                                                     |
| `ccpm_updating_index`     | Updating package index.                                           | N/A                                                               |
