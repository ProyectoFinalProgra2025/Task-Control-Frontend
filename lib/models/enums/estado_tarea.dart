enum EstadoTarea {
  pendiente(0, 'Pendiente'),
  asignada(1, 'Asignada'),
  aceptada(2, 'Aceptada'),
  finalizada(3, 'Finalizada'),
  cancelada(4, 'Cancelada');

  final int value;
  final String label;

  const EstadoTarea(this.value, this.label);

  static EstadoTarea fromValue(int value) {
    return EstadoTarea.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoTarea.pendiente,
    );
  }

  static EstadoTarea fromString(String str) {
    return EstadoTarea.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => EstadoTarea.pendiente,
    );
  }
}
