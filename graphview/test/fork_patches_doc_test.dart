import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Tests for FORK_PATCHES.md — validates the document's structural integrity,
// patch count arithmetic, status marker validity, and file reference accuracy.

/// Returns the lines of [content] that fall within the section beginning with
/// the heading [sectionHeader] and ending before the next `##`-level heading.
List<String> extractSectionLines(String content, String sectionHeader) {
  final lines = content.split('\n');
  var inSection = false;
  final result = <String>[];

  for (final line in lines) {
    if (line.trim() == sectionHeader) {
      inSection = true;
      continue;
    }
    if (inSection && line.startsWith('## ')) {
      break;
    }
    if (inSection) {
      result.add(line);
    }
  }
  return result;
}

/// Counts the data rows in a Markdown table within [sectionLines].
///
/// A data row starts with `|` and is neither the header row (which contains
/// "Patch Name" or "Category") nor a separator row (which contains `---`).
int countPatchTableDataRows(List<String> sectionLines) {
  var count = 0;
  for (final line in sectionLines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('|') &&
        !trimmed.contains('---') &&
        !trimmed.contains('Patch Name') &&
        !trimmed.contains('Category')) {
      count++;
    }
  }
  return count;
}

/// Returns Markdown table data rows, excluding header and separator rows.
List<String> extractTableDataRows(List<String> sectionLines) {
  return sectionLines
      .where((line) =>
          line.trim().startsWith('|') &&
          !line.contains('---') &&
          !line.contains('Patch Name') &&
          !line.contains('Category'))
      .toList();
}

List<String> extractTableCells(String row) {
  return row
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

String extractStatusToken(String statusCell, String line) {
  final match = RegExp(r'^\*\*(\w+)\*\*$').firstMatch(statusCell.trim());
  expect(match, isNotNull,
      reason:
          'Status cell must be exactly one bold token, found "$statusCell" in: $line');
  return match!.group(1)!;
}

/// Extracts all bold-marker tokens (e.g. `Required`, `Optional`) from table
/// cells of the form `**Token**` found in [sectionLines].
Set<String> extractStatusMarkers(List<String> sectionLines) {
  final markers = <String>{};
  for (final line in sectionLines) {
    // Only look at table data rows in the Status column (3rd column).
    // We detect table rows that start with '|' and are not separators/headers.
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') ||
        trimmed.contains('---') ||
        trimmed.contains('Patch Name')) {
      continue;
    }
    final cols = trimmed.split('|');
    // cols[0] is empty (before first |), cols[3] is the Status column.
    if (cols.length >= 5) {
      markers.add(extractStatusToken(cols[3], line));
    }
  }
  return markers;
}

class AppendixFilePaths {
  final List<String> sourceFiles;
  final List<String> testFiles;

  AppendixFilePaths({
    required this.sourceFiles,
    required this.testFiles,
  });
}

/// Returns the second data cell from a Quick Reference table row.
int extractQuickReferenceCount(String row) {
  final cells = row
      .split('|')
      .map((cell) => cell.trim().replaceAll('*', ''))
      .where((cell) => cell.isNotEmpty)
      .toList();
  expect(cells.length, greaterThanOrEqualTo(2),
      reason: 'Quick Reference row must have at least two cells: $row');
  return int.parse(cells[1]);
}

/// Extracts code-formatted `lib/...` and `test/...` paths from the File
/// Reference Appendix.
AppendixFilePaths extractAppendixFilePaths(String content) {
  final appendixLines =
      extractSectionLines(content, '## File Reference Appendix');
  final pathPattern = RegExp(r'`((?:lib|test)/[^`]+)`');
  final sourceFiles = <String>{};
  final testFiles = <String>{};

  for (final line in extractTableDataRows(appendixLines)) {
    for (final match in pathPattern.allMatches(line)) {
      final path = match.group(1)!;
      if (path.startsWith('lib/')) {
        sourceFiles.add(path);
      } else if (path.startsWith('test/')) {
        testFiles.add(path);
      }
    }
  }

  return AppendixFilePaths(
    sourceFiles: sourceFiles.toList()..sort(),
    testFiles: testFiles.toList()..sort(),
  );
}

void main() {
  late String content;
  late List<String> lines;

  setUpAll(() {
    final file = File('FORK_PATCHES.md');
    expect(file.existsSync(), isTrue,
        reason: 'FORK_PATCHES.md must exist at the package root');
    content = file.readAsStringSync();
    lines = content.split('\n');
  });

  group('FORK_PATCHES.md — document existence and basic structure', () {
    test('file is non-empty', () {
      expect(content.trim(), isNotEmpty);
    });

    test('document title is present', () {
      expect(content, contains('# Fork Patches'));
    });

    test('all six category section headers are present', () {
      expect(content, contains('## Edge Rendering Patches'));
      expect(content, contains('## Performance Patches'));
      expect(content, contains('## Interaction Patches'));
      expect(content, contains('## Animation Patches'));
      expect(content, contains('## API Patches'));
      expect(content, contains('## Algorithm Patches'));
    });

    test('Quick Reference section is present', () {
      expect(content, contains('## Quick Reference'));
    });

    test('File Reference Appendix section is present', () {
      expect(content, contains('## File Reference Appendix'));
    });

    test('Migration Cross-References section is present', () {
      expect(content, contains('## Migration Cross-References'));
    });
  });

  group('FORK_PATCHES.md — status marker definitions', () {
    test('Required status is defined in the preamble', () {
      expect(content, contains('**Required**'));
    });

    test('Optional status is defined in the preamble', () {
      expect(content, contains('**Optional**'));
    });

    test('Experimental status is defined in the preamble', () {
      expect(content, contains('**Experimental**'));
    });

    test('all status markers in patch tables are from the defined set', () {
      final validStatuses = {'Required', 'Optional', 'Experimental'};
      final patchSections = [
        '## Edge Rendering Patches',
        '## Performance Patches',
        '## Interaction Patches',
        '## Animation Patches',
        '## API Patches',
        '## Algorithm Patches',
      ];

      for (final section in patchSections) {
        final sectionLines = extractSectionLines(content, section);
        final markers = extractStatusMarkers(sectionLines);
        for (final marker in markers) {
          expect(validStatuses, contains(marker),
              reason:
                  'Section "$section" has unknown status marker "**$marker**"');
        }
      }
    });
  });

  group('FORK_PATCHES.md — Quick Reference patch counts', () {
    late List<String> quickRefLines;

    setUpAll(() {
      quickRefLines = extractSectionLines(content, '## Quick Reference');
    });

    test('Quick Reference table lists Edge rendering as 5 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('Edge rendering') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(5),
          reason: 'Edge rendering row should report 5 patches');
    });

    test('Quick Reference table lists Performance as 4 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('Performance') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(4),
          reason: 'Performance row should report 4 patches');
    });

    test('Quick Reference table lists Interaction as 3 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('Interaction') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(3),
          reason: 'Interaction row should report 3 patches');
    });

    test('Quick Reference table lists Animation as 3 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('Animation') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(3), reason: 'Animation row should report 3 patches');
    });

    test('Quick Reference table lists API as 5 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('| API |') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(5), reason: 'API row should report 5 patches');
    });

    test('Quick Reference table lists Algorithms as 5 patches', () {
      final row = quickRefLines.firstWhere(
        (l) => l.contains('Algorithms') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(row);
      expect(count, equals(5),
          reason: 'Algorithms row should report 5 patches');
    });

    test('Quick Reference total is 25', () {
      final totalRow = quickRefLines.firstWhere(
        (l) => l.contains('Total') && !l.contains('---'),
        orElse: () => '',
      );
      final count = extractQuickReferenceCount(totalRow);
      expect(count, equals(25), reason: 'Total row should report 25 patches');
    });

    test('individual category counts sum to 25', () {
      const edgeRendering = 5;
      const performance = 4;
      const interaction = 3;
      const animation = 3;
      const api = 5;
      const algorithms = 5;
      const expectedTotal = 25;

      expect(
        edgeRendering +
            performance +
            interaction +
            animation +
            api +
            algorithms,
        equals(expectedTotal),
      );
    });
  });

  group('FORK_PATCHES.md — actual section row counts match Quick Reference',
      () {
    test('Edge Rendering section has exactly 5 patch rows', () {
      final sectionLines =
          extractSectionLines(content, '## Edge Rendering Patches');
      expect(countPatchTableDataRows(sectionLines), equals(5),
          reason:
              'Edge Rendering section must contain exactly 5 patch entries');
    });

    test('Performance section has exactly 4 patch rows', () {
      final sectionLines =
          extractSectionLines(content, '## Performance Patches');
      expect(countPatchTableDataRows(sectionLines), equals(4),
          reason: 'Performance section must contain exactly 4 patch entries');
    });

    test('Interaction section has exactly 3 patch rows', () {
      final sectionLines =
          extractSectionLines(content, '## Interaction Patches');
      expect(countPatchTableDataRows(sectionLines), equals(3),
          reason: 'Interaction section must contain exactly 3 patch entries');
    });

    test('Animation section has exactly 3 patch rows', () {
      final sectionLines = extractSectionLines(content, '## Animation Patches');
      expect(countPatchTableDataRows(sectionLines), equals(3),
          reason: 'Animation section must contain exactly 3 patch entries');
    });

    test('API section has exactly 5 patch rows', () {
      final sectionLines = extractSectionLines(content, '## API Patches');
      expect(countPatchTableDataRows(sectionLines), equals(5),
          reason: 'API section must contain exactly 5 patch entries');
    });

    test('Algorithm section has exactly 5 patch rows', () {
      final sectionLines = extractSectionLines(content, '## Algorithm Patches');
      expect(countPatchTableDataRows(sectionLines), equals(5),
          reason: 'Algorithm section must contain exactly 5 patch entries');
    });

    test('total patch rows across all sections equals 25', () {
      final sections = [
        '## Edge Rendering Patches',
        '## Performance Patches',
        '## Interaction Patches',
        '## Animation Patches',
        '## API Patches',
        '## Algorithm Patches',
      ];
      final total = sections.fold<int>(
        0,
        (sum, s) =>
            sum + countPatchTableDataRows(extractSectionLines(content, s)),
      );
      expect(total, equals(25));
    });

    test('no patch section has zero rows (no empty sections)', () {
      final sections = {
        '## Edge Rendering Patches': 1,
        '## Performance Patches': 1,
        '## Interaction Patches': 1,
        '## Animation Patches': 1,
        '## API Patches': 1,
        '## Algorithm Patches': 1,
      };
      for (final entry in sections.entries) {
        final rows =
            countPatchTableDataRows(extractSectionLines(content, entry.key));
        expect(rows, greaterThanOrEqualTo(entry.value),
            reason: 'Section "${entry.key}" must not be empty');
      }
    });
  });

  group('FORK_PATCHES.md — migration cross-references', () {
    test('MIGRATION.md is referenced in the document', () {
      expect(content, contains('MIGRATION.md'));
    });

    test('MIGRATION.md file actually exists', () {
      expect(File('MIGRATION.md').existsSync(), isTrue,
          reason: 'MIGRATION.md must exist since FORK_PATCHES.md links to it');
    });

    test('Node.Id() migration item is documented', () {
      final migSection =
          extractSectionLines(content, '## Migration Cross-References');
      final joined = migSection.join('\n');
      expect(joined, contains('Node.Id()'));
    });

    test('GraphView.builder() migration item is documented', () {
      final migSection =
          extractSectionLines(content, '## Migration Cross-References');
      final joined = migSection.join('\n');
      expect(joined, contains('GraphView.builder()'));
    });

    test('Graph.getNodeUsingId() migration item is documented', () {
      final migSection =
          extractSectionLines(content, '## Migration Cross-References');
      final joined = migSection.join('\n');
      expect(joined, contains('Graph.getNodeUsingId()'));
    });
  });

  group('FORK_PATCHES.md — source file references exist on disk', () {
    final sourceFiles =
        extractAppendixFilePaths(File('FORK_PATCHES.md').readAsStringSync())
            .sourceFiles;

    test('source file references are parsed from appendix', () {
      expect(sourceFiles, isNotEmpty);
    });

    for (final path in sourceFiles) {
      test('$path exists', () {
        expect(File(path).existsSync(), isTrue,
            reason: 'Source file "$path" referenced in FORK_PATCHES.md '
                'must exist on disk');
      });
    }
  });

  group('FORK_PATCHES.md — test file references exist on disk', () {
    final testFiles =
        extractAppendixFilePaths(File('FORK_PATCHES.md').readAsStringSync())
            .testFiles;

    test('test file references are parsed from appendix', () {
      expect(testFiles, isNotEmpty);
    });

    for (final path in testFiles) {
      test('$path exists', () {
        expect(File(path).existsSync(), isTrue,
            reason: 'Test file "$path" listed in FORK_PATCHES.md '
                'File Reference Appendix must exist on disk');
      });
    }
  });

  group('FORK_PATCHES.md — File Reference Appendix completeness', () {
    late List<String> appendixLines;
    late List<String> dataRows;
    late List<String> categories;

    setUpAll(() {
      appendixLines =
          extractSectionLines(content, '## File Reference Appendix');
      dataRows = extractTableDataRows(appendixLines);
      categories = dataRows.map((row) => extractTableCells(row).first).toList();
    });

    test('appendix has a row for Edge rendering category', () {
      expect(categories, contains('Edge rendering'));
    });

    test('appendix has a row for Performance category', () {
      expect(categories, contains('Performance'));
    });

    test('appendix has a row for Interaction category', () {
      expect(categories, contains('Interaction'));
    });

    test('appendix has a row for Animation category', () {
      expect(categories, contains('Animation'));
    });

    test('appendix has a row for API category', () {
      expect(categories, contains('API'));
    });

    test('appendix has a row for Algorithms category', () {
      expect(categories, contains('Algorithms'));
    });

    test('appendix contains exactly 6 data rows (one per category)', () {
      expect(
        categories,
        equals([
          'Edge rendering',
          'Performance',
          'Interaction',
          'Animation',
          'API',
          'Algorithms',
        ]),
      );
    });
  });

  group('FORK_PATCHES.md — regression and boundary checks', () {
    test('all patch counts in Quick Reference are positive integers', () {
      final countPattern = RegExp(r'\|\s*(\d+)\s*\|');
      final quickRefLines = extractSectionLines(content, '## Quick Reference');
      for (final line in quickRefLines) {
        if (line.contains('---') || line.contains('Category')) continue;
        final matches = countPattern.allMatches(line);
        for (final match in matches) {
          final count = int.parse(match.group(1)!);
          expect(count, greaterThan(0),
              reason:
                  'All patch counts must be positive; found $count in: $line');
        }
      }
    });

    test('each patch section header appears exactly once', () {
      final headers = [
        '## Edge Rendering Patches',
        '## Performance Patches',
        '## Interaction Patches',
        '## Animation Patches',
        '## API Patches',
        '## Algorithm Patches',
      ];
      for (final header in headers) {
        final occurrences = lines.where((l) => l.trim() == header).length;
        expect(occurrences, equals(1),
            reason: 'Header "$header" must appear exactly once');
      }
    });

    test('document contains no patch rows with empty status cells', () {
      final patchSectionHeaders = [
        '## Edge Rendering Patches',
        '## Performance Patches',
        '## Interaction Patches',
        '## Animation Patches',
        '## API Patches',
        '## Algorithm Patches',
      ];

      for (final header in patchSectionHeaders) {
        final sectionLines = extractSectionLines(content, header);
        for (final line in extractTableDataRows(sectionLines)) {
          final trimmed = line.trim();
          final cols = trimmed.split('|');
          if (cols.length >= 5) {
            final statusToken = extractStatusToken(cols[3], line);
            expect(statusToken, isNotEmpty,
                reason:
                    'Status cell must not be empty in section "$header": $line');
          }
        }
      }
    });
  });
}
