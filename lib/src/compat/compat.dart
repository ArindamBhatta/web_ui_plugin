/// Compatibility layer for code still using the old SectionRepo / SectionService API.
/// New (preferred):
///   `SectionRepo<Model>(moduleId: 'pets', service: FirestoreService(...))`
library;

import 'package:web_ui_plugin/src/core/contracts/data_model.dart';
import 'package:web_ui_plugin/src/adapters/firebase/firestore_service.dart';
import 'package:web_ui_plugin/src/adapters/firebase/section_repo.dart';

typedef SectionService<T extends DataModel> = FirestoreService<T>;

/// @deprecated Use [SectionRepo] with an explicit [moduleId].
/// Creates a SectionRepo under the 'default' moduleId so old call-sites compile.
SectionRepo<T> createSectionRepo<T extends DataModel>(
  FirestoreService<T> service,
) {
  return SectionRepo<T>(moduleId: 'default', service: service);
}
