// Run with flutter build bundle, then flutter_tester (see docs).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  const sdk = String.fromEnvironment('FLUTTER_SDK');
  final font = FontLoader('Roboto')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf')
              .readAsBytesSync(),
        ),
      ),
    );
  await font.load();
  final boundaryKey = GlobalKey();
  runApp(
    MediaQuery(
      data: const MediaQueryData(size: Size(412, 892)),
      child: RepaintBoundary(
        key: boundaryKey,
        child: SednoApp(
          historyRepository: MockHistoryRepository(clock: DateTime.now),
        ),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  RendererBinding.instance.renderViews.first.configuration = ViewConfiguration(
    logicalConstraints: BoxConstraints.tight(const Size(412, 892)),
    physicalConstraints: BoxConstraints.tight(const Size(412, 892)),
    devicePixelRatio: 1,
  );
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
  Future<void> save(String name) async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = File('build/previews/$name.png');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
    stdout.writeln('Saved ${output.path}');
  }

  await save('home');
  final editor = findEditor(boundaryKey.currentContext! as Element);
  editor.controller!.text =
      'W związku z planowanymi pracami konserwacyjnymi '
      'dostawa wody zostanie wstrzymana w godzinach od 8:00 do 14:00.';
  await WidgetsBinding.instance.endOfFrame;
  await save('home-with-text');
  exit(0);
}

TextField findEditor(Element element) {
  TextField? result;
  void visit(Element child) {
    if (child.widget case final TextField field) result = field;
    if (result == null) child.visitChildren(visit);
  }

  visit(element);
  return result!;
}
