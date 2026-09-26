import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/premium/time_slot_picker.dart';

void main() {
  group('TimeSlotPicker', () {
    const morning = TimeOfDay(hour: 9, minute: 0);
    const midday = TimeOfDay(hour: 12, minute: 0);

    testWidgets('tapping available slot calls onSelect', (tester) async {
      TimeOfDay? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSlotPicker(
              slots: const [morning, midday],
              unavailable: const {},
              onSelect: (t) => picked = t,
            ),
          ),
        ),
      );
      await tester.tap(find.text('12:00'));
      expect(picked, midday);
    });

    testWidgets('unavailable slot does not call onSelect', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSlotPicker(
              slots: const [morning],
              unavailable: {morning},
              onSelect: (_) => calls++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('9:00'), warnIfMissed: false);
      expect(calls, 0);
    });
  });
}
