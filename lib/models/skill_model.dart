class Skill {
  final String id;
  final String name;

  Skill({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  factory Skill.fromMap(String id, Map<String, dynamic> map) {
    return Skill(
      id: id,
      name: map['name'] ?? '',
    );
  }
}