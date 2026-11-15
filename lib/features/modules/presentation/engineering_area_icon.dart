import 'package:flutter/material.dart';

import '../domain/engineering_area.dart';

/// Ícone de cada área. Fica na apresentação porque o domínio não importa
/// Flutter; o `switch` exaustivo obriga a tratar toda área nova.
extension EngineeringAreaIcon on EngineeringArea {
  IconData get icon => switch (this) {
    EngineeringArea.physics => Icons.motion_photos_on_outlined,
    EngineeringArea.mathematics => Icons.functions_rounded,
    EngineeringArea.civil => Icons.foundation_outlined,
    EngineeringArea.electrical => Icons.electrical_services_outlined,
    EngineeringArea.mechanical => Icons.precision_manufacturing_outlined,
  };
}
