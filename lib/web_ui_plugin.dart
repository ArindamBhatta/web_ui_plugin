/// web_ui_plugin — Plug-and-play SaaS admin UI package.
///
/// To use this package:
/// 1. Define your entity (implements [DataModel]).
/// 2. Define your section/persona enums.
/// 3. Define your view widget.
/// 4. Register a [PluginDescriptor] in [AppBootstrap].
///
/// Firebase is the default adapter. No other backend setup is required.
library;

// ── Core contracts ────────────────────────────────────────────────────────────
export 'src/core/contracts/data_model.dart';
export 'src/core/form/service/form_service_mixin.dart';
export 'src/core/contracts/default_plugin_description.dart';
export 'src/core/contracts/permission_contract.dart';
export 'src/core/contracts/upload_contract.dart';

// ── Registry ─────────────────────────────────────────────────────────────────
export 'src/core/registry/singleton_scoped_registry.dart';
export 'src/core/registry/plugin_registry.dart';

// ── Bootstrap ─────────────────────────────────────────────────────────────────
export 'src/core/bootstrap/app_bootstrap.dart';

// ── Permissions ───────────────────────────────────────────────────────────────
export 'src/core/permissions/permission_middleware.dart';
// ── Theme ──────────────────────────────────────────────────────────────────────
export 'src/core/theme/app_theme.dart';
export 'src/core/theme/app_colors.dart';
export 'src/core/theme/theme_extensions.dart';
export 'src/core/theme/brand_blues.dart';
export 'src/core/theme/outer_space_stage.dart';
// ── Navigation ────────────────────────────────────────────────────────────────
export 'src/core/navigation/plugin_left_navigation.dart';

// ── Form layer (cubit + state + page + field widgets) ─────────────────────────
export 'src/core/form/cubit/form_cubit.dart';
export 'src/core/form/form_page.dart';
export 'src/core/form/widgets/general_form_field.dart';
export 'src/core/form/widgets/form_dropdown_field.dart';
export 'src/core/form/widgets/form_multiselect_field.dart';
export 'src/core/form/widgets/form_date_field.dart';
export 'src/core/form/widgets/form_time_field.dart';
export 'src/core/form/widgets/form_age_field.dart';
export 'src/core/form/repo/form_repo_mixin.dart';

// ── Section layer (cubit + state + widgets) ───────────────────────────────────
export 'src/core/section/cubit/section_cubit.dart';
export 'src/core/section/widget/section_view.dart';
export 'src/core/section/widget/section_widget.dart';
export 'src/core/section/widget/sub_section_view.dart';
export 'src/core/section/widget/custom_list_view.dart';
export 'src/core/section/widget/custom_list_tile.dart';
export 'src/core/section/widget/plugin_grid_view.dart';
export 'src/core/section/widget/no_data_view.dart';
export 'src/core/section/widget/custom_tabular_view.dart';

// ── Shared UI primitives ──────────────────────────────────────────────────────
export 'src/core/widgets/custom_button.dart';
export 'src/core/widgets/custom_dialog_box.dart';
export 'src/core/widgets/custom_snack_bar.dart';
export 'src/core/widgets/custom_textfield.dart';
export 'src/core/widgets/customizable_search_bar.dart';
export 'src/core/widgets/package_enums.dart';
export 'src/core/widgets/kpi_card_widget.dart';

// ── Utility functions ─────────────────────────────────────────────────────────
export 'src/core/functions/date_time_utils.dart';

// ── Firebase adapter (default) ────────────────────────────────────────────────
export 'src/adapters/firebase/firestore_service.dart';
export 'src/adapters/firebase/section_repo.dart';

// ── Compatibility layer (incremental migration from old SectionRepo/SectionService)
export 'src/compat/compat.dart';
