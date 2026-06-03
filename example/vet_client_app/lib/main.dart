import 'package:flutter/material.dart';
import 'package:vet_application/view/vet_application.dart';

import 'package:web_ui_plugin/web_ui_plugin.dart';

import 'app/vet_application_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: -Paste your new Firebase project values here.
  const FirebaseApiConfig customFirebaseConfig = FirebaseApiConfig(
    apiKey: 'AIzaSyD0J_5aqolfSn9uDnkcVfVvyrQjZc2gaBg',
    appId: '1:593360566365:web:ed338bacd98cdb509075b4',
    messagingSenderId: '593360566365',
    projectId: 'chat-app-44a75',
    authDomain: 'chat-app-44a75.firebaseapp.com',
    storageBucket: 'chat-app-44a75.firebasestorage.app',
    measurementId: 'G-RK7YFJGJJC',
  );

  // use getter to check if the config is complete, otherwise pass null to use default options.
  final FirebaseApiConfig? firebaseConfig = customFirebaseConfig.isComplete
      ? customFirebaseConfig
      : null;

  try {
    //Step 2: -initializes Firebase, sets up the user, and registers plugins.
    await VetApplicationBootstrap.run(
      useEmulators: true,
      firebaseConfig: firebaseConfig,
    );

    // Step 3: -builds the app with the router and plugin-generated shell.
    runApp(
      /// when we call AppBootstrap.buildRouterApp, the framework creates a GoRouter instance.
      AppBootstrap.buildRouterApp(
        title: 'Vet Client App',
        theme: AppTheme.lightTheme.copyWith(
          colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
            primary: AppColors.primary,
          ),
        ),
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // The shellBuilder we provided acts as a wrapper for every page in this app.
        //when a user navigates to a route (like /pet-owners), GoRouter takes the PetOwnerPluginPage and passes it as the child argument to your VetApplication.
        shellBuilder: (context, child) => VetApplication(child: child),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Application Initialization failed: $error'),
          ),
        ),
      ),
    );
  }
}
