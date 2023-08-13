import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class CleanCommand extends Command<int> {
  CleanCommand({
    required Logger logger,
  }) : _logger = logger;
  @override
  String get description => 'Clean the sky project.';

  @override
  String get name => 'clean';

  final Logger _logger;

  @override
  Future<int> run() async {
    final progress = _logger.progress('Cleaning the project');
    try {
      await cleanProject();
      progress.complete('Project cleaned');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to clean the project');
      _logger.err(e.toString());
      exit(ExitCode.ioError.code);
    }
  }

  Future<void> cleanProject() async {
    final progress = _logger.progress('Cleaning Flutter project...');
    final cleanFiles = <String>[
      'ios/Pods',
      'ios/Podfile.lock',
      'ios/.symlinks',
      'ios/build',
      'ios/Runner/GeneratedPluginRegistrant.m',
      'ios/Runner/GeneratedPluginRegistrant.h',
      'pubspec.lock',
    ];
    try {
      _logger.detail('Executing `flutter clean`...');
      final flutterClean = await Process.start(
        'flutter',
        ['clean'],
        workingDirectory: Directory.current.path,
      );
      flutterClean.stdout.listen((event) => _logger.detail(utf8.decode(event)));
      flutterClean.stderr.transform(utf8.decoder).listen(_logger.err);
      progress.update('Cleaning iOS project...');
      for (var i = 0; i < cleanFiles.length; i++) {
        final file = i == 4 || i == 5 || i == 6
            ? File(p.join(Directory.current.path, cleanFiles[i]))
            : Directory(p.join(Directory.current.path, cleanFiles[i]));
        if (file.existsSync()) {
          file.deleteSync(recursive: true);
        }
      }
      final podCacheClean = await Process.start(
        'pod',
        ['cache', 'clean', '--all'],
        workingDirectory: p.join(Directory.current.path, 'ios'),
      );
      podCacheClean.stdout
          .listen((event) => _logger.detail(utf8.decode(event)));
      podCacheClean.stderr.transform(utf8.decoder).listen(_logger.err);
      final podClean = await Process.start(
        'pod',
        ['deintegrate'],
        workingDirectory: p.join(Directory.current.path, 'ios'),
      );
      podClean.stdout.listen((event) => _logger.detail(utf8.decode(event)));
      podClean.stderr.transform(utf8.decoder).listen(_logger.err);
      progress.update('Cleaning Android project...');
      _logger.detail('Checking for gradlew file');
      final gradlewFile =
          File(p.join(Directory.current.path, 'android', 'gradlew'));
      if (!gradlewFile.existsSync()) {
        _logger
          ..detail('gradlew file not found')
          ..detail(
            '''Creating a new gradlew file in ${p.join(Directory.current.path, 'android')}''',
          );
        await gradlewFile.create(recursive: true);
        final url = Uri.parse(
          'https://cdn.sourceb.in/bins/uvyIOoOWHl/0',
        );
        _logger.detail('Downloading gradlew script...');

        final req = http.Request('GET', url);

        final res = await req.send();
        final resBody = await res.stream.bytesToString();

        if (res.statusCode >= 200 && res.statusCode < 300) {
          _logger.detail('Writing gradlew script to ${gradlewFile.path}...');
          await gradlewFile.writeAsString(resBody);
        } else {
          progress.fail('Failed to write required android files');
        }
      }
      _logger.detail('Granting permissions to gradlew file');
      await Process.start(
        'chmod',
        ['+x', 'gradlew'],
        workingDirectory: p.join(Directory.current.path, 'android'),
      );
      _logger.detail('Running `gradlew clean`...');
      final gradleClean = await Process.start(
        './gradlew',
        ['clean'],
        workingDirectory: p.join(Directory.current.path, 'android'),
      );
      gradleClean.stdout.listen((event) => _logger.detail(utf8.decode(event)));
      gradleClean.stderr.listen((err) => _logger.detail(utf8.decode(err)));
      progress.complete('Successfully cleaned project');
    } catch (e, s) {
      progress.fail('Failed to clean project');
      _logger
        ..detail('$e')
        ..detail('StackTraces:')
        ..detail('$s');
      exit(ExitCode.software.code);
    }
  }
}
