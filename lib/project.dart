class Project {
  final String id;
  final String name;
  final String description;
  final DateTime deadline;
  bool isSelected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    this.isSelected = false,
  });
}