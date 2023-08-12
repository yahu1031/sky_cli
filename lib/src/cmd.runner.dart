import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:sky/src/commands/commands.dart';
import 'package:sky/src/commands/git.dart';
import 'package:sky/src/global.dart' as global;
import 'package:sky/src/version.dart';

/// {@template sky_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```
/// $ sky --version
/// ```
/// {@endtemplate}
class SkyCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro sky_command_runner}
  SkyCommandRunner({
    Logger? logger,
  })  : _logger = logger ?? global.logger,
        super('sky', 'HDFC Sky CLI tool for flutter project.') {
    // Add root options and flags
    argParser
      ..addFlag(
        'version',
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.',
      );

    addCommand(SetupCommand(logger: _logger));
    addCommand(CleanCommand(logger: _logger));
    addCommand(UpgradeCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    await init();

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger
        ..detail('Major : ${Version.parse(packageVersion).major}')
        ..detail('Minor : ${Version.parse(packageVersion).minor}')
        ..detail('Patch : ${Version.parse(packageVersion).patch}')
        ..detail('Hotfix : ${Version.parse(packageVersion).build}')
        ..info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    return exitCode;
  }

  Future<void> init() async {
    final isUptoDate = await UpgradeCommand(logger: global.logger).isLatest();
    if (!isUptoDate) {
      _logger
        ..alert('┌─────────────────────────┐')
        ..alert('│    Update Available.    │')
        ..alert('│    Run "sky upgrade"    │')
        ..alert('└─────────────────────────┘');
    }
    final skyHomeExists = Directory(global.skyHome).existsSync();
    final dartSdkExists =
        Directory(path.join(global.skyHome, 'dart-sdk')).existsSync();
    final cliDirExists = Directory(global.cliDir).existsSync();
    if (skyHomeExists && dartSdkExists && cliDirExists) {
      return;
    }
    Directory(global.skyHome).createSync(recursive: true);
    final initProcess = _logger.progress('Initializing HDFC SKY...');
    try {
      if (!dartSdkExists) {
        await git.clone(
          user: 'dart-lang',
          repo: 'sdk',
          outputDirectory: 'dart-sdk',
        );
      }
      if (cliDirExists) {
        await git.clone(
          user: 'yahu1031',
          repo: 'sky_cli',
          outputDirectory: 'cli',
        );
      }
      if (cliDirExists && dartSdkExists) {
        await SetupCommand(logger: global.logger)
            .pubGet(path: global.cliDir, exe: global.latestDart);
        _logger.detail('Building HDFC SKY CLI...');
        await Process.start(
          global.latestDart,
          [
            'compile',
            'exe',
            'bin/sky.dart',
            '-o',
            path.join(global.skyHome, 'sky'),
            '--target-os',
            Platform.operatingSystem
          ],
          workingDirectory: global.cliDir,
          runInShell: true,
          includeParentEnvironment: false,
        );
      }
      if (File(path.join(global.skyHome, 'sky')).existsSync()) {
        _logger.detail('Granting HDFC SKY CLI permissions...');
        await Process.start(
          'chmod',
          ['+x', 'sky'],
          workingDirectory: global.skyHome,
          runInShell: true,
          includeParentEnvironment: false,
        );
      }
      for (final rc in ['.zshrc', '.bashrc']) {
        final rcData = await File(path.join(global.home, rc)).readAsString();
        final export = '\nexport PATH="\$PATH:${global.skyHome}"\n';
        if (!rcData.contains(export)) {
          _logger.detail('Adding HDFC SKY CLI to $rc...');
          await File(path.join(global.home, rc)).writeAsString(
            export,
            mode: FileMode.append,
          );
        }
        await Process.start(
          'source',
          [rc],
          workingDirectory: global.home,
          runInShell: true,
          includeParentEnvironment: false,
        );
      }
      _logger.detail('Cleaning up old CLI...');
      final skyFile = File(Platform.script.path);
      if (skyFile.existsSync()) {
        skyFile.deleteSync();
      }
      initProcess.complete('Initialized HDFC SKY');
    } catch (e, s) {
      initProcess
        ..fail('Failed Initializing')
        ..fail(e.toString());
      _logger.detail('Stacktrace: $s');
      exit(ExitCode.software.code);
    }
  }
}
