# Security policy

## Supported versions

Only the latest released version receives security fixes.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do
not open a public issue containing an unpatched vulnerability, exploit, secret,
or personally identifying log data.

Include the affected version, Omarchy version, impact, reproduction steps, and
any proposed mitigation. You should receive an acknowledgement within seven
days. Coordinated disclosure is appreciated.

## Security model

This plugin can invoke session and power-management commands at the current
user's request. It never asks for credentials, adds privilege rules, downloads
code at runtime, or executes commands assembled from user-provided strings.
Logout, reboot, and shutdown require an explicit second confirmation.
