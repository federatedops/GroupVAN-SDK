/// Session management for GroupVAN SDK
///
/// Handles storage and retrieval of session IDs for catalog API calls.
library session;

import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../logging.dart';

/// Simple session management cubit with persistence
/// Only stores the current session ID string
class SessionCubit extends HydratedCubit<String?> {
  SessionCubit() : super(null);

  /// Update session with new session ID
  void updateSession(String sessionId) {
    GroupVanLogger.sdk.fine('Updating session: $sessionId');
    emit(sessionId);
  }

  /// Clear current session
  void clearSession() {
    GroupVanLogger.sdk.fine('Clearing session');
    emit(null);
  }

  /// Get current session ID
  String? get currentSessionId => state;

  /// Check if session exists
  bool get hasSession => state != null;

  @override
  String? fromJson(Map<String, dynamic> json) {
    try {
      return json['session_id'] as String?;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to restore session from storage: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(String? state) {
    try {
      return state != null ? {'session_id': state} : null;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to persist session to storage: $e');
      return null;
    }
  }
}
