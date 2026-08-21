import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/search/application/universal_search.dart';

void main() {
  const entries = [
    UniversalSearchEntry(
      type: UniversalSearchResultType.inventory,
      id: 'BAT-2608-0001',
      title: 'Combat Spec H1',
      subtitle: 'BBCOR bat',
      searchText: 'Combat Spec H1 BBCOR like new BAT-2608-0001',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.contact,
      id: 'contact-1',
      title: 'John Smith',
      subtitle: 'john@example.com',
      searchText: 'John Smith john@example.com 8175551212',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.transaction,
      id: 'sale-1',
      title: 'Sale BAT-2608-0001',
      subtitle: 'John Smith',
      searchText: 'sale BAT-2608-0001 John Smith cash',
    ),
    UniversalSearchEntry(
      type: UniversalSearchResultType.deal,
      id: 'deal-1',
      title: 'Trade Deal',
      subtitle: 'John Smith',
      searchText: 'trade deal John Smith BAT-2608-0001',
    ),
  ];

  group('UniversalSearch', () {
    test('blank query returns no results', () {
      expect(UniversalSearch.filter(entries, ''), isEmpty);
      expect(UniversalSearch.filter(entries, '   '), isEmpty);
    });

    test('matches inventory number across record types', () {
      final results = UniversalSearch.filter(entries, 'BAT-2608-0001');

      expect(results, hasLength(3));
    });

    test('matches a contact name across related record types', () {
      final results = UniversalSearch.filter(entries, 'John Smith');

      expect(results, hasLength(3));
    });

    test('matching is case insensitive', () {
      final results = UniversalSearch.filter(entries, 'combat');

      expect(results, hasLength(1));
      expect(results.single.type, UniversalSearchResultType.inventory);
    });

    test('all query terms must match the same record', () {
      final results = UniversalSearch.filter(entries, 'Combat BBCOR');

      expect(results, hasLength(1));
      expect(results.single.id, 'BAT-2608-0001');
    });

    test('unrelated terms return no results', () {
      expect(UniversalSearch.filter(entries, 'Louisville Atlas'), isEmpty);
    });

    test('record type name participates in matching', () {
      final results = UniversalSearch.filter(entries, 'contact');

      expect(results, hasLength(1));
      expect(results.single.id, 'contact-1');
    });

    test('subtitle participates in matching', () {
      final results = UniversalSearch.filter(entries, 'john@example.com');

      expect(results, hasLength(1));
      expect(results.single.type, UniversalSearchResultType.contact);
    });

    test('group organizes results by record type', () {
      final grouped = UniversalSearch.group(
        UniversalSearch.filter(entries, 'John'),
      );

      expect(grouped[UniversalSearchResultType.contact], hasLength(1));
      expect(grouped[UniversalSearchResultType.transaction], hasLength(1));
      expect(grouped[UniversalSearchResultType.deal], hasLength(1));
      expect(grouped[UniversalSearchResultType.inventory], isNull);
    });

    test('group returns immutable lists', () {
      final grouped = UniversalSearch.group(entries);

      expect(
        () => grouped[UniversalSearchResultType.inventory]!.add(entries.first),
        throwsUnsupportedError,
      );
    });
  });
}
