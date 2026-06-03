# web_ui_plugin — Architecture
---

## 1. Goal

Build a plug-and-play plugin framework where an end developer onboards a new domain module with minimal work:

1. Define an entity/model class (extends `DataModel`).
2. Define enums (section, persona, status, etc.).
3. Define a view widget.
4. Register a `PluginDescriptor` in bootstrap.

Everything else — state, repo, service, routing, permissions, sidebar, CRUD, uploads — is wired by the framework.

Targets multi-module SaaS products: clinic, medical admin, etc.

---

## 2. Package Structure

```
lib/
├── web_ui_plugin.dart          ← public barrel export (only file consumers import)
└── src/
    ├── core/
    │   ├── contracts/           ← backend-agnostic interfaces + shared config
    │   │   ├── data_model.dart                  ← base Model
    │   │   ├── default_plugin_descriptor.dart   ← Defend all Contract what end user needs
    │   │   ├── globals.dart                     ← shared UI constants (form sizes, padding)
    │   │   ├── permission_contract.dart         ← All Access permission policy
    │   │   ├── upload_contract.dart             ← ......
   
    │   ├── registry/
    │   │   └── plugin_registry.dart               ← All plugins register here during bootstrap
    │   │   ├── singleton_scoped_registry.dart     ← SingletonScopedRegistry<T> + CrossModuleSingletonKey(moduleId/model/collection)


    │   ├── bootstrap/
    │   │   └── app_bootstrap.dart       ← initialize → registerPlugins → buildApp / buildRouterApp

    │   ├── permissions/
    │   │   └── permission_middleware.dart  ← PermissionMiddleware + PermissionGuard (for go_router)

    │   ├── form/
    │   │   ├── cubit/
    │   │   │   ├── form_cubit.dart      ← FormCubit<T> (create/read/update/delete intents)
    │   │   │   └── form_state.dart      ← FormViewState sealed class (Initial/InProgress/Loaded/Success/Failure)
    │   │   ├── repo/
    │   │   │   └── form_repo_mixin.dart ← FormRepoMixin<T> (local cache + broadcast stream)
    │   │   ├── form_page.dart           ← FormPageView + WidgetConfig declarative field API
    │   │   └── widgets/                 ← GeneralFormField, FormDropdown, FormDate, FormTime, FormAge, FormMultiSelect
    │   ├── section/
    │   │   ├── cubit/
    │   │   │   ├── section_cubit.dart   ← SectionCubit<T> (search, status filter, date range, item selection)
    │   │   │   └── section_state.dart   ← SectionState<T> (items, filteredItems, selectedItem, filters)
    │   │   └── widget/
    │   │       ├── section_view.dart    ← two-pane master/detail layout
    │   │       ├── section_widget.dart  ← SectionWidget (wraps cubit + view)
    │   │       ├── sub_section_view.dart
    │   │       ├── custom_list_view.dart
    │   │       ├── custom_list_tile.dart
    │   │       └── no_data_view.dart
    │   ├── navigation/
    │   │   └── plugin_left_navigation.dart  ← sidebar driven by PluginRegistry + PermissionMiddleware
    │   ├── widgets/                     ← shared UI primitives
    │   │   ├── custom_button.dart
    │   │   ├── custom_dialog_box.dart
    │   │   ├── custom_snack_bar.dart
    │   │   ├── custom_textfield.dart
    │   │   ├── customizable_search_bar.dart
    │   │   └── package_enums.dart       ← SnackBarCategory, SuccessStatus, etc.
    │   └── functions/
    │       └── date_time_utils.dart     ← date formatting helpers
    ├── adapters/
    │   └── firebase/                    ← official default adapter
    │       ├── firestore_service.dart   ← FirestoreService<T> (CRUD + realtime listener + Cloud Fn IDs)
    │       └── scoped_repo.dart         ← ScopedRepo<T> (replaces SectionRepo)
    └── compat/
        └── compat.dart                  ← migration shims for old SectionRepo/SectionService code

example/
└── vet_clinic_web/                               ← reference consumer app
    ├── pubspec.yaml                              ← depends on web_ui_plugin via path
    └── lib/
        ├── main.dart                              ← 3-step app_bootstrap.run() and buildRouterApp()
        ├── app/
        │   └── vet_application_bootstrap.dart     ← initialize Firebase, default author, plugins
        ├── domain/
        │   ├── enums/             
        │   └── models/            
        └── view/
            └── vet_application.dart   ← Left Navigation is defined here, but driven by PluginRegistry + PermissionMiddleware
```



