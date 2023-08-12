import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sky/src/commands/git.dart';
import 'package:sky/src/global.dart';

/// `sky upgrade`
/// A [Command] to exemplify a sub command
class UpgradeCommand extends Command<int> {
  /// {@macro sample_command}
  UpgradeCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get description => 'Upgrade HSFC SKY cli to the latest version';

  @override
  String get name => 'upgrade';

  final Logger _logger;

  @override
  Future<int> run() async {
    if (!Directory(skyHome).existsSync()) {
      exit(ExitCode.osFile.code);
    }
    final upgradeProcess = _logger.progress('Checking for updates...');
    try {
      final isUptoDate = await isLatest();
      if (isUptoDate) {
        upgradeProcess.complete('Already up to date');
        exit(ExitCode.success.code);
      }
      await git.remotePrune(
        name: 'origin',
        directory: cliDir,
      );
      final scriptFile =
          File(Platform.script.toFilePath(windows: Platform.isWindows));
      if (!scriptFile.path.endsWith('.dart') && scriptFile.existsSync()) {
        _logger
          ..detail('Listing $cliDir')
          ..detail('${Directory(cliDir).listSync()}')
          ..detail('')
          ..detail('Deleting old CLI...');
        await scriptFile.delete(recursive: true);
      }
      _logger.detail('Compiling a new HDFC SKY CLI...');
      final compileArgs = [
        'compile',
        'exe',
        'bin/sky.dart',
        '-o',
        p.join(skyHome, 'sky'),
        '--target-os',
        Platform.operatingSystem
      ];
      final pr = await Process.start(
        latestDart,
        compileArgs,
        workingDirectory: cliDir,
        runInShell: true,
      );
      pr.stdout.transform(utf8.decoder).listen(_logger.detail);
      pr.stderr.transform(utf8.decoder).listen(_logger.err);
      final exitCode = await Future.wait([pr.exitCode]);
      _logger.detail('Compile exit code: ${exitCode.first}');
      upgradeProcess.complete('Successfully upgraded HDFC SKY CLI');
      exit(ExitCode.success.code);
    } catch (e, s) {
      upgradeProcess.fail('Failed Upgrading');
      _logger
        ..detail('$e')
        ..detail('StackTraces:')
        ..detail('$s');
      exit(ExitCode.software.code);
    }
  }

  Future<String> _fetchLatestGitHash() async {
    try {
      // Fetch upstream branch's commits and tags
      await git.fetch(directory: cliDir, args: ['--tags']);
      // Get the latest commit revision of the upstream
      return git.revParse(revision: '@{upstream}', directory: cliDir);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _fetchCurrentGitHash() async {
    try {
      // Get the commit revision of HEAD
      return git.revParse(revision: 'HEAD', directory: cliDir);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLatest() async {
    try {
      final currentVersion = await _fetchCurrentGitHash();
      _logger.detail('Current version: $currentVersion');
      final latestVersion = await _fetchLatestGitHash();
      _logger
        ..detail('Latest version: $latestVersion')
        ..detail('Update available: ${currentVersion != latestVersion}');
      return currentVersion == latestVersion;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePrompt() async {
    final isUptoDate = await isLatest();
    if (!isUptoDate) {
      _logger
        ..alert('┌─────────────────────────┐')
        ..alert('│    Update Available.    │')
        ..alert('│    Run "sky upgrade"    │')
        ..alert('└─────────────────────────┘');
    }
  }
}
