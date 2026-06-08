import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:web_ui_plugin/web_ui_plugin.dart';

//PluginRouteBuilder is a function type that defines how to build a widget for a given route,
typedef PluginRouteBuilder =
    Widget Function(BuildContext context, GoRouterState state);

///Step 1: PluginFeatureFlags is a simple class that groups together boolean flags indicating(CRUD, realtime updates, file uploads).
class PluginFeatureFlags {
  final bool supportsCrud;
  final bool supportsRealtime;
  final bool supportsUpload;

  const PluginFeatureFlags({
    this.supportsCrud = true,
    this.supportsRealtime = true,
    this.supportsUpload = false,
  });
}

///Step 2: SingleRouteDescriptionAndPolicy Describes a single route a user navigate to this route?.
class SingleRouteDescriptionAndPolicy {
  final String path;
  final PluginRouteBuilder builder; //pass typedef
  final OpenDefaultDevelopmentPolicy? accessPolicy;

  const SingleRouteDescriptionAndPolicy({
    required this.path,
    required this.builder,
    this.accessPolicy,
  });
}

///Step 3  Data binding information for a plugin's model and Firestore collection.
class PluginDataConnector<T extends DataModel> {
  final String collectionName;
  final T Function(Map<String, dynamic> json) fromJson;
  final T Function() createEmpty;

  const PluginDataConnector({
    required this.collectionName,
    required this.fromJson,
    required this.createEmpty,
  });
}

/// 🌱 The top-level description
/// a developer provides to register a plugin. This is the entire surface area a module author fills in.
class DefaultPluginDescription<T extends DataModel> {
  /// Stable unique identifier.
  final String moduleId;

  /// Display metadata shown in sidebar and headers.
  final String title;
  final IconData icon;
  final Color color;
  final int order;

  /// Enable or disable features like CRUD, realtime updates, and file uploads.
  final PluginFeatureFlags features;

  /// Routes this plugin contributes.
  final List<SingleRouteDescriptionAndPolicy> routes;

  ///Step 3:  Data binding: collection, serializer, empty factory.
  final PluginDataConnector<T> dataBinding;

  /// Visibility policy: is this plugin shown to current user?
  final PermissionPolicyAgreement? visibilityPolicy;

  /// Optional lifecycle hooks.
  final Future<void> Function()? onRegister;
  final Future<void> Function()? onDispose;

  const DefaultPluginDescription({
    required this.moduleId,
    required this.title,
    required this.icon,
    required this.color,
    required this.dataBinding,
    this.order = 0,
    this.features = const PluginFeatureFlags(),
    this.routes = const [],
    this.visibilityPolicy,
    this.onRegister,
    this.onDispose,
  });
}
