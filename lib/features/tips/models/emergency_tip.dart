enum TipKind { flood, flatTire, battery, brakes }

class EmergencyTip {
  const EmergencyTip({
    required this.title,
    required this.minutes,
    required this.level,
    required this.kind,
    required this.steps,
    required this.sourceLabel,
    required this.sourceUrl,
  });
  final String title;
  final int minutes;
  final String level;
  final TipKind kind;
  final List<String> steps;
  final String sourceLabel;
  final String sourceUrl;
}
