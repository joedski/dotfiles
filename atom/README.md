My Atom Config
==============

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
