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

  /// Task 3: Proportional Redistribution (ManualEdit)
  /// Adjusts a target split and proportionally scales the remaining unlocked splits without integer bias.
  static List<int> manualEdit({
    required int targetIndex,
    required int targetValue,
    required List<int> currentSplits,
    required Set<int> lockedIndices,
  }) {
    int n = currentSplits.length;
    if (n <= 1) return currentSplits;

    // 1. Identify Unlocked Siblings
    List<int> unlockedSiblings = [];
    int lockedSpace = 0;

    for (int i = 0; i < n; i++) {
      if (i == targetIndex) continue;

      if (lockedIndices.contains(i)) {
        lockedSpace += currentSplits[i];
      } else {
        unlockedSiblings.add(i);
      }
    }

    // 2. Boundary Constraint (Preventing Zero-Space)
    int maxAllowed =
        totalSpace - lockedSpace - (unlockedSiblings.length * minSpace);
    int clampedTarget = targetValue > maxAllowed ? maxAllowed : targetValue;
    if (clampedTarget < minSpace)
      clampedTarget = minSpace; // Target cannot be crushed

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

    // 5. Apply Proportional Ratio (Largest Remainder Method)
    int assignedSpace = 0;
    Map<int, double> exactFractions =
        {}; // Tracks who lost the most in rounding

    for (int i in unlockedSiblings) {
      if (cTotal == 0) {
        int val = aNew ~/ unlockedSiblings.length;
        newSplits[i] = val;
        assignedSpace += val;
      } else {
        // Calculate the exact decimal
        double exact = (currentSplits[i] * aNew) / cTotal;
        newSplits[i] = exact.floor(); // Round down safely
        assignedSpace += newSplits[i];

        // Save the decimal fraction that got chopped off
        exactFractions[i] = exact - exact.floor();
      }
    }

    // 6. Handle the Remainder Fairly
    int remainder = aNew - assignedSpace;
    if (remainder > 0 && cTotal > 0) {
      // Sort the siblings so the one with the biggest chopped-off decimal is first
      unlockedSiblings.sort(
        (a, b) => exactFractions[b]!.compareTo(exactFractions[a]!),
      );

      // Hand out the remainder 1 unit at a time to whoever deserves it most
      for (int i = 0; i < remainder; i++) {
        newSplits[unlockedSiblings[i % unlockedSiblings.length]] += 1;
      }
    } else if (remainder > 0 && cTotal == 0) {
      // Fallback if the space was entirely 0 previously
      for (int i = 0; i < remainder; i++) {
        newSplits[unlockedSiblings[i % unlockedSiblings.length]] += 1;
      }
    }

    return newSplits;
  }
}
