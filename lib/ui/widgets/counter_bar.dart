import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models.dart';

class CounterBar extends StatelessWidget {
  final Taxon? selectedTaxon;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onCountTap;
  final int totalCount;
  final VoidCallback onSearchTap;

  const CounterBar({
    Key? key,
    this.selectedTaxon,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    this.onCountTap,
    required this.totalCount,
    required this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        12,
      ), // Reduced from 16 to 12 (25% reduction)
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6, // Reduced from 8 to 6
            offset: const Offset(0, -1), // Reduced from -2 to -1
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected taxon info
          if (selectedTaxon != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  selectedTaxon!.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    // Reduced from titleMedium to titleSmall
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                if (selectedTaxon!.rank != null) ...[
                  const SizedBox(width: 6), // Reduced from 8 to 6
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ), // Reduced from 6,2 to 4,1
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        3,
                      ), // Reduced from 4 to 3
                    ),
                    child: Text(
                      selectedTaxon!.rank!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6), // Reduced from 8 to 6
          ],

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: IconButton(
                      onPressed: onSearchTap,
                      icon: Icon(
                        Icons.search,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button on the left
                      IconButton(
                        onPressed: onDecrement,
                        icon: Icon(
                          Icons.remove_circle,
                          color: colorScheme.error,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Count box in the center
                      Expanded(
                        child: GestureDetector(
                          onTap: onCountTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Plus button on the right
                      IconButton(
                        onPressed: () {
                          // Add haptic feedback - vibrate provides more noticeable feedback
                          HapticFeedback.vibrate();
                          onIncrement();
                        },
                        icon: Icon(
                          Icons.add_circle,
                          color: colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Count',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$totalCount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
