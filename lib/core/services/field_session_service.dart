/// Represents an offline-first inspection workflow.
/// Data should be committed locally after each meaningful field operation.
class FieldSessionService {
  static const autosaveDelay = Duration(milliseconds: 500);

  static bool isInspectionReady({
    required String projectId,
    required String buildingId,
    required String engineer,
  }) {
    return projectId.isNotEmpty &&
        buildingId.isNotEmpty &&
        engineer.trim().isNotEmpty;
  }
}
