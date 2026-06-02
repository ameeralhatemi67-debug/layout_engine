import 'package:flutter_test/flutter_test.dart';
import 'package:layout_engine/controllers/math_engine.dart';
// Adjust path if your project name differs

void main() {
  group('MathEngine - splitEdit', () {
    test('Splitting by 3 handles the remainder correctly', () {
      final splits = MathEngine.splitEdit(3);

      // Expected: 1000 / 3 = 333. Remainder 1 goes to middle.
      expect(splits, [333, 334, 333]);

      // Prove total is exactly 1000
      final total = splits.reduce((a, b) => a + b);
      expect(total, 1000);
    });

    test('Splitting by 7 handles the remainder correctly', () {
      final splits = MathEngine.splitEdit(7);

      final total = splits.reduce((a, b) => a + b);
      expect(total, 1000);
    });
  });

  group('MathEngine - manualEdit', () {
    test('Proportional scaling maintains 1000 total', () {
      // Start with 333, 334, 333
      List<int> initial = MathEngine.splitEdit(3);

      // User drags the first split to 500 (50%)
      final newSplits = MathEngine.manualEdit(
        targetIndex: 0,
        targetValue: 500,
        currentSplits: initial,
        lockedIndices: {},
      );

      // Prove total is exactly 1000
      final total = newSplits.reduce((a, b) => a + b);
      expect(total, 1000);

      // The remaining 500 should be split proportionally between the other two
      expect(newSplits[0], 500);
    });

    test('Boundary wall prevents zero-space crushing', () {
      List<int> initial = MathEngine.splitEdit(3);

      // User attempts to drag the first split to 990 (crushing the others below minSpace)
      final newSplits = MathEngine.manualEdit(
        targetIndex: 0,
        targetValue: 990,
        currentSplits: initial,
        lockedIndices: {},
      );

      // The engine should clamp the value to protect the 25 unit minimums of the other 2 splits
      // 1000 - (25 * 2) = 950 max allowed for the target.
      expect(newSplits[0], 950);

      final total = newSplits.reduce((a, b) => a + b);
      expect(total, 1000);
    });
  });
}
