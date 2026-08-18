import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/routes.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../repositories/booking_repository.dart';
import '../repositories/business_repository.dart';
import '../repositories/firestore_booking_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

class AdminCalendarPage extends StatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  State<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends State<AdminCalendarPage> {
  bool _busy = true;
  bool _staffBusy = true;
  String? _error;
  String? _staffError;
  List<User> _staff = [];
  List<Appointment> _appointments = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedProfessionalId;
  final BookingRepository _bookingRepo = FirestoreBookingRepository.instance;
  final UserRepository _userRepo = FirestoreUserRepository.instance;

  static const _professionalColors = [
    Color(0xFF008080),
    Color(0xFF6366F1),
    Color(0xFFBE123C),
    Color(0xFF1E3A8A),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _ensureBusinessLoaded();
  }

  Future<void> _ensureBusinessLoaded() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (businessProvider.currentBusiness != null) {
      _loadData();
      return;
    }

    final userBusinessId = user.businessId;
    if (userBusinessId == null || userBusinessId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _staffBusy = false;
      });
      return;
    }

    try {
      final repository = Provider.of<BusinessRepository>(context, listen: false);
      final business = await repository.getBusinessById(userBusinessId);
      if (business != null && mounted) {
        businessProvider.setBusiness(business);
      }
    } catch (e, stack) {
      AppLogger.error('AdminCalendarPage._ensureBusinessLoaded error: $e\n$stack');
    }

    if (!mounted) return;
    _loadData();
  }

  bool _isAdmin(String role) {
    return role == 'business_admin' || role == 'super_admin';
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return;
    if (!_isAdmin(user.role)) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _staffBusy = false;
      });
      return;
    }

    final businessId = businessProvider.currentBusiness?.id;
    if (businessId == null || businessId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _staff = [];
        _appointments = [];
        _busy = false;
        _staffBusy = false;
      });
      return;
    }

    await Future.wait([
      _loadStaff(businessId),
      _loadAppointments(businessId),
    ]);
  }

  Future<void> _loadStaff(String businessId) async {
    try {
      final staff = await _userRepo.getProfessionals(businessId: businessId);
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _staffBusy = false;
        _staffError = null;
      });
    } catch (e, stack) {
      AppLogger.error('AdminCalendarPage._loadStaff error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _staffError = e.toString();
        _staffBusy = false;
      });
    }
  }

  Future<void> _loadAppointments(String businessId) async {
    try {
      final day = _selectedDay ?? _focusedDay;
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999, 999);
      final appointments = await _bookingRepo.getAppointmentsForBusiness(
        businessId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _busy = false;
        _error = null;
      });
    } catch (e, stack) {
      AppLogger.error('AdminCalendarPage._loadAppointments error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _refresh() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id;
    if (businessId == null || businessId.isEmpty) return;
    setState(() {
      _busy = true;
      _staffBusy = true;
      _error = null;
      _staffError = null;
    });
    await _loadData();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id;
    if (businessId != null && businessId.isNotEmpty) {
      _loadAppointments(businessId);
    }
  }

  void _onProfessionalSelected(String? professionalId) {
    setState(() {
      _selectedProfessionalId = professionalId;
    });
  }

  List<Appointment> get _filteredAppointments {
    if (_selectedProfessionalId == null) return _appointments;
    return _appointments
        .where((a) => a.professionalId == _selectedProfessionalId)
        .toList();
  }

  Map<String, List<Appointment>> get _appointmentsByProfessional {
    final filtered = _filteredAppointments;
    final grouped = <String, List<Appointment>>{};
    for (final appt in filtered) {
      final key = appt.professionalId ?? '__unknown__';
      grouped.putIfAbsent(key, () => []).add(appt);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
    return grouped;
  }

  Color _professionalColor(String? professionalId) {
    if (professionalId == null) return Colors.grey;
    final index = _staff.indexWhere((s) => s.id == professionalId);
    if (index >= 0 && index < _professionalColors.length) {
      return _professionalColors[index];
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_isAdmin(user.role)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Calendar'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to access the admin calendar.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Calendar'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(context),
            const SizedBox(height: 20),
            _buildStaffFilter(context),
            const SizedBox(height: 20),
            _buildAppointmentsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime(_focusedDay.year, _focusedDay.month - 2),
          lastDay: DateTime(_focusedDay.year + 2, _focusedDay.month, _focusedDay.day),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          onDaySelected: _onDaySelected,
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            return _appointments.where((a) {
              final apptDay = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
              final targetDay = DateTime(day.year, day.month, day.day);
              return apptDay == targetDay;
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildStaffFilter(BuildContext context) {
    final selectedLabel = _selectedProfessionalId == null
        ? 'All Staff'
        : _staff.firstWhere(
            (s) => s.id == _selectedProfessionalId,
            orElse: () => _staff.isEmpty
                ? User(name: 'Unknown', email: '', phone: '', role: '')
                : _staff.first,
          ).name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Staff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selectedLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StaffChip(
                label: 'All Staff',
                selected: _selectedProfessionalId == null,
                onSelected: () => _onProfessionalSelected(null),
              ),
              if (_staffBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_staffError != null)
                  IconButton(
                    onPressed: () {
                      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
                      final businessId = businessProvider.currentBusiness?.id;
                      if (businessId != null && businessId.isNotEmpty) {
                        setState(() {
                          _staffBusy = true;
                          _staffError = null;
                        });
                        _loadStaff(businessId);
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Retry',
                  )
              else
                ..._staff.map((staff) {
                  final isSelected = _selectedProfessionalId == staff.id;
                  return _StaffChip(
                    label: staff.name,
                    selected: isSelected,
                    onSelected: () => _onProfessionalSelected(staff.id),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(BuildContext context) {
    if (_busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Could not load appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredAppointments;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No appointments for this day',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final grouped = _appointmentsByProfessional;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: grouped.entries.map((entry) {
        final professionalId = entry.key;
        final appts = entry.value;
        final professional = _staff.firstWhere(
          (s) => s.id == professionalId,
          orElse: () => User(name: AppLocalizations.of(context)?.unknownValue ?? 'Unknown', email: '', phone: '', role: ''),
        );
        final color = _professionalColor(professionalId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    professional.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${appts.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...appts.map((appt) => _AdminAppointmentTile(
                    appointment: appt,
                    professionalColor: color,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
      ),
    );
  }
}

class _AdminAppointmentTile extends StatelessWidget {
  const _AdminAppointmentTile({
    required this.appointment,
    required this.professionalColor,
  });

  final Appointment appointment;
  final Color professionalColor;

  @override
  Widget build(BuildContext context) {
    final startTime = TimeOfDay(hour: appointment.dateTime.hour, minute: appointment.dateTime.minute);
    final endTime = TimeOfDay(
      hour: appointment.endTime.hour,
      minute: appointment.endTime.minute,
    );
    final startFormatted = _formatTimeOfDay(startTime);
    final endFormatted = _formatTimeOfDay(endTime);
    final statusColor = _statusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                '$startFormatted\n$endFormatted',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1.3,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 2,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appointment.service,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _localizedStatus(context, appointment.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.customerName ?? AppLocalizations.of(context)?.unknownValue ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appointment.durationMinutes} ${AppLocalizations.of(context)?.minutesLabel ?? 'min'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return Colors.orange;
    case AppointmentStatus.confirmed:
      return Colors.green;
    case AppointmentStatus.completed:
      return Colors.blue;
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return Colors.red;
    case AppointmentStatus.noShow:
      return Colors.grey;
  }
}

String _localizedStatus(BuildContext context, AppointmentStatus status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case AppointmentStatus.pending:
      return l10n?.statusPending ?? 'Pending';
    case AppointmentStatus.confirmed:
      return l10n?.statusConfirmed ?? 'Confirmed';
    case AppointmentStatus.completed:
      return l10n?.statusCompleted ?? 'Completed';
    case AppointmentStatus.cancelledByCustomer:
    case AppointmentStatus.cancelledByProfessional:
      return l10n?.statusCancelled ?? 'Cancelled';
    case AppointmentStatus.noShow:
      return 'No Show';
  }
}