import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class AuthStatus extends StatelessWidget {
  const AuthStatus({super.key, this.authState});

  final AuthState? authState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildStatusRow('Status:', 'Authenticated'),

            if (authState?.user != null)
              _buildStatusRow('Client ID:', authState?.user?.clientId ?? 'N/A'),
            if (authState?.user != null)
              _buildStatusRow('Member:', authState?.user?.member ?? 'N/A'),
            if (authState?.session?.accessToken != null)
              _buildStatusRow(
                'Access Token Preview:',
                '${authState!.session!.accessToken.substring(0, 10)}...${authState!.session!.accessToken.substring(authState!.session!.accessToken.length - 10)}',
              ),
            if (authState?.session?.refreshToken != null)
              _buildStatusRow(
                'Refresh Token Preview:',
                '${authState!.session!.refreshToken.substring(0, 10)}...${authState!.session!.refreshToken.substring(authState!.session!.refreshToken.length - 10)}',
              ),
            if (authState?.session?.expiresAt != null)
              _buildStatusRow(
                'Expires:',
                authState!.session!.expiresAt.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
