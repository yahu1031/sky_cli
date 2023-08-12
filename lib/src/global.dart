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
    await for (final data in response.stream) {
      fileSink.add(data);
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
