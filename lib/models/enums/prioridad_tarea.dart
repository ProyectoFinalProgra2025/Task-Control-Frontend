enum PrioridadTarea {
  low(0, 'Low'),
  medium(1, 'Medium'),
  high(2, 'High');

  final int value;
  final String label;

  const PrioridadTarea(this.value, this.label);

  static PrioridadTarea fromValue(int value) {
    return PrioridadTarea.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PrioridadTarea.medium,
    );
  }

  static PrioridadTarea fromString(String str) {
    return PrioridadTarea.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => PrioridadTarea.medium,
    );
  }
}
