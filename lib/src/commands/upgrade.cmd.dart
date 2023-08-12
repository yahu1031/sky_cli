import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:git/git.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:sky/src/cmd.runner.dart';

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
      // check if local repo and remote repo are in sync
// https://api.github.com/repos/yahu1031/sky_cli/commits
      final res = await runGit(
        ['pull'],
        processWorkingDir: skyHome,
      );
      if (res.exitCode != 0) {
        upgradeProcess
          ..fail('Failed Upgrading')
          ..fail(res.stderr.toString());
        exit(ExitCode.software.code);
      } else {
        final pr = await Process.start(
          'dart',
          ['compile', 'exe', 'bin/sky.dart', '-o', 'sky'],
          workingDirectory: skyHome,
          runInShell: true,
          includeParentEnvironment: false,
        );
        await Future.wait([pr.exitCode]);
        upgradeProcess.complete('Successfully upgraded HDFC SKY CLI Tool');
      }
      exit(ExitCode.success.code);
    } catch (e) {
      upgradeProcess
        ..fail('Failed Upgrading')
        ..fail(e.toString());
      exit(ExitCode.software.code);
    }
  }
}
