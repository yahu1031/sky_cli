import 'dart:io';

import 'package:scoped/scoped.dart';
import 'package:sky/src/cmd.runner.dart';
import 'package:sky/src/commands/git.dart';
import 'package:sky/src/global.dart';

Future<void> main(List<String> args) async {
  await _flushThenExit(
    await runScoped(
      () async => SkyCommandRunner(logger: logger).run(args),
      values: {
        gitRef,
      },
    ),
  );
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
