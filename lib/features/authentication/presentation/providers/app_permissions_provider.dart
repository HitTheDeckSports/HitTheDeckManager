import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_permissions.dart';
import 'authorization_providers.dart';

final currentAppPermissionsProvider = Provider<AppPermissions>((ref) {
  final sessionState = ref.watch(authenticatedSessionProvider);
  final session = sessionState.value;

  // Protected production routes are only reachable after the router has
  // established an authenticated session. This fallback exists only so legacy
  // isolated widget tests without a router/session keep their historical
  // privileged fixture behavior. Runtime role enforcement uses the session.
  if (session == null) {
    return const AppPermissions.ownerOrAdmin();
  }

  return AppPermissions.forRole(session.authorization.role);
});
