# Upstream and provenance

Power Center is derived from Omarchy's first-party `omarchy.power` bar widget,
distributed under the MIT License.

## Baseline

- Project: <https://github.com/basecamp/omarchy>
- Source path: `shell/plugins/panels/power/`
- Installed Omarchy package: `4.0.0-1`
- Baseline date: 2026-08-22
- `Panel.qml` SHA-256: `bbd4da9ef5cf07bb8023806c56ed2f51c64d881319c31117c176e9f9bbc3fa5f`
- `Model.js` SHA-256: `5ed21781bcd315742b8eda1aa72f415f72217a38e03c659fe40095ed939f7ed2`
- `manifest.json` SHA-256: `7e1a3d83a1ffd85f4a9ee2df9ccfd2cb63de794f100c5e2ec11156be7df83bb5`

The original copyright and permission notice are retained in `LICENSE`.

## Local changes

- Renamed the plugin and moved it into the author's GitHub namespace.
- Added the complete action set from Omarchy's default System menu.
- Reused Omarchy's canonical commands for screensaver, lock, logout, reboot,
  and shutdown.
- Matched the System menu's conditional availability for suspend and hibernate.
- Added confirmation before session-ending or power-ending actions.
- Kept the widget available on systems without a battery.
- Added tests and repository documentation.

## Update policy

Upstream changes are not merged automatically. To update the fork:

1. Compare the current Omarchy `shell/plugins/panels/power/` directory with
   the baseline recorded above.
2. Review and port upstream changes without removing Power Center's System
   controls or confirmation flow.
3. Update the version and changelog.
4. Run `npm test`, `omarchy plugin validate .`, and `git diff --check`.
5. Record the new upstream version and hashes in this file.

This project is independent and unofficial. It is not endorsed by or
affiliated with Basecamp, 37signals, David Heinemeier Hansson, or Omarchy.
