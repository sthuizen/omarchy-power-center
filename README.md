# Power Center 2 for Omarchy

A native, theme-aware energy dashboard and session controller based on
[sthuizen/omarchy-power-center](https://github.com/sthuizen/omarchy-power-center).

## Features

- Live UPower battery percentage, charge state, capacity, and time estimates.
- Kernel power readings, battery health, cycles, and charge limit where available.
- Power profiles with immediate D-Bus selection updates. Changes use Omarchy's
  own commands and remember separate AC and battery preferences.
- Stay awake / allow idle, with a clear explanation of automatic lock behaviour.
- Screensaver, lock, suspend, hibernate, log out, restart, and shutdown.
- Log out, restart, and shutdown require confirmation; Cancel is selected first.
- Suspend respects logind capability, Omarchy's suspend toggle, and disabled-sleep policy.
  Hibernate respects Omarchy's hibernation check and disabled-sleep policy.
- Works on desktops without batteries; unknown hardware readings show a dash.
- Lazy popup content, no polling while closed, and one concurrent probe at most.
- Keyboard navigation across every control, scrolling for small displays,
  plain-text rendering, reduced-motion support, and plugin-owned translations.

## Usage

Left click the battery/power icon. Right click toggles percentage in the bar.
Use Tab / Shift+Tab or arrows to select, Enter / Space to activate, R to refresh,
and Escape to cancel a confirmation or close the panel.

The battery and active profile update through D-Bus. Hardware details and capabilities
refresh on opening and every 15 seconds while open. Each external probe has a
3-second deadline; profile and idle changes have an 8-second deadline. No network
requests, daemon, Python packages, or npm dependencies are needed.

English is supplied; other shell languages fall back to that catalog. Add translations
under `i18n/<language>.json`. The current desktop theme supplies colors, type, spacing,
borders, and animation preferences.

## Install and update

```bash
omarchy plugin add https://github.com/sthuizen/omarchy-power-center.git --enable
```

To update an existing git-managed installation:

```bash
omarchy plugin update io.github.thenailedone.power-center
```

The plugin keeps its original ID for compatibility and replaces the built-in
power widget. Its files live at:

```text
~/.config/omarchy/plugins/io.github.thenailedone.power-center/
```

The manifest replaces `omarchy.power` and preserves its IPC entry point:

```bash
omarchy-shell omarchy.power toggle
```

To return to the built-in widget:

```bash
omarchy plugin disable io.github.thenailedone.power-center
omarchy plugin enable omarchy.power
```

### Upgrading from 1.x

Version 2 replaces the rotating charge phrases with a stable energy dashboard,
adds Stay awake and battery health information, and uses the current lazy panel
and ShellIpc APIs. Existing widget placement and percentage preference are retained.
The plugin does not change your chosen power profile or idle timings on install.
Back up `~/.config/omarchy/shell.json` before making manual configuration changes.

## Requirements and limitations

Current Omarchy shell with schema version 1, Quickshell UPower/PowerProfiles,
Python 3, and coreutils. Power profiles require a compatible running provider.
Battery health, cycle count, charge limit, and instantaneous draw depend on hardware.
For multiple batteries, the hero uses UPower's aggregate device; individual battery
health and cycles show a dash instead of attributing one pack's values to the group.
Charge limits are displayed, not modified; no privileged hardware writes are made.

## Verification

```bash
npm test
omarchy plugin validate .
git diff --check
```

Tests cover action routing and confirmation policy, profile allowlisting,
markup-shaped input, invalid numbers, sysfs battery detection, peripheral
exclusion, signed current readings, and unavailable/timed-out commands. GitHub Actions runs the JavaScript and Python
suites plus manifest checks. Live checks verified panel rendering, keyboard
selection, cancel-first confirmation, and loading in Omarchy. Session-ending and
sleep actions were not executed as part of verification.

## Acknowledgements

This is an unofficial derivative of the `omarchy.power` plugin from
[Omarchy](https://github.com/basecamp/omarchy), created by David Heinemeier
Hansson and Omarchy contributors. The upstream copyright and MIT permission
notice are retained in [LICENSE](LICENSE). Exact provenance is recorded in
[UPSTREAM.md](UPSTREAM.md), with contributor acknowledgements in
[CREDITS.md](CREDITS.md).

## Licence

MIT. See [LICENSE](LICENSE).
