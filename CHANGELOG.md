# Changelog

## [2.0.0] - 2026-11-07

### Changed

- Rebuilt the panel for current KeyboardPanel and ShellIpc contracts.
- Replaced rotating charge phrases and battery subprocess polling with a stable,
  reactive UPower energy dashboard and lazy popup content.
- Added bounded parallel probes, explicit failures, and serialized setting changes.
- Added keyboard access to every control, stable selection during data refresh,
  scrolling, plain-text rendering, translation catalogs, and reduced-motion support.

### Added

- Kernel power readings, battery health, cycles, and available charge-limit data.
- Stay awake / allow idle control and immediate D-Bus power-profile feedback.
- JavaScript and Python regression coverage, including hardware reading failures.

### Preserved

- Separate AC/battery power-profile choices through Omarchy's canonical commands.
- All System actions, desktop fallback, right-click percentage toggle, and
  cancel-first confirmation for log out, restart, and shutdown.

## [1.0.0] - 2026-08-22

### Added

- Screensaver, lock, suspend, hibernate, logout, reboot, and shutdown controls.
- Runtime visibility checks matching Omarchy's System menu for suspend and hibernate.
- Confirmation UI for logout, reboot, and shutdown.
- Desktop support when no battery is present.
- Dependency-free tests for the System action model.
- Project documentation, security policy, contribution guide, and upstream provenance.

### Preserved

- Battery and charge-state reporting from UPower.
- Power-profile selection and active-state display.
- System statistics, rotating charge/discharge status, and percentage toggle.

[2.0.0]: https://github.com/sthuizen/omarchy-power-center/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/sthuizen/omarchy-power-center/releases/tag/v1.0.0
