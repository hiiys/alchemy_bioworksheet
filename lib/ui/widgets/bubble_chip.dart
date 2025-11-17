import 'package:flutter/material.dart';
import '../../data/models.dart';

class BubbleChip extends StatelessWidget {
  final Taxon taxon;
  final VoidCallback onTap;
  final int? count;
  final bool isSelected;

  const BubbleChip({
    Key? key,
    required this.taxon,
    required this.onTap,
    this.count,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rankColor = _colorForRank(taxon.rank, colorScheme);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final vPad = fontSize * 0.05;
    final hPad = fontSize * 0.05;

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.transparent
                  : (rankColor ?? colorScheme.surface).withOpacity(0.3),
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: isSelected
                    ? (rankColor ?? colorScheme.primary)
                    : colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Taxon name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    taxon.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (rankColor ?? colorScheme.primary)
                          : colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Count badge (if available)
                if (count != null && count! > 0) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: (rankColor ?? colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Rank indicator (if available)
                if (taxon.rank != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    taxon.rank!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _colorForRank(String? rank, ColorScheme scheme) {
    final r = (rank ?? '').toLowerCase();
    if (r == 'phylum') return Colors.deepPurple;
    if (r == 'class') return Colors.indigo;
    if (r == 'order') return Colors.blue;
    if (r == 'family') return Colors.teal;
    if (r == 'genus') return Colors.green;
    if (r == 'species') return Colors.orange;
    return null;
  }
}
