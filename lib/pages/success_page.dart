import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../helpers/calendar_helper.dart';
import '../models/booking_summary.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../repositories/staff_directory_repository.dart';
import '../widgets/premium/booking_summary_card.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, this.summary});

  final BookingSummary? summary;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _revealed = true);
    });
  }

  BookingSummary? get summary => widget.summary;

  Future<void> _addToCalendar(BuildContext context) async {
    if (summary == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final professional = summary!.professionalId != null
        ? await Provider.of<StaffDirectoryRepository>(context, listen: false)
            .getEntryById(summary!.professionalId!)
        : null;

    if (professional == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.error ??
                'Unable to add to calendar: professional not found')),
      );
      return;
    }

    final appointment = summary!.toAppointment(
      customerId: authProvider.currentUser?.id,
    );

    try {
      await CalendarHelper.addToNativeCalendar(appointment, professional);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.bookingSuccessful ??
                'Added to calendar')),
      );
    } on CalendarException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.failedToUpdate ?? 'Failed to add to calendar'}: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToUpdate ??
                'Failed to add to calendar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)?.bookingConfirmed ??
                            'Booking confirmed',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'See you soon',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              if (summary != null) BookingSummaryCard(summary: summary!),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _revealed ? 1 : 0,
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (summary != null)
                      ElevatedButton.icon(
                        onPressed: () => _addToCalendar(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(AppLocalizations.of(context)?.calendar ??
                            'Add to Calendar'),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.services,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)?.bookAnother ??
                          'Book another'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.customerHome,
                          (route) => false,
                        );
                      },
                      child: Text(AppLocalizations.of(context)?.dashboard ??
                          'Back to dashboard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
