import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

import '../../domain/enums/vet_application_enums.dart';
import '../../domain/models/pet_model.dart';
import '../../domain/models/pet_owner_model.dart';

// Single Source of Truth: - It describes everything the framework needs to know about a plugin/module: its unique ID, display info, routes, data binding, permissions, and features.
final DefaultPluginDescription<PetOwnerModel>
petOwnerPlugin = DefaultPluginDescription<PetOwnerModel>(
  moduleId: 'pet-owners',
  title: VetAppSection.petOwners.label,
  icon: VetAppSection.petOwners.icon,
  color: VetAppSection.petOwners.color,
  order: VetAppSection.petOwners.order,

  /// Optional feature flags that the framework can use to conditionally enable/disable functionality. The plugin author declares which features they use, and the framework handles the rest.
  features: const PluginFeatureFlags(
    supportsCrud: true,
    supportsUpload: true,
    supportsRealtime: true,
  ),

  // All personas can view clients section, but only admin and manager can edit (enforced in the UI and in the API).
  visibilityPolicy: PersonaPermissionPolicy({
    VetApplicationEnums.admin.label,
    VetApplicationEnums.operator.label,
  }),

  /// Data binding: collection, serializer, empty factory. The framework uses this to generate a repo and sync with Firestore. The plugin author only writes the model and the fromJson logic, and the framework handles the rest.
  dataBinding: PluginDataConnector<PetOwnerModel>(
    collectionName: 'petOwners', // Firestore collection name
    fromJson: PetOwnerModel.fromJson,
    createEmpty: PetOwnerModel.new,
  ),

  /// Routes: path, builder, and optional access policy. The framework uses this to generate GoRouter routes and enforce permissions. The plugin author only writes the builder logic, and the framework handles the rest.
  routes: [
    SingleRouteDescriptionAndPolicy(
      path: '/pet-owners', //GoRouter path
      builder: (BuildContext ctx, GoRouterState state) => PetOwnerPluginPage(
        initialSelectedItemId: state.uri.queryParameters['selected'],
      ),
    ),
    SingleRouteDescriptionAndPolicy(
      path: '/pet-owners/:id', //GoRouter path with path parameter
      builder: (BuildContext ctx, GoRouterState state) =>
          PetOwnerPluginPage(initialSelectedItemId: state.pathParameters['id']),
    ),
  ],
);

/// Single source of truth for Pet Owner state. Because this is static, the state and realtime listeners persist even when navigating to other plugins.
class PetOwnerPluginState {
  static final SectionRepo<PetOwnerModel> repo =
      SectionRepo<PetOwnerModel>.fromDescriptor(petOwnerPlugin);

  static final FormCubit<PetOwnerModel> cubit = FormCubit<PetOwnerModel>(
    repo: repo,
  );
}

/// Single source of truth for Pet state inside the sub-section.
class PetPluginState {
  static final DefaultPluginDescription<PetModel> descriptor =
      DefaultPluginDescription<PetModel>(
        moduleId: 'pets',
        title: 'Pets',
        icon: FontAwesomeIcons.dog,
        color: Colors.blue,
        features: const PluginFeatureFlags(
          supportsCrud: true,
          supportsRealtime: true,
        ),
        dataBinding: PluginDataConnector<PetModel>(
          collectionName: 'pets',
          fromJson: PetModel.fromJson,
          createEmpty: PetModel.new,
        ),
      );

  static final SectionRepo<PetModel> repo =
      SectionRepo<PetModel>.fromDescriptor(descriptor);

  static final FormCubit<PetModel> cubit = FormCubit<PetModel>(repo: repo);
}

class PetOwnerPluginPage extends StatelessWidget {
  final String? initialSelectedItemId;

  const PetOwnerPluginPage({super.key, this.initialSelectedItemId});

  Widget _buildSection(BuildContext context, SectionRepo<PetOwnerModel> repo) {
    //When the user clicks "Update" in the FormPageView, the widget looks up the tree using BlocProvider.of<FormCubit<PetOwnerModel>>(context). Instead of finding a global instance from main.dart,
    final FormCubit<PetOwnerModel> cubit =
        BlocProvider.of<FormCubit<PetOwnerModel>>(context);

    return SectionWidget<PetOwnerModel>(
      sectionLabel: VetAppSection.petOwners.label,
      sectionIcon: VetAppSection.petOwners.icon,
      sectionColor: VetAppSection.petOwners.color,
      sectionTitle: 'Pet Owners',
      repo: repo,
      formCubit: cubit,
      initialSelectedItemId: initialSelectedItemId,
      createEmptyModel: PetOwnerModel.new,

      filterExtraTabs: (petOwners) => ["Pets"],

      extraTabViewsBuilder: (petOwner) => [
        (ownerId) => CustomTabularView<PetModel>(
          repo: PetPluginState.repo,
          formCubit: PetPluginState.cubit,
          subSectionTitle: 'Pets',
          createEmptyModel: () => PetModel(ownerId: ownerId),
          filterFunction: (items) =>
              items.where((pet) => pet.ownerId == ownerId).toList(),
          columns: [
            TabularColumn<PetModel>(
              label: 'Pet Name',
              valueMapper: (pet) => pet.name ?? 'Unknown',
            ),
            TabularColumn<PetModel>(
              label: 'Species',
              valueMapper: (pet) => pet.species ?? 'Unknown',
            ),
            TabularColumn<PetModel>(
              label: 'Breed',
              valueMapper: (pet) => pet.breed ?? 'Unknown',
            ),
            TabularColumn<PetModel>(
              label: 'Age (Years)',
              valueMapper: (pet) => pet.age?.toString() ?? 'N/A',
              sortValueMapper: (pet) => pet.age ?? 0,
            ),
          ],
          detailBuilder: (pet, ctx) => FormPageView(
            formCubit: PetPluginState.cubit,
            dataModel: pet,
            supportsCrud: true,
            snackBarEntityName: 'Pet',
            fields: [
              WidgetConfig(
                key: 'name',
                fieldType: FieldType.name,
                labelText: 'Pet Name',
                initialValue: pet.name,
                mandatory: true,
                icon: FontAwesomeIcons.dog,
              ),
              WidgetConfig(
                key: 'species',
                fieldType: FieldType.general,
                labelText: 'Species',
                initialValue: pet.species,
                mandatory: true,
                icon: FontAwesomeIcons.paw,
              ),
              WidgetConfig(
                key: 'breed',
                fieldType: FieldType.general,
                labelText: 'Breed',
                initialValue: pet.breed,
                mandatory: false,
                icon: FontAwesomeIcons.dna,
              ),
              WidgetConfig(
                key: 'age',
                fieldType: FieldType.general,
                labelText: 'Age',
                initialValue: pet.age?.toString(),
                mandatory: false,
                icon: FontAwesomeIcons.clock,
              ),
            ],
            rebuildDataModel: (data) => PetModel(
              id: data['id'] as String?,
              ownerId: ownerId,
              name: data['name'] as String?,
              species: data['species'] as String?,
              breed: data['breed'] as String?,
              age: data['age'] is int
                  ? data['age'] as int
                  : int.tryParse(data['age']?.toString() ?? ''),
            ),
          ),
        ),
      ],

      rebuildDataModel: (data) => PetOwnerModel(
        id: data['id'] as String?,
        name: data['name'] as String?,
        address: data['address'] as String?,
        mobile: data['mobile'] as String?,
        email: data['email'] as String?,
        whatsapp: data['whatsapp'] as String?,
      ),

      initialTabDetailBuilder: (item, ctx) => FormPageView(
        formCubit: BlocProvider.of<FormCubit<PetOwnerModel>>(ctx),
        dataModel: item,
        supportsCrud: petOwnerPlugin.features.supportsCrud,
        snackBarEntityName: 'Pet Owner',
        fields: [
          WidgetConfig(
            key: 'name',
            fieldType: FieldType.name,
            labelText: 'Full Name',
            initialValue: item.name,
            mandatory: true,
            icon: FontAwesomeIcons.solidUser,
          ),

          WidgetConfig(
            key: 'address',
            fieldType: FieldType.address,
            labelText: 'Address',
            initialValue: item.address,
            mandatory: false,
            icon: FontAwesomeIcons.house,
          ),

          WidgetConfig(
            key: 'mobile',
            fieldType: FieldType.mobileNumber,
            labelText: 'Mobile',
            initialValue: item.mobile,
            mandatory: true,
            icon: FontAwesomeIcons.mobileScreen,
          ),

          WidgetConfig(
            key: 'email',
            fieldType: FieldType.email,
            labelText: 'Email',
            initialValue: item.email,
            mandatory: false,
            icon: FontAwesomeIcons.solidEnvelope,
          ),

          WidgetConfig(
            key: 'whatsapp',
            labelText: 'WhatsApp',
            initialValue: item.whatsapp,
            fieldType: FieldType.mobileNumber,
            mandatory: false,
            icon: FontAwesomeIcons.whatsapp,
          ),
        ],

        rebuildDataModel: (data) => PetOwnerModel(
          id: data['id'] as String?,
          name: data['name'] as String?,
          address: data['address'] as String?,
          mobile: data['mobile'] as String?,
          email: data['email'] as String?,
          whatsapp: data['whatsapp'] as String?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide the persistent, strictly-typed cubit to the widget tree for this route.
    // FormPageView and SectionWidget will successfully find it via BlocProvider.of!
    return BlocProvider.value(
      //it finds the static singleton (PetOwnerPluginState.cubit) that you injected at the top of the page using BlocProvider.value.
      value: PetOwnerPluginState.cubit,
      child: Builder(
        builder: (ctx) => _buildSection(ctx, PetOwnerPluginState.repo),
      ),
    );
  }
}

/* 
Step 1: The UI Trigger (Finding the Instance)
When the user clicks "Update" in the FormPageView, the widget looks up the tree using BlocProvider.of<FormCubit<PetOwnerModel>>(context). Instead of finding a global instance from main.dart, it finds the static singleton (PetOwnerPluginState.cubit) that you injected at the top of the page using BlocProvider.value.

Step 2: The Cubit Intent (Optimistic UI)
The UI calls cubit.updateItem(...). The FormCubit immediately emits a FormInProgress state. The UI sees this state and instantly changes the "Update" button to a spinning loading indicator.

Step 3: The Repository & Backend Adapter
The FormCubit doesn't talk to the database directly. It passes the updated data down to the SectionRepo. The SectionRepo passes it to the FirestoreService (the adapter). The FirestoreService executes the actual write command to Firebase Firestore.

Step 4: The Realtime "Magic" Loop (The Reactive Part)
This is where your architecture shines. When the data saves to Firebase, two things happen simultaneously:

Path A: The Form Success The FirestoreService write completes successfully. The FormCubit finishes its method and emits a FormSuccess state. The FormPageView listens to this and triggers the green "Saved successfully" Snackbar.

Path B: The Real-time List Update Because your plugin declared supportsRealtime: true in its features, the FirestoreService has an active snapshot listener pointing at the petOwners collection in Firebase.

Firebase instantly pushes the updated collection back to your app.
FirestoreService receives it and pushes it into the SectionRepo's broadcast stream (dataStream).
The SectionCubit (which drives the list on the left side of your screen) is constantly listening to this dataStream.
It receives the new data, applies any active search/status filters, and emits a new SectionState.
The SectionWidget rebuilds the list instantly showing the newly updated Pet Owner name!
Summary of the Flow
Unlike a standard Bloc app where the Bloc has to manually tell the UI to update its lists after a save, your architecture is strictly Data-Driven.

Action Flow: UI ➔ FormCubit ➔ Repo ➔ Firebase.
Reactive Flow: Firebase ➔ Repo Stream ➔ SectionCubit ➔ UI List Rebuilds

By using PetOwnerPluginState to hold the repo and cubit in static memory, that "Reactive Flow" stays alive in the background. Even if the user navigates away to the "Doctors" page and comes back, the data is instantly there without having to reload!

 */
