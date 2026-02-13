class TallyStats {
  final int totalCount;
  final Map<String, int> byEvent;
  final Map<String, int> byPerson;
  final Map<String, Map<String, int>> byNameByPerson;

  const TallyStats({
    required this.totalCount,
    required this.byEvent,
    this.byPerson = const {},
    this.byNameByPerson = const {},
  });
}
