import 'package:material_ui/material_ui.dart';

import '../vision/filters.dart';
import '../vision/vision.dart';

class SimulationSettings extends ChangeNotifier {
  VisionFilter filter = allFilters.first;

  /// Starts at the chosen filter's preset, then follows the slider.
  double severity = allFilters.first.severity;

  VisionMode get mode => filter.mode;

  void select(VisionFilter value) {
    filter = value;
    severity = value.severity;
    notifyListeners();
  }

  void setSeverity(double value) {
    severity = value;
    notifyListeners();
  }
}
