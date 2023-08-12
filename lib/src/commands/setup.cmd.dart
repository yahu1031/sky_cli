import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sky/src/commands/clean.cmd.dart';
import 'package:sky/src/lock.dart';
import 'package:yaml/yaml.dart';

/// {@template setup_command}
///
/// `sky setup`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class SetupCommand extends Command<int> {
  /// {@macro setup_command}
  SetupCommand({
    required Logger logger,
  }) : _logger = logger;

  final String _pubCache = p.join(
    Platform.environment['HOME'] ?? '',
    '.pub-cache',
    'hosted',
    'pub.dartlang.org',
  );

  @override
  String get description => 'Setup the project according to the machine.';

  @override
  String get name => 'setup';

  final Logger _logger;

  @override
  Future<int> run() async {
    await isHDFCproject();
    final progress = _logger.progress('Setting up the project');
    try {
      await _checkPackagesCode();
      progress
        ..update('Cleaning the project')
        ..complete('Project setup completed');
      await CleanCommand(logger: _logger).cleanProject();
      return ExitCode.success.code;
    } catch (e, s) {
      _logger
        ..err(e.toString())
        ..detail('StackTraces:')
        ..detail('$s');

      return ExitCode.ioError.code;
    }
  }

  Future<bool> isHDFCproject() async {
    final progress = _logger.progress('Checking the project');
    try {
      final yamlFile = File(p.join(Directory.current.path, 'pubspec.yaml'));
      final yamlData = await yamlFile.readAsString();
      final yamlObject = loadYaml(yamlData) as YamlMap;
      final projName = yamlObject['name'];
      if (projName != 'hdfcapp') {
        progress.fail('Looks like you are not in HDFC SKY app project');
        exit(1);
      }
      progress.complete('Found the HDFC SKY project');
      return true;
    } catch (e, s) {
      progress.fail();
      _logger
        ..err('Failed looking up HDFC SKY app project')
        ..err('Error : $e')
        ..detail('StackTraces:')
        ..detail('$s');

      rethrow;
    }
  }

  Future<Package?> _fetchPackageFromLock(String packageName) async {
    final progress = _logger.progress('Looking up into HDFC SKY project...');
    try {
      final lockFile = File(p.join(Directory.current.path, 'pubspec.lock'));
      if (!lockFile.existsSync()) {
        _logger.detail(
          "Pubspec.lock for HDFC SKY project wasn't found at ${Directory.current.path}",
        );
        progress.fail();
        _logger.err('No HDFC SKY project found. Please run `sky clone` first.');
        exit(1);
      }
      progress.update('Reading project...');
      final lock = await lockFile.readAsString();
      _logger
        ..detail('Pubspec.lock read')
        ..detail(lock);
      final yaml = loadYaml(lock);
      // convert yaml to json
      final yamlString = jsonEncode(yaml);
      final lockMap =
          LockMap.fromJson(jsonDecode(yamlString) as Map<String, dynamic>);
      progress.complete('Successfully read project');
      _logger
        ..detail('Found $packageName Details')
        ..detail(lockMap.packages[packageName].toString())
        ..detail('');
      return lockMap.packages[packageName];
    } catch (e, s) {
      progress.fail();
      _logger
        ..err('Failed checking packages version.')
        ..err('Error : $e')
        ..detail('StackTraces:')
        ..detail('$s');

      exit(ExitCode.osFile.code);
    }
  }

  Future<void> _checkPackagesCode() async {
    final progress = _logger.progress('Checking packages code');
    try {
      // Check the package version
      final firebase = await _fetchPackageFromLock('firebase_core');
      final graphql = await _fetchPackageFromLock('graphql');
      final infiniteScrollPagination =
          await _fetchPackageFromLock('infinite_scroll_pagination');
      if (firebase != null) {
        await _fixFirebase(firebase);
      }
      if (graphql != null) {
        await _fixGraphql(graphql);
      }
      if (infiniteScrollPagination != null) {
        await _fixInfiniteScrollPagination(infiniteScrollPagination);
      }
      await pubGet();
      await _podInstall();
      progress.complete('Packages code checked');
    } catch (e, s) {
      progress.fail();
      _logger
        ..err('Failed to check packages code.')
        ..err('Error: $e')
        ..detail('StackTraces:')
        ..detail('$s');

      exit(ExitCode.software.code);
    }
  }

  Future<void> _fixInfiniteScrollPagination(
    Package infiniteScrollPagination,
  ) async {
    final progress = _logger.progress('Fixing infinite_scroll_pagination');
    try {
      // check if infinite_scroll_pagination is installed in _pubCache
      final infiniteScrollPaginationPath = depsPath(infiniteScrollPagination);
      _logger.detail(
        'Package ${infiniteScrollPagination.description.name} found at $infiniteScrollPaginationPath',
      );
      if (!Directory(infiniteScrollPaginationPath).existsSync()) {
        _logger.warn('infinite_scroll_pagination not found in $_pubCache');
      } else {
        // read paged_sliver_builder.dart file
        final pagedSliverBuilderFile = File(
          p.join(
            infiniteScrollPaginationPath,
            'lib',
            'src',
            'ui',
            'paged_sliver_builder.dart',
          ),
        );
        if (!pagedSliverBuilderFile.existsSync()) {
          progress.fail();
          _logger.err('paged_sliver_builder.dart file not found');
          return;
        }
        final pagedSliverBuilderContent =
            await pagedSliverBuilderFile.readAsString();
        // split the file content by new line
        final lines = pagedSliverBuilderContent.split('\n');
        final tempLines = lines;
        if (lines
            .elementAt(253)
            .trim()
            .startsWith('WidgetsBinding.instance.addPostFrameCallback')) {
          tempLines[253] = lines[253].replaceAll(
            'WidgetsBinding.instance.addPostFrameCallback',
            'WidgetsBinding.instance?.addPostFrameCallback',
          );
          await pagedSliverBuilderFile.writeAsString(tempLines.join('\n'));
          progress.complete('infinite_scroll_pagination fixed');
        }
      }
    } catch (e, s) {
      progress.fail();
      _logger
        ..err(e.toString())
        ..detail('StackTraces:')
        ..detail('$s');

      rethrow;
    }
  }

  Future<void> _fixFirebase(Package firebasePkg) async {
    final progress = _logger.progress('Fixing Firebase core code');
    try {
      // check if firebase_core is installed in _pubCache
      final firebaseCorePath = depsPath(firebasePkg);
      _logger.detail(
        'Package ${firebasePkg.description.name} found at $firebaseCorePath',
      );
      if (!Directory(firebaseCorePath).existsSync()) {
        _logger.warn('Firebase core not found in $_pubCache');
      } else {
        // read lib/src/firebase_app.dart file
        final firebaseAppFile = File(
          p.join(
            firebaseCorePath,
            'lib',
            'src',
            'firebase_app.dart',
          ),
        );
        if (!firebaseAppFile.existsSync()) {
          _logger.err('Firebase app file not found');
          return;
        }
        final firebaseAppFileContent = await firebaseAppFile.readAsString();
        // split the file content by new line
        final lines = firebaseAppFileContent.split('\n');
        final tempLines = lines;
        for (final line in lines) {
          if (line.trim() == 'FirebaseAppPlatform.verifyExtends(_delegate);') {
            tempLines[lines.indexOf(line)] =
                line.replaceAll('verifyExtends', 'verify');
            await firebaseAppFile.writeAsString(tempLines.join('\n'));
            progress.complete('Firebase core fixed');
            break;
          }
        }
      }
      return;
    } catch (e, s) {
      progress.fail();
      _logger
        ..err(e.toString())
        ..detail('StackTraces:')
        ..detail('$s');

      rethrow;
    }
  }

  Future<void> _fixGraphql(Package graphqlPkg) async {
    final progress = _logger.progress('Fixing the GraphQL code');
    try {
      // check if firebase_core is installed in _pubCache
      final graphqlPath = depsPath(graphqlPkg);
      _logger.detail(
        'Package ${graphqlPkg.description.name} found at $graphqlPath',
      );
      if (!Directory(graphqlPath).existsSync()) {
        _logger.warn('GraphQL not found in $_pubCache');
      } else {
        final graphqlFile = File(
          p.join(
            graphqlPath,
            'lib',
            'src',
            'links',
            'websocket_link',
            'websocket_client.dart',
          ),
        );
        if (!graphqlFile.existsSync()) {
          _logger.err('GraphQL file not found');
          return;
        }
        final graphqlFileContent = await graphqlFile.readAsString();
        // split the file content by new line
        final lines = graphqlFileContent.split('\n');
        final tempLines = lines;
        if (!graphqlFileContent
            .contains('final Future<void> ready = Future.value();')) {
          tempLines
            ..insert(598, '')
            ..insert(599, '  @override')
            ..insert(600, '  final Future<void> ready = Future.value();');
          await graphqlFile.writeAsString(tempLines.join('\n'));
          progress.complete('GraphQL fixed');
        }
      }
      return;
    } catch (e, s) {
      progress.fail();
      _logger
        ..err(e.toString())
        ..detail('StackTraces:')
        ..detail('$s');

      rethrow;
    }
  }

  Future<void> pubGet({String? path, String exe = 'flutter'}) async {
    final pubProgress = _logger.progress('Fetching packages...');
    try {
      _logger.detail(
        'Executing `flutter pub get` in ${path ?? Directory.current.path}',
      );
      final pubGet = await Process.start(
        exe,
        ['pub', 'get'],
        workingDirectory: path ?? Directory.current.path,
      );
      pubGet.stdout.transform(utf8.decoder).listen(_logger.detail);
      pubGet.stderr.transform(utf8.decoder).listen(_logger.err);
      await pubGet.exitCode;
      pubProgress.complete('Successfully fetched packages');
    } catch (e, s) {
      pubProgress.fail('Failed to fetch packages with error: $e');
      _logger
        ..detail('StackTraces:')
        ..detail('$s');

      exit(ExitCode.software.code);
    }
  }

  Future<void> _podInstall() async {
    final podProgress = _logger.progress('Installing pods...');
    try {
      _logger.detail(
        'Executing `pod install` in ${p.join(Directory.current.path, 'ios')}',
      );
      final podInstall = await Process.start(
        'pod',
        ['install', '--repo-update'],
        workingDirectory: p.join(Directory.current.path, 'ios'),
      );
      podInstall.stdout.transform(utf8.decoder).listen(_logger.detail);
      podInstall.stderr.transform(utf8.decoder).listen(_logger.err);
      final exitCode = await podInstall.exitCode;
      exitCode == ExitCode.success.code
          ? podProgress.complete('Successfully installed pods')
          : podProgress.fail('Failed to install pods');
    } catch (e, s) {
      podProgress.fail('Failed to install pods with error: $e');
      _logger
        ..detail('StackTraces:')
        ..detail('$s');

      exit(ExitCode.software.code);
    }
  }

  String depsPath(Package package) => p.join(
        _pubCache,
        '${package.description.name}-${package.version}',
      );
}
