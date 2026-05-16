import 'package:ecorutacr_admin_web/widgets/sponsor_registration_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SponsorRegistrationForm renders first step', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SponsorRegistrationForm(onSave: (_) {})),
      ),
    );

    expect(find.text('Registrar patrocinadores'), findsOneWidget);
    expect(find.text('Datos basicos'), findsWidgets);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
