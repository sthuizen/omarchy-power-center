# Power Center for Omarchy

Power Center expands Omarchy's excellent battery and power-profile chooser
with every action from Omarchy's System menu. It keeps the native look,
UPower integration, profile switching, system statistics, keyboard-openable
panel, and right-click percentage toggle.

## Actions

| Action | Behaviour |
|---|---|
| Screensaver | Starts the configured Omarchy screensaver |
| Lock | Locks the session through Omarchy |
| Suspend | Shown when suspend has not been disabled |
| Hibernate | Shown only when Omarchy reports hibernation is available |
| Logout | Requires confirmation, then closes applications cleanly |
| Reboot | Requires confirmation, then uses Omarchy's graceful reboot flow |
| Shutdown | Requires confirmation, then uses Omarchy's graceful shutdown flow |

The widget also remains useful on a desktop without a battery: it shows a
power glyph and opens the System controls. On a laptop it retains the normal
battery icon and all battery information.

## Install

```bash
omarchy plugin add https://github.com/thenailedone/omarchy-power-center.git --enable
```

The manifest declares `clonedFrom: omarchy.power`, allowing Omarchy to replace
the built-in widget cleanly and preserve the stock `omarchy.power` IPC route.

To remove it and return to the built-in widget:

```bash
omarchy plugin remove io.github.thenailedone.power-center
omarchy plugin enable omarchy.power
```

## Usage

- Left click opens or closes Power Center.
- Right click toggles the percentage on battery-powered systems.
- Click a profile to change it.
- Click a System action to run it; Logout, Reboot, and Shutdown ask first.
- Escape closes the panel or cancels a confirmation.

Power Center intentionally calls Omarchy's own action commands instead of
duplicating their shutdown and window-closing logic.

## Requirements

- Omarchy Quattro / Omarchy Shell with plugin schema version 1
- Quickshell and the commands shipped by Omarchy
- UPower for battery information
- `power-profiles-daemon` or another provider supported by Omarchy for profiles

## Verify

```bash
npm test
omarchy plugin validate .
git diff --check
```

The test suite has no third-party dependencies.

## Updating

```bash
omarchy plugin update io.github.thenailedone.power-center
```

See [UPSTREAM.md](UPSTREAM.md) for the fork baseline and update policy.

## Acknowledgements

This is an unofficial derivative of the `omarchy.power` plugin from
[Omarchy](https://github.com/basecamp/omarchy), created by David Heinemeier
Hansson and Omarchy contributors. The upstream copyright and MIT permission
notice are retained in [LICENSE](LICENSE). Exact provenance is recorded in
[UPSTREAM.md](UPSTREAM.md), with contributor acknowledgements in
[CREDITS.md](CREDITS.md).

## Licence

MIT. See [LICENSE](LICENSE).
