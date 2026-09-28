import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restorahub/pages/booking_page.dart';
import 'package:restorahub/pages/customer_shell.dart';
import 'package:restorahub/pages/profile_page.dart';
import 'package:restorahub/pages/user_home_page.dart';
import 'package:restorahub/pages/visits_page.dart';

// Seam (see task-4 report): the shell defaults to the real production pages,
// but pumping those requires seeding Auth/Appointment/Service/Business/
// StaffDirectory providers AND unmounting UserHomePage throws from its
// dispose (Provider.of on a deactivated context — frozen pre-existing code).
// Widget tests therefore inject lightweight stub tab bodies; production
// still gets the real pages via the default (covered by the unit test below).

const _stubPages = <Widget>[
  _StubBody('home-body'),
  _StubBody('book-body'),
  _StubBody('visits-body'),
  _StubBody('profile-body'),
];

class _StubBody extends StatelessWidget {
  const _StubBody(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

Future<void> _pumpShell(
  WidgetTester tester, {
  int initialIndex = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CustomerShell(
        initialIndex: initialIndex,
        pages: _stubPages,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int _selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('CustomerShell', () {
    test('defaults to the four production pages', () {
      const shell = CustomerShell();
      expect(shell.pages.length, 4);
      expect(shell.pages[0], isA<UserHomePage>());
      expect(
        (shell.pages[0] as UserHomePage).showChrome,
        isFalse,
        reason: 'shell embeds UserHomePage chromeless to avoid nested chrome',
      );
      expect(shell.pages[1], isA<BookingPage>());
      expect(shell.pages[2], isA<VisitsPage>());
      expect(shell.pages[3], isA<ProfilePage>());
    });

    testWidgets('shows all four destinations', (tester) async {
      await _pumpShell(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(_selectedIndex(tester), 0);
    });

    testWidgets('tapping Book shows the Book tab', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Book'));
      await tester.pumpAndSettle();

      expect(_selectedIndex(tester), 1);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        1,
      );
    });

    testWidgets('back-press from Book returns to Home', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Book'));
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), 1);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(_selectedIndex(tester), 0);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );
    });

    testWidgets('clamps out-of-range initialIndex to Home', (tester) async {
      await _pumpShell(tester, initialIndex: 99);

      expect(_selectedIndex(tester), 0);
    });
  });
}
