class CustomEvent {
  final int id;
  final String name;
  final bool isLunar;
  final int? year;
  final int month;
  final int day;
  final bool isLeap;

  const CustomEvent({
    required this.id,
    required this.name,
    this.isLunar = false,
    this.year,
    required this.month,
    required this.day,
    this.isLeap = false,
  });
}
