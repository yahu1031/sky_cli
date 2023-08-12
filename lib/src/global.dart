import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

final home = Platform.environment['HOME'] ?? '~';

final skyHome = path.join(home, '.sky');

final cliDir = path.join(skyHome, 'cli');

final latestDart = path.join('.', 'sdk', 'bin', 'dart');

final Logger logger = Logger();
