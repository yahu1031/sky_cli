import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:scoped/scoped.dart';
import 'package:sky/src/global.dart';

/// A reference to a [Git] instance.
final gitRef = create(Git.new);

/// The [Git] instance available in the current zone.
Git get git => read(gitRef);

/// A wrapper around all git related functionality.
class Git {
  static const executable = 'git';

  final Logger _logger = logger;

  /// Clones the git repository located at [url] into the [outputDirectory].
  /// `git clone <url> ...<args> <outputDirectory>`
  Future<void> clone({
    required String user,
    required String repo,
    required String outputDirectory,
    String? workindDir,
    List<String>? args,
  }) async {
    final arguments = [
      'clone',
      'https://github.com/$user/$repo',
      ...?args,
      outputDirectory,
    ];
    _logger.detail('Cloning $repo from $user');
    final result = await Process.run(
      executable,
      arguments,
      runInShell: true,
      workingDirectory: skyHome,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Checks out the git repository located at [directory] to the [revision].
  Future<void> checkout({
    required String directory,
    required String revision,
  }) async {
    final arguments = [
      '-C',
      directory,
      '-c',
      'advice.detachedHead=false',
      'checkout',
      revision,
    ];
    _logger.detail('Checking out to $revision in $directory');
    final result = await Process.run(
      executable,
      arguments,
      runInShell: true,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Fetch branches/tags from the repository at [directory].
  Future<void> fetch({required String directory, List<String>? args}) async {
    final arguments = ['fetch', ...?args];
    _logger.detail('Fetching Tags/Branches of $directory');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Iterate over all refs that match [pattern] and show them
  /// according to the given [format].
  Future<String> forEachRef({
    required String directory,
    required String format,
    required String pattern,
    String? pointsAt,
  }) async {
    final arguments = [
      'for-each-ref',
      if (pointsAt != null) ...['--points-at', pointsAt],
      '--format',
      format,
      pattern
    ];
    _logger.detail('Iterating Git Refs of $directory');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
    return '${result.stdout}'.trim();
  }

  /// Prunes stale remote branches from the repository at [directory]
  /// associated with [name].
  Future<void> remotePrune({
    required String name,
    required String directory,
  }) async {
    final arguments = ['remote', 'prune', name];
    _logger.detail('Pruning $directory remote branches...');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Resets the git repository located at [directory] to the [revision].
  Future<void> reset({
    required String revision,
    required String directory,
    List<String>? args,
  }) async {
    final arguments = ['reset', ...?args, revision];
    _logger.detail('Resetting $directory...');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Returns the revision of the git repository located at [directory].
  Future<String> revParse({
    required String revision,
    required String directory,
  }) async {
    final arguments = ['rev-parse', '--verify', revision];
    _logger.detail('Fetching $directory revisions...');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
    return '${result.stdout}'.trim();
  }

  /// Returns the status of the git repository located at [directory].
  Future<String> status({required String directory, List<String>? args}) async {
    final arguments = ['status', ...?args];
    _logger.detail('Fetching $directory Git status...');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: directory,
    );
    if (result.exitCode != 0) {
      _logger
        ..detail(result.stdout.toString())
        ..detail(result.stderr.toString());
      throw ProcessException(
        executable,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
    return '${result.stdout}'.trim();
  }
}
