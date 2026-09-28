import 'package:flutter/material.dart';

import 'booking_page.dart';
import 'profile_page.dart';
import 'user_home_page.dart';
import 'visits_page.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    this.initialIndex = 0,
    this.pages = _defaultPages,
  });

  static const _defaultPages = <Widget>[
    UserHomePage(showChrome: false),
    BookingPage(),
    VisitsPage(),
    ProfilePage(),
  ];

  final int initialIndex;

  /// Tab bodies. Defaults to the production pages ([_defaultPages]); tests
  /// may inject lightweight stubs so they do not need to seed every provider
  /// the real pages require (see task-4 report: full seeding is infeasible
  /// because UserHomePage.dispose reads AppointmentProvider via context).
  final List<Widget> pages;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _index = (widget.initialIndex >= 0 &&
          widget.initialIndex < widget.pages.length)
      ? widget.initialIndex
      : 0;

  void _onTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 150),
          // Single-child layout keeps exactly one IndexedStack in the tree
          // mid-transition so existing finders stay green; incoming tab
          // still fades in via the default FadeTransition.
          layoutBuilder: (currentChild, _) => currentChild!,
          child: IndexedStack(
            key: ValueKey<int>(_index),
            index: _index,
            children: widget.pages,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTap,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Book'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Visits'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
