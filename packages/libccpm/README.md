# Package `libccpm`

## Events

CCPM generates a lot of events in order to make the usage of the package manager interractive.

| Event name                | Description                                                       | Resolution                                                        |
|:-------------------------:|:-----------------------------------------------------------------:|:-----------------------------------------------------------------:|
| `ccpm_backup`             | Created backup of unparsable storage file  (path in arg1).        | N/A                                                               |
| `ccpm_not_saved`          | Could not save storage file (path in arg1).                       | Free space on disk, change path and call `database.save()` again. |
