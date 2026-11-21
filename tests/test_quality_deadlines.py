"""Keep ordinary Godot deadlines aligned with the measured-duration policy."""
import re
import unittest
from decimal import ROUND_CEILING, Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class QualityDeadlineTests(unittest.TestCase):
    def test_measured_deadlines(self):
        measured = Decimal("457.701")
        deadline = 3 * int((measured * Decimal("1.25")).to_integral_value(ROUND_CEILING))
        self.assertEqual(deadline, 1719)
        runner = (ROOT / "scripts/checks.sh").read_text()
        ordinary = [
            r'^run_godot (\d+) --path "\$metrics" -s check_complexity.gd$',
            r'^  seconds=(\d+)$',
            r'^    run_godot (\d+) --fixed-fps 1000 -s "\$script"$',
        ]
        allocations = [re.findall(pattern, runner, re.MULTILINE) for pattern in ordinary]
        self.assertEqual(allocations, [[str(deadline)]] * 3)
        self.assertIn(
            'game/world/test_local_frame_routes.gd|game/world/test_local_frame_runtime.gd) seconds=1263 ;;',
            runner,
        )
        self.assertIn('run_godot 12 --quit -- --save-path="$scratch/boot.json"', runner)
        docs = (ROOT / "docs/quality-checks.md").read_text()
        self.assertIn(
            '| Ordinary validation/tests, including fixed-1000-FPS map | '
            '`ontology/test_required_inputs.gd` | 457.701s | 1719s |', docs,
        )
        self.assertIn('Cognitive analysis also uses the ordinary 1719-second deadline', docs)
        self.assertIn('| 336.189s | 1263s |', docs)
        self.assertIn('| 3.072s | 12s |', docs)


if __name__ == "__main__":
    unittest.main()
