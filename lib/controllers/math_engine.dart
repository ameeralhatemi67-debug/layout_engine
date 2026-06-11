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

  /// Task 2: Neighbor-Shift Redistribution (Equalizer OFF)
  /// Adjusts a target split and steals/gives space ONLY to immediate cascading neighbors.
  static List<int> neighborEdit({
    required int targetIndex,
    required int targetValue,
    required List<int> currentSplits,
    required Set<int> lockedIndices,
  }) {
    int n = currentSplits.length;
    if (n <= 1) return currentSplits;

    List<int> newSplits = List.from(currentSplits);
    int difference = targetValue - currentSplits[targetIndex];
    if (difference == 0) return newSplits;

    // 1. Build the cascade order: Right neighbors first, then Left neighbors.
    List<int> cascadeOrder = [];
    for (int i = targetIndex + 1; i < n; i++) cascadeOrder.add(i);
    for (int i = targetIndex - 1; i >= 0; i--) cascadeOrder.add(i);

    int remainingToDistribute = -difference;

    // 2. Cascade the difference through the available neighbors
    for (int idx in cascadeOrder) {
      if (remainingToDistribute == 0) break;
      if (lockedIndices.contains(idx)) continue;

      int currentVal = newSplits[idx];

      if (remainingToDistribute < 0) {
        // Target is growing, so this neighbor must shrink.
        int maxSubtraction = currentVal - minSpace;
        if (maxSubtraction > 0) {
          int needToSubtract = -remainingToDistribute;
          int amountToSubtract = needToSubtract > maxSubtraction
              ? maxSubtraction
              : needToSubtract;
          newSplits[idx] -= amountToSubtract;
          remainingToDistribute += amountToSubtract;
        }
      } else {
        // Target is shrinking, so this neighbor grows.
        newSplits[idx] += remainingToDistribute;
        remainingToDistribute = 0;
      }
    }

    // 3. Fallback Clamp
    // If we hit limits (like minSpace on all unlocked neighbors),
    // we must clamp the target's growth to whatever space we were actually able to steal.
    if (remainingToDistribute != 0) {
      int actualDifference = difference - (-remainingToDistribute);
      newSplits[targetIndex] = currentSplits[targetIndex] + actualDifference;
    } else {
      newSplits[targetIndex] = targetValue;
    }

    return newSplits;
  }
}
