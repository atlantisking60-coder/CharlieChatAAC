import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: web_live_preview_tee.dart <flutterCommand> <logFile> [mode]');
    exit(1);
  }

  final flutterCmd = args[0];
  final logFile = args[1];
  final mode = args.length > 2 ? args[2] : 'chrome';

  final sink = File(logFile).openWrite(mode: FileMode.append, encoding: utf8);

  String? dartExe;

  // On Windows a .bat file must be invoked through cmd.exe so stream capture
  // and argument quoting work reliably. Process.start(runInShell: true) with a
  // .bat executable can drop or misparse the command line.
  final String executable;
  final List<String> arguments;
  if (Platform.isWindows &&
      (flutterCmd.toLowerCase().endsWith('.bat') ||
          flutterCmd.toLowerCase().endsWith('.cmd'))) {
    // Avoid cmd.exe wrapper so keystrokes (r, q) reach Flutter's stdin.
    final normalized = flutterCmd.replaceAll('/', '\\');
    final parts = normalized.split('\\');
    final binIndex = parts.lastIndexWhere((s) => s.toLowerCase() == 'bin');
    final flutterRoot =
        binIndex > 0 ? parts.sublist(0, binIndex).join('\\') : '';
    dartExe = '$flutterRoot\\bin\\cache\\dart-sdk\\bin\\dart.exe';
    final snapshot = '$flutterRoot\\bin\\cache\\flutter_tools.snapshot';

    if (File(dartExe!).existsSync() && File(snapshot).existsSync()) {
      executable = dartExe;
      arguments = [
        snapshot,
        'run',
        '-d',
        mode,
        '--web-port=8080',
        '--hot',
        '--web-hostname=localhost',
      ];
    } else {
      executable = 'cmd.exe';
      arguments = [
        '/c',
        flutterCmd,
        'run',
        '-d',
        mode,
        '--web-port=8080',
        '--hot',
        '--web-hostname=localhost',
      ];
    }
  } else {
    executable = flutterCmd;
    arguments = [
      'run',
      '-d',
      mode,
      '--web-port=8080',
      '--hot',
      '--web-hostname=localhost',
    ];
  }

  Process? devServer;
  if (dartExe != null) {
    devServer = await Process.start(
      dartExe,
      ['run', 'tools/dev_save_server.dart'],
      runInShell: false,
    );
    devServer.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stdout.writeln(line);
      sink.writeln(line);
    });
    devServer.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stderr.writeln(line);
      sink.writeln(line);
    });
  }

  final webRoot = p.absolute('build', 'web');
  if (!Directory(webRoot).existsSync()) {
    stderr.writeln('No build/web directory found. Run "flutter build web" first.');
    await sink.flush();
    await sink.close();
    exit(1);
  }

  // Board JSONs live in lib/data/boards but are declared in pubspec.yaml as
  // lib/... assets.  flutter build web does not actually copy them into
  // build/web/assets/lib/, so serve them from the source tree on the fly.
  final libRoot = p.absolute('lib');

  String contentTypeFor(String ext) {
    return switch (ext.toLowerCase()) {
      '.html' || '.htm' => 'text/html; charset=utf-8',
      '.js' => 'application/javascript; charset=utf-8',
      '.css' => 'text/css; charset=utf-8',
      '.json' => 'application/json; charset=utf-8',
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.svg' => 'image/svg+xml',
      '.webp' => 'image/webp',
      '.wasm' => 'application/wasm',
      '.ico' => 'image/x-icon',
      '.ttf' => 'font/ttf',
      '.otf' => 'font/otf',
      '.woff' => 'font/woff',
      '.woff2' => 'font/woff2',
      _ => 'application/octet-stream',
    };
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  final serverSub = server.listen((request) async {
    final response = request.response;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');

    // request.uri.path is already decoded by Dart; don't decode percent signs
    // again because some build/web asset folders contain literal '%20'.
    final uriPath = request.uri.path;
    final relative = uriPath.startsWith('/') ? uriPath.substring(1) : uriPath;
    final safeRelative = relative
        .split('/')
        .where((s) => s.isNotEmpty && s != '..')
        .join('/');

    // Flutter web asset paths declared under lib/ are requested at
    // /assets/lib/..., so map them back to the project lib/ directory.
    var filePath = safeRelative.startsWith('assets/lib/')
        ? p.join(libRoot, safeRelative.substring('assets/lib/'.length))
        : p.join(webRoot, safeRelative);

    if (Directory(filePath).existsSync()) {
      filePath = p.join(filePath, 'index.html');
    }
    if (!File(filePath).existsSync()) {
      if (safeRelative.startsWith('assets/') && !safeRelative.startsWith('assets/lib/')) {
        // Flutter's web build encodes spaces as %20 in the on-disk asset names,
        // while the browser request may use real spaces or %26. Normalise so
        // '1. Main Boards' and 'Animals and Habitats' still resolve.
        final encodedSafe = safeRelative
            .replaceAll(' ', '%20')
            .replaceAll('%26', '&');
        if (encodedSafe != safeRelative) {
          final encodedPath = p.join(webRoot, encodedSafe);
          if (File(encodedPath).existsSync() || Directory(encodedPath).existsSync()) {
            filePath = encodedPath;
          }
        }

        // Some runtime requests drop the leading 'assets/' asset prefix.
        if (!File(filePath).existsSync()) {
          final altPath = p.join(webRoot, 'assets', safeRelative);
          if (File(altPath).existsSync() || Directory(altPath).existsSync()) {
            filePath = altPath;
          }
        }
      }
    }
    if (Directory(filePath).existsSync()) {
      filePath = p.join(filePath, 'index.html');
    }
    if (!File(filePath).existsSync()) {
      // Real asset requests (have an extension) should 404, not get index.html.
      final isAsset = safeRelative.contains('.') && !safeRelative.endsWith('/');
      if (isAsset) {
        response.statusCode = HttpStatus.notFound;
        response.write('Not found');
        await response.close();
        return;
      }
      filePath = p.join(webRoot, 'index.html');
    }

    final file = File(filePath);
    if (await file.exists()) {
      response.headers.set(HttpHeaders.contentTypeHeader, contentTypeFor(p.extension(filePath)));
      await response.addStream(file.openRead());
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write('Not found');
    }
    await response.close();
  });

  final url = 'http://localhost:8080';
  stdout.writeln('');
  stdout.writeln('=============================================');
  stdout.writeln('  Charlie Chat Web Preview (build/web)');
  stdout.writeln('  $url');
  stdout.writeln('=============================================');
  stdout.writeln('Press q then Enter to quit.');
  sink.writeln('Serving $webRoot at $url');

  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().toLowerCase() == 'q') {
      break;
    }
  }

  await serverSub.cancel();
  await server.close();
  devServer?.kill();
  await Future.delayed(Duration(milliseconds: 200));
  await sink.flush();
  await sink.close();

  exit(0);
}
