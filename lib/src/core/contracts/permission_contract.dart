/// Represents a role assigned to a user within the framework.
class UserRole {
  final String id;
  final String name;

  const UserRole({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRole && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Identity of the currently authenticated user [PermissionMiddleware] and [LoginSignUpPage] [AppBootstrap].
class UserIdentity {
  final String userId;
  final String? email;
  final String? name;
  final String? mobile;
  final UserRole role;

  /// Backwards compatibility getter for persona (returns role.id).
  String get persona => role.id;

  const UserIdentity({
    required this.userId,
    required this.role,
    this.email,
    this.name,
    this.mobile,
  });
}

//
//                             ----------- Permission ---------------
//

// Create instance where need permission evaluation like visibility, route access, etc.[PermissionMiddleware]
class PermissionContext {
  final UserIdentity user;
  final String moduleId;
  final String? routePath;

  const PermissionContext({
    required this.user,
    required this.moduleId,
    this.routePath,
  });
}

/// Result of a permission evaluation.
class PermissionResult {
  final bool granted;
  final String? reason;
  const PermissionResult.granted() : granted = true, reason = null;
  const PermissionResult.denied(this.reason) : granted = false;
}

/// Implement this in the consuming app to encode your Role-Based Access Control logic.[DefaultPluginDescription] [PermissionMiddleware] and [AppBootstrap].
abstract interface class PermissionPolicyAgreement {
  PermissionResult evaluate(PermissionContext context);
}

//! Default open policy — grants everything. Use only in development.
class OpenDefaultDevelopmentPolicy implements PermissionPolicyAgreement {
  const OpenDefaultDevelopmentPolicy();

  @override
  PermissionResult evaluate(PermissionContext context) =>
      const PermissionResult.granted();
}

/// Restricts access to users whose persona is in the [doctorPlugin] set.
class PersonaPermissionPolicy implements PermissionPolicyAgreement {
  final Set<String> allowedPersonas;
  final String? denyReason;

  const PersonaPermissionPolicy(this.allowedPersonas, {this.denyReason});

  @override
  PermissionResult evaluate(PermissionContext context) {
    final normalizedPersona = context.user.persona.trim().toLowerCase();
    final normalizedAllowedPersonas = allowedPersonas
        .map((persona) => persona.trim().toLowerCase())
        .toSet();

    if (normalizedAllowedPersonas.contains(normalizedPersona)) {
      return const PermissionResult.granted();
    }
    return PermissionResult.denied(
      denyReason ??
          'Role ${context.user.persona} cannot access ${context.moduleId}',
    );
  }
}
