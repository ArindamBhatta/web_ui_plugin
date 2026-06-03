import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_application/view/plugin_ui/technician_plugin.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

import '../view/plugin_ui/pet_owner_plugin.dart';
import '../view/plugin_ui/doctor_plugin.dart';
import '../view/plugin_ui/dashboard_plugin.dart';

/// Optional Firebase config for connecting this example app to a different
/// Firebase project without editing package-level generated files.
class FirebaseApiConfig {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? measurementId;

  const FirebaseApiConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.measurementId,
  });

  bool get isComplete =>
      apiKey.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      messagingSenderId.trim().isNotEmpty &&
      projectId.trim().isNotEmpty;
  // Converts this config to the standard [FirebaseOptions] used by Firebase.initializeApp.
  FirebaseOptions toFirebaseOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId,
    );
  }
}

/// All app wiring in one place.
/// main.dart calls [VetApplicationBootstrap.run].

class VetApplicationBootstrap {
  /// Private constructor to prevent instantiation.
  VetApplicationBootstrap._();

  /// Local setup for development — initializes Firebase, sets a dev user, and registers plugins.
  static Future<void> run({
    bool useEmulators = false,
    FirebaseApiConfig? firebaseConfig,
  }) async {
    if (firebaseConfig != null && !firebaseConfig.isComplete) {
      throw ArgumentError(
        'Incomplete firebaseConfig. Provide apiKey, appId, '
        'messagingSenderId, and projectId.',
      );
    }

    final FirebaseOptions? firebaseOptions = firebaseConfig
        ?.toFirebaseOptions();

    // Step 1: Initialize Firebase
    await AppBootstrap.initialize(
      config: BootstrapConfig(
        initializeFirebase: () async {
          await Firebase.initializeApp(options: firebaseOptions);
          if (useEmulators) {
            FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
            FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
            //Use other emulators as needed, e.g. Storage emulator on 9199
          }
        },
        defaultPermissionPolicy:
            const OpenDefaultDevelopmentPolicy(), // Use a permissive policy for development. Replace with real policies in production.
      ),
    );

    // Step 2: Important - Authorization Setup (Access denied without this!) write now it’s a dummy user for development, but you can replace it with real auth logic.
    PermissionMiddleware.instance.setUser(
      const UserIdentity(
        userId: '0000-0000-0000-0000-000000000001',
        persona: 'admin',
        email: 'arindambhattacharyya.ab@gmail.com',
      ),
    );

    // Step 3: Register plugins — this is the entire app configuration example route wiring happens here. Each plugin registers its own routes and dependencies.
    await AppBootstrap.registerPlugins([
      dashboardPlugin,
      doctorsPlugin,
      petOwnerPlugin,
      technicianPlugin,
    ]);
  }
}
