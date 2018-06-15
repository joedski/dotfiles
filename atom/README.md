My Atom Config
==============



## Command Flows


### Initialize a New System

```sh
bash ~/.atom/commands/install-packages.sh
```


### Update Packages and Update Packages File

```sh
apm update
bash ~/.atom/commands/update-packages-file.sh
```


### Soft-Sync Packages by Disabling Unlisted and Enabling Listed

```sh
bash ~/.atom/commands/disable-unlisted-enable-listed.sh
```


#### Hard-Sync Packages by Uninstalling Unlisted

```sh
bash ~/.atom/commands/disable-unlisted-enable-listed.sh
bash ~/.atom/commands/uninstall-disabled.sh
```



> NOTE: The `grep .` seen in places is to skip empty lines.

Helpful commands:
- Install remote list: `apm install --packages-file ~/.atom/packages-list`
- See what packages are out of date: `apm upgrade --list` (And update them if so desired)
- Update the list: `apm list --bare --installed --enabled | sort | grep . > ~/.atom/packages-list`
- See discrepancy between installed and listed:
  - All (even disabled): `diff <(apm list --bare --installed | sort) packages-list`
    - NOTE: Will show differences in versions, too.
- Disable installed packages not in the list:
  - `diff <(apm list --bare --installed | sort | grep .) <(grep . packages-list) | grep '^<' | sed '/^< /s///; /@.*$/ s///' | xargs apm disable`
    - `apm` accepts multiple packages for `apm disable`, so no need for `-n 1`.
    - Using `apm uninstall` to remove them.
- See currently disabled packages:
  - `diff <(apm list --bare --installed | sort | grep .) <(apm list --bare --installed --enabled | sort | grep .) | grep '^<' | sed '/^< /s///; /@.*$/ s///'`

Actual commands used:
- Update Packages File: Updates the Packages File to the list of currently installed and enabled packages.
- Sync: Installs the packages listed in the Packages File that are not currently installed.
  - NOTE: May leave old versions.  Should probably run Update afterwards.
- Update: Updates currently installed packages then updates the Packages File.
- Disable Unlisted: Disables any packages not listed in the Packages File.
- Uninstall Disabled: Uninstalls any packages that are currently disabled.  Mostly for cleaning up lists.
