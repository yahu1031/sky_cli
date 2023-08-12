import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

final home = Platform.environment['HOME'] ?? '~';

final skyHome = path.join(home, '.sky');

final cliDir = path.join(skyHome, 'cli');

final latestDart = path.join(skyHome, 'dart-sdk', 'bin', 'dart');

final Logger logger = Logger();

Future<void> unzipFile(String filePath, Directory targetDirectory) async {
  try {
    // Read the zip file from disk
    logger.detail(
      'Reading the ${filePath.split(Platform.pathSeparator).last} file...',
    );
    final bytes = await File(filePath).readAsBytes();

    // Decode the Zip file
    logger.detail(
      'Decoding the ${filePath.split(Platform.pathSeparator).last} file...',
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final totalFiles = archive.length;
    var processedFiles = 0;

    // Extract the contents of the Zip archive to disk
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final tempfile = File(path.join(targetDirectory.path, filename));
        await tempfile.create(recursive: true);
        logger.detail('Writing $filename to ${tempfile.path}...');
        await tempfile.writeAsBytes(data);
      } else {
        logger.detail('Creating $filename Directory...');
        await Directory(path.join(targetDirectory.path, filename))
            .create(recursive: true);
      }
      processedFiles++;
      final percentage =
          ((processedFiles / totalFiles) * 100).toStringAsFixed(2);
      logger.detail('Unzipped: $percentage %');
    }
  } catch (e, s) {
    logger
      ..detail('Failed to UnZip ${filePath.split(Platform.pathSeparator).last}')
      ..detail('')
      ..detail('StackTraces :')
      ..detail('$s');
    rethrow;
  }
}

Future<void> downloadFile(String url, String fileName) async {
  try {
    logger.detail('Downloading dart sdk from $url');
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    final dartSdk = File(path.join(skyHome, fileName));
    logger.detail('Writing data to $fileName...');
    final fileSink = dartSdk.openWrite();
    final contentLength = response.contentLength ?? 0;
    var bytesDownloaded = 0;
    await for (final data in response.stream) {
      fileSink.add(data);
      bytesDownloaded += data.length;
      final percentage =
          (bytesDownloaded / contentLength * 100).toStringAsFixed(2);
      logger.detail('Downloaded: $percentage %');
    }
    logger
      ..detail('Writing done...')
      ..detail('Flushing $fileName...');
    await fileSink.flush();
    logger.detail('Closing $fileName...');
    await fileSink.close();
  } catch (e, s) {
    logger
      ..detail('Failed to download $fileName')
      ..detail('')
      ..detail('StackTraces :')
      ..detail('$s');
    rethrow;
  }
}

Future<void> grantPermissionsRecursively(String filePath) async {
  try {
    final fileName = filePath.split(Platform.pathSeparator).last;
    logger.detail('Granting $fileName permissions...');
    final result = await Process.run('chmod', ['-R', '777', filePath]);
    if (result.exitCode != 0) {
      logger
        ..detail('Error setting permissions to $fileName')
        ..detail('${result.stderr}');
    }
  } catch (e) {
    rethrow;
  }
}
