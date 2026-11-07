#!/usr/bin/env python3
"""Bounded, read-only hardware/capability probe. Never executes supplied commands."""
import concurrent.futures
import json
import math
from pathlib import Path
import subprocess
import sys


def run(argv):
    try:
        result = subprocess.run(argv, capture_output=True, text=True, timeout=3)
        return result.returncode, result.stdout[:16384]
    except (OSError, subprocess.TimeoutExpired):
        return -1, ''


def number(path, signed=False):
    try:
        value = float(path.read_text()[:64].strip())
        return value if math.isfinite(value) and (signed or value >= 0) else None
    except (OSError, ValueError):
        return None


def batteries(root=Path('/sys/class/power_supply')):
    result = []
    for battery in sorted(root.glob('*'))[:32]:
        try:
            if (battery / 'type').read_text().strip() != 'Battery':
                continue
            if (battery / 'scope').exists() and (battery / 'scope').read_text().strip() == 'Device':
                continue
            if number(battery / 'present') == 0:
                continue
        except OSError:
            continue
        full = number(battery / 'energy_full')
        design = number(battery / 'energy_full_design')
        if full is None or design is None:
            full, design = number(battery / 'charge_full'), number(battery / 'charge_full_design')
        rate = number(battery / 'power_now', signed=True)
        if rate is not None:
            rate = abs(rate)
        # Some kernels report signed discharge current.
        if rate is None:
            try:
                current = abs(float((battery / 'current_now').read_text()[:64]))
                voltage = number(battery / 'voltage_now')
                rate = current * voltage / 1e6 if voltage is not None and math.isfinite(current) else None
            except (OSError, ValueError):
                pass
        result.append({'name': battery.name[:80], 'cycles': number(battery / 'cycle_count'),
                       'health': min(100, full / design * 100) if full is not None and design and full > 0 else None,
                       'limit': number(battery / 'charge_control_end_threshold'),
                       'watts': rate / 1e6 if rate is not None else None})
    return result


def snapshot():
    commands = {
        'profiles': ['omarchy', 'powerprofiles', 'list', '--active-state'],
        'suspend': ['busctl', '--timeout=2s', 'call', 'org.freedesktop.login1', '/org/freedesktop/login1', 'org.freedesktop.login1.Manager', 'CanSuspend'],
        'hibernate': ['omarchy', 'hibernation', 'available'],
        'idle': ['omarchy', 'toggle', 'idle', 'status'],
        'suspend_off': ['omarchy-toggle-enabled', 'suspend-off'],
        'sleep_disabled': ['omarchy-sleep-disabled'],
    }
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        tasks = {key: pool.submit(run, argv) for key, argv in commands.items()}
        values = {key: task.result() for key, task in tasks.items()}
    try:
        awake = json.loads(values['idle'][1]).get('enabled') is True
    except (ValueError, AttributeError):
        awake = None
    return {'profiles': values['profiles'][1], 'profilesOk': values['profiles'][0] == 0 and bool(values['profiles'][1].strip()),
            'suspend': values['suspend'][0] == 0 and values['suspend'][1].strip() in ('s "yes"', 's "challenge"') and values['suspend_off'][0] == 1 and values['sleep_disabled'][0] == 1,
            'hibernate': values['hibernate'][0] == 0 and values['sleep_disabled'][0] == 1,
            'awake': awake, 'batteries': batteries()}


if __name__ == '__main__':
    if len(sys.argv) != 1:
        sys.exit(2)
    print(json.dumps(snapshot(), allow_nan=False, separators=(',', ':')))
