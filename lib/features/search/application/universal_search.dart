enum UniversalSearchResultType { inventory, contact, transaction, deal }

class UniversalSearchEntry {
  const UniversalSearchEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.searchText,
    this.subtitle,
  });

  final UniversalSearchResultType type;
  final String id;
  final String title;
  final String? subtitle;
  final String searchText;
}

final class UniversalSearch {
  const UniversalSearch._();

  static List<UniversalSearchEntry> filter(
    Iterable<UniversalSearchEntry> entries,
    String query,
  ) {
    final terms = _terms(query);

    if (terms.isEmpty) {
      return const [];
    }

    return List<UniversalSearchEntry>.unmodifiable(
      entries.where((entry) {
        final haystack = _searchableText(entry);
        return terms.every(haystack.contains);
      }),
    );
  }

  static Map<UniversalSearchResultType, List<UniversalSearchEntry>> group(
    Iterable<UniversalSearchEntry> entries,
  ) {
    final grouped = <UniversalSearchResultType, List<UniversalSearchEntry>>{};

    for (final entry in entries) {
      grouped.putIfAbsent(entry.type, () => []).add(entry);
    }

    return Map<
      UniversalSearchResultType,
      List<UniversalSearchEntry>
    >.unmodifiable({
      for (final mapEntry in grouped.entries)
        mapEntry.key: List<UniversalSearchEntry>.unmodifiable(mapEntry.value),
    });
  }

  static List<String> _terms(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
  }

  static String _searchableText(UniversalSearchEntry entry) {
    return [
      entry.id,
      entry.title,
      entry.subtitle,
      entry.searchText,
      entry.type.name,
    ].whereType<String>().join(' ').toLowerCase();
  }
}
