import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:git/git.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:sky/src/commands/commands.dart';
import 'package:sky/src/version.dart';

const executableName = 'sky';
const packageName = 'sky';
const description = 'HDFC Sky CLI tool for flutter project.';
const repoUrl = 'github.com/yahu1031/sky_cli';
final home = Platform.environment['HOME'] ?? '~';
final skyHome = path.join(home, '.sky');

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
  })  : _logger = logger ?? Logger(),
        super(executableName, description) {
    // Add root options and flags
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );

    addCommand(SetupCommand(logger: _logger));
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
    // Fast track completion command
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    // Verbose logs
    _logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    return exitCode;
  }

  Future<void> init() async {
    if (Directory(skyHome).existsSync()) {
      return;
    }
    Directory(skyHome).createSync(recursive: true);
    final initProcess = _logger.progress('Initializing HDFC SKY...');
    try {
      final res = await runGit(
        ['clone', 'https://$repoUrl', '.'],
        processWorkingDir: skyHome,
      );
      if (res.exitCode != 0) {
        initProcess
          ..fail('Failed Initializing')
          ..fail(res.stderr.toString());
        return;
      } else {
        for (final rc in ['.zshrc', '.bashrc']) {
          await File(path.join(home, rc)).writeAsString(
            '\nexport PATH=\$PATH:$skyHome',
            mode: FileMode.append,
          );
          await Process.start(
            'source',
            [rc],
            workingDirectory: home,
            runInShell: true,
            includeParentEnvironment: false,
          );
        }
        await Process.start(
          'chmod',
          ['+x', 'sky'],
          workingDirectory: skyHome,
          runInShell: true,
          includeParentEnvironment: false,
        );
        await File(path.join(Directory.current.path, 'sky'))
            .delete(recursive: true);
        initProcess.complete('Initialized HDFC SKY');
      }
    } catch (e) {
      initProcess
        ..fail('Failed Initializing')
        ..fail(e.toString());
    }
  }

  Future<void> upgrade() async {
    if (!Directory(skyHome).existsSync()) {
      return;
    }
    final upgradeProcess = _logger.progress('Upgrading HDFC SKY CLI...');
    try {
      final res = await runGit(
        ['pull'],
        processWorkingDir: skyHome,
      );
      if (res.exitCode != 0) {
        upgradeProcess
          ..fail('Failed Upgrading')
          ..fail(res.stderr.toString());
        return;
      } else {
        final pr = await Process.start(
          'dart',
          ['compile', 'exe', 'bin/sky.dart', '-o', 'sky'],
          workingDirectory: skyHome,
          runInShell: true,
          includeParentEnvironment: false,
        );
        await Future.wait([pr.exitCode]);
        upgradeProcess.complete('Upgraded HDFC SKY CLI Tool');
      }
    } catch (e) {
      upgradeProcess
        ..fail('Failed Upgrading')
        ..fail(e.toString());
    }
  }
}
