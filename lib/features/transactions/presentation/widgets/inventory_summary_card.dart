import 'package:flutter/material.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';

class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard.full({
    required this.item,
    required this.onTap,
    this.contextLabel,
    this.contextDate,
    this.statusLabel,
    super.key,
  }) : compact = false,
       valueLabel = null;

  const InventorySummaryCard.compact({
    required this.item,
    required this.onTap,
    this.valueLabel,
    super.key,
  }) : compact = true,
       contextLabel = null,
       contextDate = null,
       statusLabel = null;

  final InventoryItem item;
  final VoidCallback? onTap;
  final bool compact;
  final String? contextLabel;
  final String? contextDate;
  final String? statusLabel;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final specLine = compactInventorySpecification(item);
    final inventoryNumber =
        item.inventoryNumber ?? 'Inventory number not assigned';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              if (contextLabel != null || contextDate != null) ...[
                Row(
                  children: [
                    if (contextLabel != null)
                      _Pill(
                        text: contextLabel!,
                        foreground: const Color(0xFF147A3D),
                        background: const Color(0xFFE3F4E8),
                      ),
                    const Spacer(),
                    if (contextDate != null)
                      Text(
                        contextDate!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5F6D7E),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItemPhoto(
                    photoUrl: item.photoUrls.isEmpty
                        ? null
                        : item.photoUrls.first,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inventoryNumber,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF1174C2),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          inventoryEquipmentName(item),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF082A4A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (specLine.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            specLine,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF526174)),
                          ),
                        ],
                        if (item.condition != null) ...[
                          const SizedBox(height: 8),
                          _Pill(
                            text: item.condition!.label,
                            foreground: const Color(0xFF26384B),
                            background: const Color(0xFFF1F3F6),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(width: 8),
                    _Pill(
                      text: statusLabel!,
                      foreground: const Color(0xFF526174),
                      background: const Color(0xFFF1F3F6),
                    ),
                  ] else if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final specLine = compactInventorySpecification(item);
    final inventoryNumber =
        item.inventoryNumber ?? 'Inventory number not assigned';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ItemPhoto(
              photoUrl: item.photoUrls.isEmpty ? null : item.photoUrls.first,
              size: 58,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inventoryNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF1174C2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inventoryEquipmentName(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF082A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (specLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      specLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5F6D7E),
                      ),
                    ),
                  ],
                  if (valueLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      valueLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4F5E70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ItemPhoto extends StatelessWidget {
  const _ItemPhoto({required this.photoUrl, this.size = 82});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() => const ColoredBox(
    color: Color(0xFFF1F3F6),
    child: Center(
      child: Icon(Icons.inventory_2_outlined, color: Color(0xFF8793A2)),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String inventoryEquipmentName(InventoryItem item) {
  final model = item.model?.trim() ?? '';
  return model.isEmpty ? item.brand : '${item.brand} $model';
}

String compactInventorySpecification(InventoryItem item) {
  switch (item.category) {
    case InventoryCategory.bat:
      final parts = <String>[];
      if (item.lengthInches != null) {
        parts.add('${_compactNumber(item.lengthInches!)}"');
      }
      if (item.weightOunces != null) {
        parts.add('${_compactNumber(item.weightOunces!)} oz');
      }
      if (item.certification != null && item.certification!.trim().isNotEmpty) {
        parts.add(item.certification!.trim());
      }
      return parts.join('  •  ');
    case InventoryCategory.glove:
      final parts = <String>[];
      if (item.gloveSizeInches != null) {
        parts.add('${_compactNumber(item.gloveSizeInches!)}"');
      }
      if (item.handOrientation != null &&
          item.handOrientation!.trim().isNotEmpty) {
        parts.add(item.handOrientation!.trim());
      }
      return parts.join('  •  ');
    case InventoryCategory.catchersGear:
      return item.catchersGearSize?.trim() ?? '';
    case InventoryCategory.helmet:
      return item.helmetSize?.trim() ?? '';
    case InventoryCategory.other:
      return '';
  }
}

String _compactNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
