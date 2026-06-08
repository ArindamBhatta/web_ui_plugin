# web_ui_plugin

## 🚀 WebUI Plugins: The SaaS Builder's Dream

Building SaaS applications doesn't have to be complex. **WebUI Plugins** is a modular, plug-and-play framework for Flutter Web that brings professional design and functionality without the architectural headache.

### What makes it different?

*   ✨ **Minimal Setup** — Define your data models and UI, let the framework handle the rest.
*   🔄 **Automatic Magic** — Automatically generates forms, validation, and data handling logic.
*   ⚡ **Production-Ready** — Built with Firebase integration out of the box.
*   🎨 **Web-Grade UI** — Professional, responsive design that feels native to the browser.
*   📦 **Truly Modular** — Register plugins, build features independently, and scale effortlessly.

**Perfect for:** Bootstrapped founders, indie hackers, and dev teams who want to ship SaaS faster without sacrificing quality.

---

## The 4-Step Developer Experience

### 1. Define your Data Model
```dart
class PetOwnerModel extends DataModel {
  final String? id, name, mobile;
  PetOwnerModel({this.id, this.name, this.mobile});
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name, 'mobile': mobile};
  factory PetOwnerModel.fromJson(Map<String, dynamic> json) => ...;
  @override String? get uid => id;
}
```

### 2. Create the Declarative UI
Use `FormPageView` with `WidgetConfig`. The framework handles the layout and state automatically.
```dart
initialTabDetailBuilder: (item, ctx) => FormPageView(
  fields: [
    WidgetConfig(key: 'name', fieldType: FieldType.name, labelText: 'Full Name'),
    WidgetConfig(key: 'mobile', fieldType: FieldType.mobileNumber, labelText: 'Mobile'),
  ],
  rebuildDataModel: (data) => PetOwnerModel.fromJson(data),
)
```

### 3. Register the Plugin Descriptor
Define identity, permissions, and routing in a single object.
```dart
final petOwnerPlugin = PluginDescriptor<PetOwnerModel>(
  moduleId: 'pet-owners',
  title: 'Pet Owners',
  icon: Icons.person,
  dataBinding: PluginDataBinding<PetOwnerModel>(
    collectionName: 'petOwners',
    fromJson: PetOwnerModel.fromJson,
    createEmpty: PetOwnerModel.new,
  ),
  routes: [ ... ],
);
```

### 4. Bootstrap and Run
Initialize the framework and register your plugins in `main.dart`.
```dart
void main() async {
  await AppBootstrap.initialize(config: BootstrapConfig(...));
  await AppBootstrap.registerPlugins([petOwnerPlugin]);
  runApp(AppBootstrap.buildRouterApp(
    title: 'My SaaS App',
    shellBuilder: (context, child) => MyShell(child: child),
  ));
}
```

---

## 🏗️ Feature Status (Current State)

*   ✅ **Modular Registry:** Plugin system is fully operational.
*   ✅ **Firebase Integration:** Firestore CRUD and Realtime streams are live.
*   ✅ **Permission System:** Persona-based sidebar and route gating is live.
*   ✅ **Scoped Repositories:** Individual data isolation per plugin (Backlog #4 Fixed).
*   🚧 **Image Uploads [WORK IN PROGRESS]:** `UploadCapability` contract is defined; Firebase Storage adapter implementation is underway.
*   🚧 **Theme Engine & Dark Mode [WORK IN PROGRESS]:** Base theming is available; automatic switching and deep customization are being refined.

---

## Core Framework Architecture

*   **PluginRegistry:** Central source of truth for all modules.
*   **ScopedRepo:** Isolated data access layer per module (Backend-agnostic).
*   **SectionWidget:** High-performance two-pane master/detail layout.
*   **PermissionMiddleware:** Dual-layer security (Sidebar visibility + Route guards).

## Roadmap 🛣️



-- firebase emulators:start --import=./emulator-data --export-on-exit