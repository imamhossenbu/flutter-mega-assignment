class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String district;
  final String detailedAddress;
  final bool isDhaka;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.district,
    required this.detailedAddress,
    required this.isDhaka,
    this.isDefault = false,
  });

  String get fullAddress => '$detailedAddress, $district';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'district': district,
        'detailedAddress': detailedAddress,
        'isDhaka': isDhaka,
        'isDefault': isDefault,
      };

  factory AddressModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final dist = map['district'] as String? ?? '';
    final isDhakaVal = map['isDhaka'] as bool? ??
        dist.trim().toLowerCase().contains('dhaka');

    return AddressModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      district: dist,
      detailedAddress: map['detailedAddress'] as String? ?? '',
      isDhaka: isDhakaVal,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  AddressModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? district,
    String? detailedAddress,
    bool? isDhaka,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      isDhaka: isDhaka ?? this.isDhaka,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
