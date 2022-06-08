import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'command.dart';
import 'commands/build_command.dart';
import 'commands/create_command.dart';
import 'commands/serve_command.dart';

void main(List<String> args) async {
  var runner = CommandRunner<JasprCommand>(
      "jaspr", "An experimental web framework for dart apps, supporting SPA and SSR.")
    ..addCommand(CreateCommand())
    ..addCommand(ServeCommand())
    ..addCommand(BuildCommand());

  StreamSubscription<ProcessSignal>? signal;
  try {
    late JasprCommand command;
    signal = ProcessSignal.sigint.watch().listen((signal) {
      command.forceQuit();
    });
    command = (await runner.run(args))!;
    exitCode = await command.runCommand();
  } on UsageException catch (e) {
    print(e.message);
    print('');
    print(e.usage);
  } catch (e, st) {
    print('$e\n$st');
    exitCode = -1;
  } finally {
    print('oh no!');
    signal?.cancel();
  }
}
