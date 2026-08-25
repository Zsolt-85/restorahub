import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserResolutionHelper {
  final UserRepository _userRepository;
  final Map<String, User> _cache = {};

  UserResolutionHelper({required UserRepository userRepository}) : _userRepository = userRepository;

  Future<String> resolveUserDisplayName(String? userId, {String fallback = 'Unknown'}) async {
    if (userId == null || userId.isEmpty) return fallback;
    try {
      final user = await _getUserById(userId);
      return user?.name ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<String?> resolveUserEmail(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final user = await _getUserById(userId);
      return user?.email;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveUserPhone(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final user = await _getUserById(userId);
      return user?.phone;
    } catch (_) {
      return null;
    }
  }

  Future<User?> _getUserById(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId];
    }
    final user = await _userRepository.getUserById(userId);
    if (user != null) {
      _cache[userId] = user;
    }
    return user;
  }

  void clearCache() {
    _cache.clear();
  }

  void invalidateCache(String userId) {
    _cache.remove(userId);
  }
}
