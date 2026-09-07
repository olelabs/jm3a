// Guards against accidentally shipping the temporary diagnostic switch
// (kTodDisableHonestyUiForDiagnosis in tod_card_screen.dart, added to
// isolate whether the honesty UI is involved in the "remote player sees
// a blank result screen" report — see that file's doc comment) turned on.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/screens/tod_card_screen.dart';

void main() {
  test('the honesty-UI diagnostic disable switch defaults to false — it '
      'must never ship as true', () {
    expect(kTodDisableHonestyUiForDiagnosis, isFalse);
  });
}
