import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:jaspr/jaspr.dart';

abstract class JasprCommand extends Command<JasprCommand> {
  final _processes = <Process>[];

  @override
  FutureOr<JasprCommand> run() => this;

  Future<int> runCommand();

  void forceQuit() {
    for (final process in _processes) {
      process.kill(ProcessSignal.sigint);
    }
    exit(-1);
  }

  @protected
  Future<Process> runWebdev(List<String> args) async {
    var globalPackageList =
        await Process.run('dart', ['pub', 'global', 'list'], stdoutEncoding: Utf8Codec());
    var hasGlobalWebdev = (globalPackageList.stdout as String).contains('webdev');

    Process process;

    if (hasGlobalWebdev) {
      process = await Process.start('dart', ['pub', 'global', 'run', 'webdev', ...args]);
    } else {
      process = await Process.start('dart', ['run', 'webdev', ...args]);
    }

    return process;
  }

  @protected
  void pipeError(Process process) {
    process.stderr.listen((event) => stderr.add(event));
  }

  @protected
  void pipeProcess(
    Process process, {
    bool Function(String)? until,
    bool Function(String)? hide,
    void Function(String)? listen,
  }) {
    pipeError(process);
    bool pipe = true;
    process.stdout.listen((event) {
      String? _decoded;
      String decoded() => _decoded ??= utf8.decode(event);

      if (pipe && until != null) {
        pipe = !until(decoded());
      }

      if (!pipe) return;
      if (hide?.call(decoded()) ?? false) return;
      listen?.call(decoded());
      stdout.add(event);
    });
  }

  @protected
  Future<String?> getEntryPoint(String? input) async {
    var entryPoints = [input, 'lib/main.dart', 'web/main.dart'];
    String? entryPoint;

    for (var path in entryPoints) {
      if (path == null) continue;
      if (await File(path).exists()) {
        entryPoint = path;
        break;
      }
    }

    return entryPoint;
  }

  @protected
  Future<void> maybeExit(Process process, {void Function()? onExit}) async {
    _processes.add(process);
    try {
      final exitCode = await process.exitCode;
      print('maybeExit: exitCode=$exitCode');
      if (exitCode != 0) {
        onExit?.call();
        exit(exitCode);
      }
    } catch (e) {
      print('maybeExit: error=$e');
    }
    _processes.remove(process);
  }
}
