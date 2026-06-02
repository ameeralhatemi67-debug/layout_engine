class MathEngine {
  /// The absolute maximum space for any given layer.
  static const int totalSpace = 1000;

  /// Minimum size constraint (2.5%) to prevent "Zero-Space" errors.
  static const int minSpace = 25;

  /// Task 2: Equal Distribution (splitEdit)
  /// Divides the 1000 units equally and assigns the remainder to the middle element.
  static List<int> splitEdit(int numberOfSplits) {
    if (numberOfSplits <= 0) return [];
    if (numberOfSplits == 1) return [totalSpace];

    int baseValue = totalSpace ~/ numberOfSplits; // Floor division
    int remainder = totalSpace - (baseValue * numberOfSplits);
    int middleIndex = numberOfSplits ~/ 2;

    List<int> splits = List.filled(numberOfSplits, baseValue);

    // Distribute the remainder to the middle element
    splits[middleIndex] += remainder;

    return splits;
  }

  /// Task 3: Proportional Redistribution (Manualedit)
  /// Adjusts a target split and proportionally scales the remaining unlocked splits.
  static List<int> manualEdit({
    required int targetIndex,
    required int targetValue,
    required List<int> currentSplits,
    required Set<int> lockedIndices,
  }) {
    int n = currentSplits.length;
    if (n <= 1) return currentSplits;

    // 1. Calculate Locked Space
    int lockedSpace = 0;
    for (int i in lockedIndices) {
      if (i != targetIndex) lockedSpace += currentSplits[i];
    }

    // Identify unlocked siblings (excluding the target)
    List<int> unlockedSiblings = [];
    for (int i = 0; i < n; i++) {
      if (!lockedIndices.contains(i) && i != targetIndex) {
        unlockedSiblings.add(i);
      }
    }

    // 2. Boundary Constraint (Preventing Zero-Space)
    int maxAllowed =
        totalSpace - lockedSpace - (unlockedSiblings.length * minSpace);
    int clampedTarget = targetValue > maxAllowed ? maxAllowed : targetValue;
    if (clampedTarget < minSpace)
      clampedTarget = minSpace; // Target itself cannot be crushed

    // 3. Current Unlocked Space (C_total)
    int cTotal = 0;
    for (int i in unlockedSiblings) {
      cTotal += currentSplits[i];
    }

    // 4. New Available Space
    int aNew = totalSpace - clampedTarget - lockedSpace;
    List<int> newSplits = List.from(currentSplits);
    newSplits[targetIndex] = clampedTarget;

    if (unlockedSiblings.isEmpty) return newSplits;

    // 5. Apply Proportional Ratio
    int assignedSpace = 0;
    for (int i in unlockedSiblings) {
      // If previous C_total was 0 (edge case), distribute evenly, otherwise strictly proportional
      int newValue = cTotal == 0
          ? (aNew ~/ unlockedSiblings.length)
          : (currentSplits[i] * aNew) ~/ cTotal;

      newSplits[i] = newValue;
      assignedSpace += newValue;
    }

    // 6. Handle the Redistribution Remainder
    int rManual = aNew - assignedSpace;
    if (rManual != 0 && unlockedSiblings.isNotEmpty) {
      int middleUnlockedIndex = unlockedSiblings[unlockedSiblings.length ~/ 2];
      newSplits[middleUnlockedIndex] += rManual;
    }

    return newSplits;
  }
}
