import 'package:flutter_test/flutter_test.dart';

import '../helpers/journeys.dart';

void main() {
  testWidgets('Main journey (spec §57)', mainJourney);
  testWidgets('Pet journey (spec §58)', petJourney);
  testWidgets('Commercial journey (spec §59)', commercialJourney);
}
