// const String tablePlaces = 'places';

class PlaceFields {
  static final List<String> values = [
    id, name, lat, lng
  ];

  static const String id = 'id';
  static const String name = 'name';
  static const String lat = 'lat';
  static const String lng = 'lng';
}

class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng
  });

  Place copy({
    String? id,
    String? name,
    double? lat,
    double? lng

  }) =>
      Place(
        id: id ?? this.id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng
      );

  static Place fromJson(Map<String, Object?> json) => Place(
    id: json[PlaceFields.id] as String,
    name: json[PlaceFields.name] as String,
    lat: json[PlaceFields.lat] as double,
    lng: json[PlaceFields.lng] as double
  );

  Map<String, Object?> toJson() => {
    PlaceFields.id: id,
    PlaceFields.name: name,
    PlaceFields.lat: lat,
    PlaceFields.lng: lng
  };
}