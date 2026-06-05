/// User API: low-level [UserClient] and public [GroupVANUser].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';

/// User API client
class UserClient extends ApiClient {
  const UserClient(super.httpClient, super.authManager);

  /// Get location details
  Future<Result<LocationDetails>> getLocationDetails(String locationId) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/user/$locationId/details',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(LocationDetails.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to get location details: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get location details: $e'),
      );
    }
  }
}

/// Namespaced user API
class GroupVANUser {
  final UserClient _client;

  const GroupVANUser(this._client);

  /// Get location details
  Future<LocationDetails> getLocationDetails(String locationId) async {
    final result = await _client.getLocationDetails(locationId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
