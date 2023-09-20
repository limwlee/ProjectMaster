class Project {
  final String id;
  final String name;
  final String description;
  bool isSelected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.isSelected = false,
  });
}