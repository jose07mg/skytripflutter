import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skytrip/core/services/hotel_service.dart';
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/features/home/edit_hotel_page.dart';

void main() {
  testWidgets('blocks access when the user is not admin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditHotelPage(
          hotel: const {},
          hotelService: _FakeHotelService(),
          authState: const _FakeAuthState(isAdmin: false),
        ),
      ),
    );

    expect(find.text('Acceso Denegado'), findsOneWidget);
    expect(
      find.text('Solo los administradores pueden editar hoteles'),
      findsOneWidget,
    );
  });

  testWidgets('updates an existing hotel with normalized form data', (
    tester,
  ) async {
    final service = _FakeHotelService(
      ciudades: [
        {'id_ciudad': 7, 'nombre': 'Madrid', 'pais_nombre': 'España'},
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditHotelPage(
          hotel: const {
            'idHotel': '42',
            'hotelName': 'Hotel Antiguo',
            'description': 'Texto antiguo',
            'city': 'Madrid',
            'price': '80.0',
            'estrellas': '4',
            'maxPeople': '2',
            'distanceCenter': '1.2',
            'distanceAirport': '12.5',
            'rating': '8.1',
            'image': '',
            'servicios': ['WiFi gratis', 'Piscina'],
          },
          hotelService: service,
          authState: const _FakeAuthState(isAdmin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _enterField(tester, 'Nombre del hotel', 'Hotel Nuevo');
    await _enterField(tester, 'Descripción', 'Texto nuevo');
    await _enterField(tester, 'Dist. al centro (km)', '0,8');
    await _enterField(tester, 'Dist. aeropuerto (km)', '14,3');
    await _enterField(tester, 'Precio/noche (€)', '99,50');
    await _enterField(tester, 'Puntuación (0-10)', '9,2');
    await _enterField(tester, 'Servicios', 'WiFi gratis, Spa, Piscina');

    await tester.tap(find.byIcon(Icons.save).last);
    await tester.pumpAndSettle();

    expect(service.updatedHotelId, 42);
    expect(service.updatedHotelData?['nombre'], 'Hotel Nuevo');
    expect(service.updatedHotelData?['biografia'], 'Texto nuevo');
    expect(service.updatedHotelData?['id_ciudad'], 7);
    expect(service.updatedHotelData?['precio_noche'], 99.5);
    expect(service.updatedHotelData?['puntuacion'], 9.2);
    expect(service.updatedHotelData?['distancia_centro_km'], 0.8);
    expect(service.updatedHotelData?['distancia_aeropuerto_km'], 14.3);
    expect(service.updatedHotelData?['servicios'], [
      'WiFi gratis',
      'Spa',
      'Piscina',
    ]);
  });

  testWidgets('creates a hotel using the selected city', (tester) async {
    final service = _FakeHotelService(
      ciudades: [
        {'id_ciudad': 3, 'nombre': 'Lisboa', 'pais_nombre': 'Portugal'},
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditHotelPage(
          hotel: const {'ciudad_nombre': 'Lisboa'},
          hotelService: service,
          authState: const _FakeAuthState(isAdmin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _enterField(tester, 'Nombre del hotel', 'Hotel Luz');
    await _enterField(tester, 'Precio/noche (€)', '120');

    await tester.tap(find.byIcon(Icons.save).last);
    await tester.pumpAndSettle();

    expect(service.createdHotelData?['nombre'], 'Hotel Luz');
    expect(service.createdHotelData?['id_ciudad'], 3);
    expect(service.createdHotelData?['precio_noche'], 120);
  });

  testWidgets('deletes a hotel only after confirmation', (tester) async {
    final service = _FakeHotelService(
      ciudades: [
        {'id_ciudad': 7, 'nombre': 'Madrid', 'pais_nombre': 'España'},
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditHotelPage(
          hotel: const {
            'id_hotel': 42,
            'nombre': 'Hotel Test',
            'id_ciudad': 7,
            'precio_noche': 100,
          },
          hotelService: service,
          authState: const _FakeAuthState(isAdmin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(service.deletedHotelId, isNull);

    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(service.deletedHotelId, 42);
  });
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = find.widgetWithText(TextFormField, label);
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(finder, value);
}

class _FakeAuthState implements AuthStateReader {
  const _FakeAuthState({required this.isAdmin});

  @override
  final bool isAdmin;
}

class _FakeHotelService implements HotelEditorService {
  _FakeHotelService({this.ciudades = const []});

  final List<Map<String, dynamic>> ciudades;
  Map<String, dynamic>? createdHotelData;
  int? updatedHotelId;
  Map<String, dynamic>? updatedHotelData;
  int? deletedHotelId;

  @override
  Future<List<Map<String, dynamic>>> getCiudades() async => ciudades;

  @override
  Future<bool> createHotel(Map<String, dynamic> hotelData) async {
    createdHotelData = Map<String, dynamic>.from(hotelData);
    return true;
  }

  @override
  Future<bool> updateHotel(int hotelId, Map<String, dynamic> hotelData) async {
    updatedHotelId = hotelId;
    updatedHotelData = Map<String, dynamic>.from(hotelData);
    return true;
  }

  @override
  Future<bool> deleteHotel(int hotelId) async {
    deletedHotelId = hotelId;
    return true;
  }
}
