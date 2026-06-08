import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:vet_application/domain/enums/vet_application_enums.dart';
import 'package:vet_application/domain/models/technician_model.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

final DefaultPluginDescription<TechnicianModel>
technicianPlugin = DefaultPluginDescription<TechnicianModel>(
  moduleId: 'technicians',
  title: VetAppSection.technicians.label,
  icon: VetAppSection.technicians.icon,
  color: VetAppSection.technicians.color,
  order: VetAppSection.technicians.order,

  // The features the plugin supports. The framework uses this to enable/disable UI and functionality.
  features: const PluginFeatureFlags(
    supportsCrud: true,
    supportsRealtime: true,
    supportsUpload: false,
  ),

  routes: [
    SingleRouteDescriptionAndPolicy(
      path: '/technicians',
      builder: (BuildContext ctx, GoRouterState state) => TechnicianPluginPage(
        initialSelectedItemId: state.uri.queryParameters['selected'],
      ),
      accessPolicy:
          OpenDefaultDevelopmentPolicy(), //Todo: change this to real policy after login and persona implementation
    ),
    SingleRouteDescriptionAndPolicy(
      path: '/technicians/:id',
      builder: (BuildContext ctx, GoRouterState state) => TechnicianPluginPage(
        initialSelectedItemId: state.pathParameters['id'],
      ),
      accessPolicy: OpenDefaultDevelopmentPolicy(),
    ),
  ],

  // if login is not implemented default to admin
  visibilityPolicy: PersonaPermissionPolicy({
    VetApplicationEnums.admin.label,
    VetApplicationEnums.operator.label,
  }, denyReason: 'Only admin and operator can view technicians section'),

  // Data binding information for this plugin's model and Firestore collection. The framework uses this to generate a repo and sync with Firestore.
  dataBinding: PluginDataConnector<TechnicianModel>(
    collectionName: 'technicians',
    fromJson: TechnicianModel.fromJson,
    createEmpty: TechnicianModel.new,
  ),
);

class TechnicianPluginPage extends StatelessWidget {
  final String? initialSelectedItemId;

  const TechnicianPluginPage({super.key, this.initialSelectedItemId});

  Widget _buildSection(
    BuildContext context,
    SectionRepo<TechnicianModel> repo,
  ) {
    final cubit = BlocProvider.of<FormCubit<TechnicianModel>>(context);

    return SectionWidget<TechnicianModel>(
      sectionLabel: VetAppSection.technicians.label,
      sectionIcon: VetAppSection.technicians.icon,
      sectionColor: VetAppSection.technicians.color,
      sectionTitle: 'Technicians',
      repo: repo,
      formCubit: cubit,
      initialSelectedItemId: initialSelectedItemId,
      createEmptyModel: TechnicianModel.new,

      rebuildDataModel: (data) => TechnicianModel(
        id: data['id'] as String?,
        active: data['active'] as String?,
        name: data['name'] as String?,
        designation: data['designation'] as String?,
        mobile: data['mobile'] as String?,
        whatsapp: data['whatsapp'] as String?,
        dob: data['dob'] as String?,
        address: data['address'] as String?,
        aadhaarUid: data['aadhaarUid'] as String?,
        uploads: (data['uploads'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      ),

      initialTabDetailBuilder: (item, ctx) => FormPageView(
        formCubit: BlocProvider.of<FormCubit<TechnicianModel>>(ctx),
        dataModel: item,
        supportsCrud: technicianPlugin.features.supportsCrud,
        snackBarEntityName: 'Technician',
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
            key: 'designation',
            fieldType: FieldType.name,
            labelText: 'Designation',
            initialValue: item.designation,
            mandatory: true,
            icon: FontAwesomeIcons.idBadge,
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
            key: 'whatsapp',
            labelText: 'WhatsApp',
            initialValue: item.whatsapp,
            fieldType: FieldType.mobileNumber,
            mandatory: false,
            icon: FontAwesomeIcons.whatsapp,
          ),

          WidgetConfig(
            key: 'dob',
            labelText: 'Date of Birth',
            initialValue: item.dob,
            fieldType: FieldType.date,
            mandatory: false,
            icon: FontAwesomeIcons.birthdayCake,
          ),

          WidgetConfig(
            key: 'aadhaarUid',
            labelText: 'Aadhaar UID',
            initialValue: item.aadhaarUid,
            fieldType: FieldType.name,
            mandatory: false,
            icon: FontAwesomeIcons.solidIdCard,
          ),
        ],

        rebuildDataModel: (data) => TechnicianModel(
          id: data['id'] as String?,
          name: data['name'] as String?,
          address: data['address'] as String?,
          mobile: data['mobile'] as String?,
          whatsapp: data['whatsapp'] as String?,
          dob: data['dob'] as String?,
          aadhaarUid: data['aadhaarUid'] as String?,
          designation: data['designation'] as String?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final FormCubit<TechnicianModel> cubit =
          BlocProvider.of<FormCubit<TechnicianModel>>(context);
      return _buildSection(context, cubit.repo as SectionRepo<TechnicianModel>);
    } catch (_) {
      final repo = SectionRepo<TechnicianModel>.fromDescriptor(
        technicianPlugin,
      );
      return BlocProvider<FormCubit<TechnicianModel>>(
        create: (_) => FormCubit<TechnicianModel>(repo: repo),
        child: Builder(builder: (ctx) => _buildSection(ctx, repo)),
      );
    }
  }
}
