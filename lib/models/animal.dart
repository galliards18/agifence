class Animal {
  final String id;
  final String name;
  final String type;
  final String breed;
  final String deviceId;
  final String status;
  final String lastSeen;
  final DateTime createdAt;
  final String? age;
  final String? weight;
  final String? gender;

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.deviceId,
    required this.status,
    required this.lastSeen,
    required this.createdAt,
    this.age,
    this.weight,
    this.gender,
  });

  Animal copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    String? deviceId,
    String? status,
    String? lastSeen,
    DateTime? createdAt,
    String? age,
    String? weight,
    String? gender,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'deviceId': deviceId,
      'status': status,
      'lastSeen': lastSeen,
      'createdAt': createdAt.toIso8601String(),
      'age': age,
      'weight': weight,
      'gender': gender,
    };
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    try {
      return Animal(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        breed: json['breed'] ?? '',
        deviceId: json['deviceId'] ?? '',
        status: json['status'] ?? 'Unknown',
        lastSeen: json['lastSeen'] ?? 'Unknown',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        age: json['age'],
        weight: json['weight'],
        gender: json['gender'],
      );
    } catch (e) {
      print('Error parsing Animal from JSON: $e');
      // Return a default animal if parsing fails
      return Animal(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] ?? 'Unknown Animal',
        type: json['type'] ?? 'Unknown',
        breed: json['breed'] ?? 'Unknown',
        deviceId: json['deviceId'] ?? 'Unknown',
        status: 'Unknown',
        lastSeen: 'Unknown',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'Animal(id: $id, name: $name, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Animal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
