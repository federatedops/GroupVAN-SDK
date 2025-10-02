import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class AuthStatus extends StatelessWidget {
  const AuthStatus({super.key});

  @override
  Widget build(BuildContext context) {
    AuthSession? session = GroupVAN.instance.auth.currentSession;
    User? user = GroupVAN.instance.auth.currentUser;

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
            if (user != null) ...[
              _buildStatusRow('Email:', user.email),
              _buildStatusRow('Name:', user.name),
              _buildStatusRow('Created At:', user.createdAt.toString()),
              _buildStatusRow('Picture:', user.picture ?? 'N/A'),
              _buildStatusRow('Member ID:', user.memberId ?? 'N/A'),
              _buildStatusRow('Location:', user.location?.name ?? 'N/A'),
            ],

            if (session?.accessToken != null)
              _buildStatusRow(
                'Access Token Preview:',
                '${session!.accessToken.substring(0, 10)}...${session.accessToken.substring(session!.accessToken.length - 10)}',
              ),
            if (session?.refreshToken != null)
              _buildStatusRow(
                'Refresh Token Preview:',
                '${session!.refreshToken.substring(0, 10)}...${session.refreshToken.substring(session!.refreshToken.length - 10)}',
              ),
            if (session?.expiresAt != null)
              _buildStatusRow('Expires:', session!.expiresAt.toString()),
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
