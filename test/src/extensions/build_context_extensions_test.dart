import 'package:flutter_test/flutter_test.dart';
import 'package:pamsimas_app/pamsimas_app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AppThemeBuildContext', () {
    testWidgets('appColors returns AppColors from theme', (tester) async {
      late AppColors colors;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            colors = context.appColors;
            return const SizedBox();
          },
        ),
      );

      expect(colors, isA<AppColors>());
    });

    testWidgets('appSpacing returns AppSpacing from theme', (tester) async {
      late AppSpacing spacing;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            spacing = context.appSpacing;
            return const SizedBox();
          },
        ),
      );

      expect(spacing, isA<AppSpacing>());
    });
  });
}
