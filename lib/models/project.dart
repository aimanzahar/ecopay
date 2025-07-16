class Project {
  final int? id;
  final String name;
  final String description;
  final double costPerUnit;
  final String unitLabel;

  Project({
    this.id,
    required this.name,
    required this.description,
    required this.costPerUnit,
    required this.unitLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost_per_unit': costPerUnit,
      'unit_label': unitLabel,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      costPerUnit: map['cost_per_unit'],
      unitLabel: map['unit_label'],
    );
  }
}