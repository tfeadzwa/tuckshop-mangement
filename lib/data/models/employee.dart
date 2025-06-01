// Employee data model
class Employee {
  final int? id; // Nullable for new employees
  final String name;
  final String role;
  final String duty;
  final int performanceScore;

  Employee({
    this.id,
    required this.name,
    required this.role,
    required this.duty,
    this.performanceScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'duty': duty,
      'performanceScore': performanceScore,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      duty: map['duty'],
      performanceScore: map['performanceScore'] ?? 0,
    );
  }
}
