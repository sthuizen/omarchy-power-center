import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('backend', Path(__file__).parents[1] / 'backend.py')
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)

class ProbeTests(unittest.TestCase):
    def test_missing_and_nonfinite_readings(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'reading'
            self.assertIsNone(backend.number(p))
            for v in ('nan', 'inf', '-2', 'bad'):
                p.write_text(v)
                self.assertIsNone(backend.number(p))
            p.write_text('0')
            self.assertEqual(backend.number(p), 0)

    def test_battery_health_current_fallback_and_peripheral_exclusion(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            bat = root / 'battery_macsmc_battery'
            bat.mkdir()
            fields = {'type': 'Battery', 'charge_full': '800', 'charge_full_design': '1000', 'current_now': '-2000000', 'voltage_now': '12000000', 'cycle_count': '0', 'charge_control_end_threshold': '80'}
            for name, value in fields.items(): (bat / name).write_text(value)
            mouse = root / 'mouse'
            mouse.mkdir()
            (mouse / 'type').write_text('Battery')
            (mouse / 'scope').write_text('Device')
            result = backend.batteries(root)
            self.assertEqual(len(result), 1)
            self.assertEqual(result[0]['health'], 80)
            self.assertEqual(result[0]['watts'], 24)
            self.assertEqual(result[0]['cycles'], 0)
            self.assertEqual(result[0]['limit'], 80)
            (bat / 'power_now').write_text('-13500000')
            self.assertEqual(backend.batteries(root)[0]['watts'], 13.5)

    def test_probes_timeout_and_missing_commands_are_safe(self):
        for error in (FileNotFoundError(), subprocess.TimeoutExpired('command', 3)):
            with patch.object(backend.subprocess, 'run', side_effect=error):
                self.assertEqual(backend.run(['fixed-command']), (-1, ''))

if __name__ == '__main__': unittest.main()
