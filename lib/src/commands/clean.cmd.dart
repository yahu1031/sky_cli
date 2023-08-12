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
      await cleanProject(progress);
      progress.complete('Project cleaned');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to clean the project');
      _logger.err(e.toString());
      exit(ExitCode.ioError.code);
    }
  }

  static Future<void> cleanProject(Progress progress) async {
    final cleanFiles = <String>[
      'ios/Pods',
      'ios/Podfile.lock',
      'ios/.symlinks',
      'ios/build',
      'ios/Runner/GeneratedPluginRegistrant.m',
      'ios/Runner/GeneratedPluginRegistrant.h',
      'pubspec.lock',
    ];
    progress.update('Cleaning Flutter project...');
    try {
      await Process.start(
        'flutter',
        ['clean'],
        workingDirectory: Directory.current.path,
      );
      progress.update('Cleaning iOS project...');
      for (var i = 0; i < cleanFiles.length; i++) {
        final file = i == 4 || i == 5 || i == 6
            ? File(p.join(Directory.current.path, cleanFiles[i]))
            : Directory(p.join(Directory.current.path, cleanFiles[i]));
        if (file.existsSync()) {
          file.deleteSync(recursive: true);
        }
      }
      progress.update('Cleaning Android project...');
      final gradlewFile =
          File(p.join(Directory.current.path, 'android', 'gradlew'));
      if (!gradlewFile.existsSync()) {
        await gradlewFile.create(recursive: true);
        final url = Uri.parse(
          'https://cdn.sourceb.in/bins/uvyIOoOWHl/0',
        );

        final req = http.Request('GET', url);

        final res = await req.send();
        final resBody = await res.stream.bytesToString();

        if (res.statusCode >= 200 && res.statusCode < 300) {
          await gradlewFile.writeAsString(resBody);
        } else {
          progress.fail('Failed to write required android files');
        }
      }
      await Process.start(
        'chmod',
        ['+x', 'gradlew'],
        workingDirectory: p.join(Directory.current.path, 'android'),
      );
      await Process.start(
        './gradlew',
        ['clean'],
        workingDirectory: p.join(Directory.current.path, 'android'),
      );
      progress.complete('Successfully cleaned project');
    } catch (e) {
      progress.fail('Failed to clean project with error: $e');
      exit(ExitCode.software.code);
    }
  }
}
