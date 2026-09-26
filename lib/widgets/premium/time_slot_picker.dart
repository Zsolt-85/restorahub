import 'package:flutter/material.dart';

String formatSlot(TimeOfDay t) =>
    '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.unavailable,
    this.selected,
    required this.onSelect,
  });

  final List<TimeOfDay> slots;
  final Set<TimeOfDay> unavailable;
  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 44,
      ),
      itemCount: slots.length,
      itemBuilder: (context, i) {
        final slot = slots[i];
        final isOff = unavailable.contains(slot);
        final isSel = selected == slot;
        final bg = isSel
            ? scheme.primary
            : isOff
                ? Colors.transparent
                : scheme.surface;
        final fg = isSel
            ? scheme.onPrimary
            : isOff
                ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
                : scheme.onSurface;
        return Semantics(
          button: true,
          enabled: !isOff,
          label: formatSlot(slot),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isOff ? null : () => onSelect(slot),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isOff || isSel
                    ? null
                    : [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                formatSlot(slot),
                style: text.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  decoration:
                      isOff ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
