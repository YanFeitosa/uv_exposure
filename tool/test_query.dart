/// SunSense — Test Query
///
/// Query test files by tag or list untagged tests.
///
/// Usage:
///   dart run tool/test_query.dart tags              # show all tags
///   dart run tool/test_query.dart list --tag edge    # files with @Tags(['edge'])
///   dart run tool/test_query.dart list --untagged    # files without @Tags
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final projectRoot = Directory.current.path;
  final allTestFiles = [
    ..._findTestFiles('$projectRoot/test/unit'),
    ..._findTestFiles('$projectRoot/test/widget'),
    ..._findTestFiles('$projectRoot/test/integration'),
  ];

  switch (args[0]) {
    case 'tags':
      _showTags(allTestFiles, projectRoot);
    case 'list':
      if (args.length >= 3 && args[1] == '--tag') {
        _listByTag(allTestFiles, args[2], projectRoot);
      } else if (args.length >= 2 && args[1] == '--untagged') {
        _listUntagged(allTestFiles, projectRoot);
      } else {
        _printUsage();
        exit(1);
      }
    default:
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('Usage:');
  print('  dart run tool/test_query.dart tags              # show all tags');
  print('  dart run tool/test_query.dart list --tag edge    # files with tag');
  print('  dart run tool/test_query.dart list --untagged    # files without tags');
}

void _showTags(List<String> files, String root) {
  final tagMap = <String, List<String>>{};
  final tagPattern = RegExp(r'''@Tags\s*\(\s*\[(.*?)\]''');

  for (final path in files) {
    final content = File(path).readAsStringSync();
    final match = tagPattern.firstMatch(content);
    if (match == null) continue;

    final tags = match
        .group(1)!
        .split(',')
        .map((t) => t.trim().replaceAll("'", '').replaceAll('"', ''))
        .where((t) => t.isNotEmpty);

    for (final tag in tags) {
      tagMap.putIfAbsent(tag, () => []).add(_relative(path, root));
    }
  }

  if (tagMap.isEmpty) {
    print('No tagged test files found.');
    return;
  }

  final sorted = tagMap.keys.toList()..sort();
  for (final tag in sorted) {
    final tagFiles = tagMap[tag]!;
    print('@$tag (${tagFiles.length} files):');
    for (final f in tagFiles) {
      print('  $f');
    }
  }
}

void _listByTag(List<String> files, String tag, String root) {
  final tagPattern = RegExp(r'''@Tags\s*\(\s*\[(.*?)\]''');
  final matches = <String>[];

  for (final path in files) {
    final content = File(path).readAsStringSync();
    final match = tagPattern.firstMatch(content);
    if (match == null) continue;

    final tags = match
        .group(1)!
        .split(',')
        .map((t) => t.trim().replaceAll("'", '').replaceAll('"', ''))
        .where((t) => t.isNotEmpty);

    if (tags.contains(tag)) {
      matches.add(_relative(path, root));
    }
  }

  if (matches.isEmpty) {
    print('No test files found with tag: $tag');
    return;
  }

  print('Files with @$tag (${matches.length}):');
  for (final f in matches) {
    print('  $f');
  }
}

void _listUntagged(List<String> files, String root) {
  final untagged = <String>[];

  for (final path in files) {
    final content = File(path).readAsStringSync();
    if (!content.contains('@Tags(')) {
      untagged.add(_relative(path, root));
    }
  }

  print('Untagged test files (${untagged.length}):');
  for (final f in untagged) {
    print('  $f');
  }
}

String _relative(String path, String root) {
  return path
      .replaceAll('\\', '/')
      .replaceFirst('${root.replaceAll('\\', '/')}/', '');
}

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
