/// SunSense — Test Report
///
/// Generates a simple, defensible test report for TCC documentation.
/// Uses: file scanning for counts/tags, lcov.info parsing for coverage.
///
/// Usage:
///   flutter test --coverage           # generate coverage first
///   dart run tool/test_report.dart     # then generate report
import 'dart:io';

void main() async {
  final projectRoot = Directory.current.path;

  print('');
  print('╔══════════════════════════════════════════════╗');
  print('║       SunSense — Test Report                 ║');
  print('╚══════════════════════════════════════════════╝');
  print('');

  // 1. Scan test files
  final unitFiles = _findTestFiles('$projectRoot/test/unit');
  final widgetFiles = _findTestFiles('$projectRoot/test/widget');
  final integrationFiles = _findTestFiles('$projectRoot/test/integration');
  final allTestFiles = [...unitFiles, ...widgetFiles, ...integrationFiles];

  // 2. Count tests per file
  final unitCount = _countTests(unitFiles);
  final widgetCount = _countTests(widgetFiles);
  final integrationCount = _countTests(integrationFiles);
  final totalCount = unitCount + widgetCount + integrationCount;

  // 3. Scan tags
  final tagMap = _scanTags(allTestFiles);

  // 4. Parse coverage
  final lcovFile = File('$projectRoot/coverage/lcov.info');
  final coverage = lcovFile.existsSync() ? _parseLcov(lcovFile) : null;

  // 5. Inventory lib/ files
  final libFiles = _findDartFiles('$projectRoot/lib');
  final excludedPatterns = [
    'main.dart',
    '.g.dart',
    '.freezed.dart',
  ];

  final eligibleLibFiles = libFiles.where((f) {
    final relative = f.replaceAll('\\', '/');
    return !excludedPatterns.any((p) => relative.endsWith(p));
  }).toList();

  // ── TEST SUMMARY ──
  print('── Test summary ─────────────────────────────');
  print('  Unit tests:        ${unitCount.toString().padLeft(4)} (${unitFiles.length} files)');
  print('  Widget tests:      ${widgetCount.toString().padLeft(4)} (${widgetFiles.length} files)');
  print('  Integration tests: ${integrationCount.toString().padLeft(4)} (${integrationFiles.length} files)');
  print('  ────────────────────────');
  print('  Total:             ${totalCount.toString().padLeft(4)} (${allTestFiles.length} files)');
  print('');

  // ── TAG SUMMARY ──
  print('── Tag summary ──────────────────────────────');
  if (tagMap.isEmpty) {
    print('  (no tagged tests found)');
  } else {
    final sortedTags = tagMap.keys.toList()..sort();
    for (final tag in sortedTags) {
      final info = tagMap[tag]!;
      print('  @$tag'.padRight(20) +
          '${info.testCount.toString().padLeft(3)} tests (${info.fileCount} files)');
    }
  }
  print('');

  // ── COVERAGE SUMMARY ──
  print('── Coverage summary ─────────────────────────');
  if (coverage == null) {
    print('  lcov.info not found. Run: flutter test --coverage');
  } else {
    final globalHit = coverage.values.fold(0, (s, c) => s + c.linesHit);
    final globalTotal = coverage.values.fold(0, (s, c) => s + c.linesTotal);
    final globalPct =
        globalTotal > 0 ? (globalHit / globalTotal * 100) : 0.0;

    print('  Global: ${globalPct.toStringAsFixed(1)}% ($globalHit/$globalTotal lines)');
    print('');
    print('  Per file:');

    final sortedFiles = coverage.keys.toList()..sort();
    for (final file in sortedFiles) {
      final c = coverage[file]!;
      if (c.linesTotal == 0) continue;
      final pct = c.linesHit / c.linesTotal * 100;
      final icon = pct >= 80 ? '✅' : (pct >= 50 ? '⚠️' : '❌');
      final name = file.padRight(48);
      print('    $icon $name ${pct.toStringAsFixed(1).padLeft(5)}% (${c.linesHit}/${c.linesTotal})');
    }
  }
  print('');

  // ── DIAGNOSTICS ──
  print('── Diagnostics ──────────────────────────────');

  // Files without coverage
  final coveredFiles =
      coverage?.keys.map((f) => f.replaceAll('\\', '/')).toSet() ?? {};

  String _toLibRelative(String path) {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/lib/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  final uncoveredEligible = eligibleLibFiles.where((f) {
    final relative = _toLibRelative(f);
    return !coveredFiles.contains(relative);
  }).toList();

  if (uncoveredEligible.isNotEmpty) {
    print('  lib/ files not in coverage data:');
    for (final f in uncoveredEligible) {
      print('    - ${_toLibRelative(f)}');
    }
  } else {
    print('  All eligible lib/ files appear in coverage data.');
  }
  print('');

  // Excluded files
  final excludedFiles = libFiles.where((f) {
    final relative = f.replaceAll('\\', '/');
    return excludedPatterns.any((p) => relative.endsWith(p));
  }).toList();

  if (excludedFiles.isNotEmpty) {
    print('  Excluded from analysis:');
    for (final f in excludedFiles) {
      print('    - ${_toLibRelative(f)}');
    }
  }
  print('');

  // Test files without tags
  final untaggedFiles = allTestFiles.where((f) {
    final content = File(f).readAsStringSync();
    return !content.contains('@Tags(');
  }).toList();

  print('  Test files without tags: ${untaggedFiles.length}/${allTestFiles.length}');
  print('    (normal — tags are only for edge/failure scenarios)');
  print('');

  // Legend
  print('── Legend ────────────────────────────────────');
  print('  Legenda: ✅ ≥80%  ⚠️ ≥50%  ❌ <50%');
  print('');
}

// ─── Helpers ───────────────────────────────────────

List<String> _findTestFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'))
      .map((f) => f.path)
      .toList()
    ..sort();
}

List<String> _findDartFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList()
    ..sort();
}

int _countTests(List<String> files) {
  int count = 0;
  final testPattern = RegExp(r'''\b(test|testWidgets)\s*\(''');
  for (final path in files) {
    final content = File(path).readAsStringSync();
    count += testPattern.allMatches(content).length;
  }
  return count;
}

Map<String, _TagInfo> _scanTags(List<String> files) {
  final tagPattern = RegExp(r'''@Tags\s*\(\s*\[(.*?)\]''');
  final result = <String, _TagInfo>{};

  for (final path in files) {
    final content = File(path).readAsStringSync();
    final match = tagPattern.firstMatch(content);
    if (match == null) continue;

    final tagsStr = match.group(1)!;
    final tags = tagsStr
        .split(',')
        .map((t) => t.trim().replaceAll("'", '').replaceAll('"', ''))
        .where((t) => t.isNotEmpty)
        .toList();

    final testCount = _countTests([path]);

    for (final tag in tags) {
      result.putIfAbsent(tag, () => _TagInfo());
      result[tag]!.fileCount++;
      result[tag]!.testCount += testCount;
    }
  }

  return result;
}

class _TagInfo {
  int fileCount = 0;
  int testCount = 0;
}

class _CoverageInfo {
  int linesHit = 0;
  int linesTotal = 0;
}

Map<String, _CoverageInfo>? _parseLcov(File lcovFile) {
  final result = <String, _CoverageInfo>{};
  String? currentFile;

  for (final line in lcovFile.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentFile = line
          .substring(3)
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'.*/lib/'), '');
    } else if (line.startsWith('LH:') && currentFile != null) {
      result.putIfAbsent(currentFile, () => _CoverageInfo());
      result[currentFile]!.linesHit = int.parse(line.substring(3));
    } else if (line.startsWith('LF:') && currentFile != null) {
      result.putIfAbsent(currentFile, () => _CoverageInfo());
      result[currentFile]!.linesTotal = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      currentFile = null;
    }
  }

  return result;
}
