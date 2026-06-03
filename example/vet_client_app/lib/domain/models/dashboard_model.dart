import 'package:web_ui_plugin/web_ui_plugin.dart';

/// A lightweight placeholder model for the Dashboard module
class DashboardModel extends DataModel {
  final String? id;

  DashboardModel({this.id = 'dashboard'});

  @override
  String? get uid => id;

  @override
  String? get title => 'Dashboard';

  @override
  String? get subTitle => 'Overview';

  @override
  Map<String, dynamic> toJson() => {'id': id};
}
