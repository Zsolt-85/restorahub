import '../repositories/booking_repository.dart';
import '../repositories/local_booking_repository.dart';

enum SyncStatus { idle, success, failed }

class SyncResult {
  final SyncStatus status;
  final String message;
  final int pushedCount;
  final int pulledCount;

  const SyncResult({
    required this.status,
    required this.message,
    this.pushedCount = 0,
    this.pulledCount = 0,
  });
}

/// Local-first sync layer. Replace the TODO sections with REST calls when a
/// backend is available.
class SyncService {
  SyncService({BookingRepository? repository})
      : _repository = repository ?? LocalBookingRepository.instance;

  final BookingRepository _repository;

  Future<SyncResult> pushPendingChanges() async {
    try {
      final appointments = await _repository.getAppointments();
      // TODO: POST /appointments for records not yet synced.
      return SyncResult(
        status: SyncStatus.success,
        message: 'Local data ready to push (${appointments.length} records).',
        pushedCount: 0,
      );
    } catch (error) {
      return SyncResult(
        status: SyncStatus.failed,
        message: 'Push failed: $error',
      );
    }
  }

  Future<SyncResult> pullRemoteChanges() async {
    try {
      // TODO: GET /appointments and /users, merge into local repository.
      await _repository.getAppointments();
      return const SyncResult(
        status: SyncStatus.success,
        message: 'Using local data until remote API is configured.',
        pulledCount: 0,
      );
    } catch (error) {
      return SyncResult(
        status: SyncStatus.failed,
        message: 'Pull failed: $error',
      );
    }
  }

  Future<SyncResult> syncAll() async {
    final pullResult = await pullRemoteChanges();
    if (pullResult.status == SyncStatus.failed) return pullResult;
    return pushPendingChanges();
  }
}
