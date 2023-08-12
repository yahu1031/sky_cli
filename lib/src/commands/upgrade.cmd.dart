import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
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
    final upgradeProcess = _logger.progress('Upgrading HDFC SKY CLI...');
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
      final scriptFile = File(Platform.script.toFilePath());
      if (!scriptFile.path.endsWith('.dart') && scriptFile.existsSync()) {
        _logger.detail('Deleting old CLI...');
        await scriptFile.delete(recursive: true);
      }
      _logger.detail('Compiling a new HDFC SKY CLI...');
      final pr = await Process.start(
        'dart',
        ['compile', 'exe', 'bin/sky.dart', '-o', 'sky'],
        workingDirectory: skyHome,
        runInShell: true,
        includeParentEnvironment: false,
      );
      final exitCode = await Future.wait([pr.exitCode]);
      upgradeProcess.complete('Successfully upgraded HDFC SKY CLI Tool with '
          'exit code: ${exitCode.first}');
      exit(ExitCode.success.code);
    } catch (e, s) {
      upgradeProcess
        ..fail('Failed Upgrading')
        ..fail(e.toString());
      _logger
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
}
