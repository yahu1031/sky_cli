import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
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
    try {
      final progress = _logger.progress('Setting up the project');
      await _checkPackagesCode();
      progress.complete('Project setup completed');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err(e.toString());
      return ExitCode.ioError.code;
    }
  }

  Future<Package?> _fetchPackageFromLock(String packageName) async {
    final lockFile = File(p.join(Directory.current.path, 'pubspec.lock'));
    if (!lockFile.existsSync()) {
      _logger.err('No HDFC SKY project found. Please run `sky clone` first.');
      exit(1);
    }
    final lock = await lockFile.readAsString();
    final yaml = loadYaml(lock);
    // convert yaml to json
    final yamlString = jsonEncode(yaml);
    final lockMap =
        LockMap.fromJson(jsonDecode(yamlString) as Map<String, dynamic>);
    return lockMap.packages[packageName];
  }

  /// final progress = _logger.progress('Checking packages code');
  /// Fix Firebase code
  ///
  /// File exists in $HOME/.pub-cache/hosted/pub.dartlang.org/firebase_core-1.24.0/lib/src/firebase_app.dart - line 18
  ///
  /// File exists in $HOME/.pub-cache/hosted/pub.dartlang.org/graphql-5.1.2/lib/src/links/websocket_link/websocket_client.dart - add       `final Future<void> ready = Future.value();`
  ///
  /// File exists in $HOME/.pub-cache/hosted/pub.dartlang.org/infinite_scroll_pagination-3.2.0/lib/src/ui/paged_sliver_builder.dart - line 254
  Future<void> _checkPackagesCode() async {
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
    // progress.complete('Packages code checked');
  }

  Future<void> _fixInfiniteScrollPagination(
    Package infiniteScrollPagination,
  ) async {
    try {
      // check if infinite_scroll_pagination is installed in _pubCache
      final infiniteScrollPaginationPath = depsPath(infiniteScrollPagination);
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
          _logger.info('infinite_scroll_pagination fixed');
        }
      }
    } catch (e) {
      _logger.err(e.toString());
      rethrow;
    }
  }

  Future<void> _fixFirebase(Package firebasePkg) async {
    try {
      // check if firebase_core is installed in _pubCache
      final firebaseCorePath = depsPath(firebasePkg);
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
            _logger.info('Fixing Firebase core code');
            tempLines[lines.indexOf(line)] =
                line.replaceAll('verifyExtends', 'verify');
            await firebaseAppFile.writeAsString(tempLines.join('\n'));
            break;
          }
        }
      }
      return;
    } catch (e) {
      _logger.err(e.toString());
      rethrow;
    }
  }

  Future<void> _fixGraphql(Package graphqlPkg) async {
    try {
      // check if firebase_core is installed in _pubCache
      final graphqlPath = depsPath(graphqlPkg);
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
          _logger.info('Fixing the GraphQL code');
          tempLines
            ..insert(598, '')
            ..insert(599, '  @override')
            ..insert(600, '  final Future<void> ready = Future.value();');
          await graphqlFile.writeAsString(tempLines.join('\n'));
        }
      }
      return;
    } catch (e) {
      _logger.err(e.toString());
      rethrow;
    }
  }

  Future<void> _pubGet() async {}

  Future<void> _podInstall() async {}

  String depsPath(Package package) => p.join(
        _pubCache,
        '${package.description.name}-${package.version}',
      );
}
