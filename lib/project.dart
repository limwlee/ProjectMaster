class Project {
  final String id;
  final String name;
  final String description;
  final DateTime? dueDate;
  bool isSelected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.dueDate,
    this.isSelected = false,
  });
}