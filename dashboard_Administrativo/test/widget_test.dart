import 'package:ecorutacr_admin_web/widgets/auth_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthCard renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthCard(
            title: 'Titulo',
            subtitle: 'Subtitulo',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('Titulo'), findsOneWidget);
    expect(find.text('Subtitulo'), findsOneWidget);
  });
}
