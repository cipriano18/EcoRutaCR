import 'package:ecorutacr_admin_web/models/sponsor_model.dart';
import 'package:ecorutacr_admin_web/widgets/sponsors/ads/advertisement_registration_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AdvertisementRegistrationModule renders anuncio fields by default',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdvertisementRegistrationModule(
                sponsorsStream: Stream.value([
                  Sponsor(
                    id: 'sp-1',
                    name: 'Cafe Sendero',
                    logoUrl: 'https://example.com/logo.png',
                    type: 'Empresa',
                    contactEmail: 'hola@example.com',
                    phone: '8888-9999',
                    startDate: DateTime(2026, 1, 10),
                    endDate: DateTime(2026, 12, 10),
                    status: 'Activo',
                    paymentType: 'Mensual',
                    isPhysicalBusiness: false,
                    category: 'Restaurante',
                    description: 'Patrocinador de ejemplo con datos completos.',
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Formulario de publicidad'), findsOneWidget);
      expect(find.text('Anuncio'), findsWidgets);
      expect(find.text('FECHA DE INICIO'), findsOneWidget);
      expect(find.text('FECHA DE FIN'), findsOneWidget);
      expect(find.text('HORA DE APERTURA'), findsNothing);
    },
  );

  testWidgets('AdvertisementRegistrationModule toggles to local fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdvertisementRegistrationModule(
              sponsorsStream: Stream.value([
                Sponsor(
                  id: 'sp-1',
                  name: 'Hotel Verde',
                  logoUrl: 'https://example.com/hotel.png',
                  type: 'Empresa',
                  contactEmail: 'hotel@example.com',
                  phone: '2222-3333',
                  startDate: DateTime(2026, 2, 1),
                  endDate: DateTime(2026, 11, 1),
                  status: 'Activo',
                  paymentType: 'Mensual',
                  isPhysicalBusiness: true,
                  latitude: 9.93,
                  longitude: -84.08,
                  category: 'Hotel',
                  description: 'Patrocinador hotelero con presencia local.',
                ),
              ]),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.ensureVisible(find.text('Local').first);
    await tester.tap(find.text('Local').first);
    await tester.pumpAndSettle();

    expect(find.text('HORA DE APERTURA'), findsOneWidget);
    expect(find.text('HORA DE CIERRE'), findsOneWidget);
    expect(find.text('FECHA DE INICIO'), findsNothing);
    expect(
      find.text('Selecciona un punto sobre el mapa para asociar el local.'),
      findsOneWidget,
    );
  });

  testWidgets('AdvertisementRegistrationModule shows empty sponsors state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdvertisementRegistrationModule(
              sponsorsStream: Stream.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.textContaining('No hay patrocinadores registrados todavia'),
      findsOneWidget,
    );
  });
}
