import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:http/http.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:sky/src/commands/commands.dart';
import 'package:sky/src/commands/git.dart';
import 'package:sky/src/global.dart' as global;
import 'package:sky/src/version.dart';
import 'package:system_info2/system_info2.dart';

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
        super(global.executableName, global.description) {
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
    await init(
      isUpgradeCmd: topLevelResults.command?.name == 'upgrade' ||
          topLevelResults['version'] == true,
    );

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger
        ..detail('Major : ${packageVersion.split('.').first}')
        ..detail('Minor : ${packageVersion.split('.')[1]}')
        ..detail('Patch : ${packageVersion.split('.')[2].split('+').first})}');
      if (packageVersion.split('.')[2].split('+')[1].isNotEmpty) {
        _logger
            .detail('Hotfix : ${packageVersion.split('.')[2].split('+')[1]}');
      }
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    return exitCode;
  }

  bool get _cliDirExists => Directory(global.cliDir).existsSync();

  bool get _skyHomeExists => Directory(global.skyHome).existsSync();

  bool get _dartSdkExists =>
      Directory(path.join(global.skyHome, 'dart-sdk')).existsSync();

  bool get _cliExists => File(path.join(global.skyHome, 'sky')).existsSync();

  Future<void> init({required bool isUpgradeCmd}) async {
    if (_skyHomeExists && _dartSdkExists && _cliDirExists) {
      if (!isUpgradeCmd) {
        await UpgradeCommand(logger: global.logger).updatePrompt();
      }
      return;
    }
    Directory(global.skyHome).createSync(recursive: true);
    final initProcess = _logger.progress('Initializing HDFC SKY...');
    try {
      // dartsdk-macos-arm64-release.zip
      final zipName =
          '''dartsdk-${Platform.operatingSystem}-${SysInfo.rawKernelArchitecture.contains('arm') ? 'arm64' : 'x64'}-release.zip''';
      if (!_dartSdkExists) {
        final dartSdkUrl =
            'https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/$zipName';
        await global.downloadFile(dartSdkUrl, 'dart-sdk.zip');
        // unzip the file
        await global.unzipFile(
          path.join(global.skyHome, 'dart-sdk.zip'),
          Directory(global.skyHome),
        );
        _logger.detail('Granting Dart CLI permissions...');
        final dartSdkList = Directory(path.join(global.skyHome, 'dart-sdk'))
            .listSync(recursive: true);
        for (final file in dartSdkList) {
          await global.grantPermissionsRecursively(file.path);
        }
        _logger.detail('Deleting the dart-sdk.zip file');
        await File(path.join(global.skyHome, 'dart-sdk.zip')).delete();
      }
      if (!_cliDirExists) {
        await git.clone(
          user: 'yahu1031',
          repo: 'sky_cli',
          outputDirectory: 'cli',
        );
      }
      if (!_cliExists) {
        await SetupCommand(logger: global.logger)
            .pubGet(path: global.cliDir, exe: global.latestDart);
        _logger.detail('Building HDFC SKY CLI...');
        final compile = await Process.start(
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
        compile.stdout.transform(utf8.decoder).listen(_logger.detail);
        compile.stderr.listen((err) {
          _logger.err('[FAILED]  : ${utf8.decode(err)}');
        });
        final compileExitCode = await compile.exitCode;
        _logger.detail('Compilation exited with $compileExitCode code');
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
      if (!skyFile.path.endsWith('.dart') && skyFile.existsSync()) {
        skyFile.deleteSync();
      }
      initProcess.complete('Initialized HDFC SKY');
    } catch (e, s) {
      if (e is ClientException && e.message.startsWith('Failed host lookup')) {
        initProcess.fail(
          '''Looks like there is no Internet Connection. Try again later.''',
        );
        exit(ExitCode.noHost.code);
      }
      initProcess.fail('Failed Initializing');
      _logger
        ..detail(e is ProcessException ? e.message : e.toString())
        ..detail('Stacktrace:')
        ..detail('$s');
      exit(ExitCode.software.code);
    }
  }
}
