class LocationData {
  final String address;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? postalCode;
  final String? label;
  final String? context;

  LocationData({
    required this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.postalCode,
    this.label,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'postal_code': postalCode,
    'label': label,
    'context': context,
  };

  Map<String, dynamic> toMap() => toJson();

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      city: json['city']?.toString(),
      postalCode: json['postal_code']?.toString(),
      label: json['label']?.toString(),
      context: json['context']?.toString(),
    );
  }

  factory LocationData.fromMap(Map<String, dynamic> map) =>
      LocationData.fromJson(map);

  LocationData copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? postalCode,
    String? label,
    String? context,
  }) {
    return LocationData(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      label: label ?? this.label,
      context: context ?? this.context,
    );
  }

  @override
  String toString() =>
      'LocationData(address: $address, lat: $latitude, lng: $longitude, city: $city)';
}

class LocationSuggestion {
  final String label;
  final String? city;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? context;
  final String? fullAddress;

  LocationSuggestion({
    required this.label,
    this.city,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.context,
    this.fullAddress,
  });

  LocationData toLocationData() {
    return LocationData(
      address: fullAddress ?? label,
      latitude: latitude,
      longitude: longitude,
      city: city,
      postalCode: postalCode,
      label: label,
      context: context,
    );
  }
}
