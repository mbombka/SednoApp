// Run with flutter build bundle, then flutter_tester (see docs).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';

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
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
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

  HomeScreen? home;
  void findHome(Element element) {
    if (element.widget case final HomeScreen screen) home = screen;
    element.visitChildren(findHome);
  }

  findHome(boundaryKey.currentContext! as Element);
  Future<void> showResult(String text, String name) async {
    editor.controller!.value = TextEditingValue(
      text: text,
      selection: const TextSelection.collapsed(offset: 0),
    );
    home!.editorResult!.show(
      originalText:
          'Przykładowy oryginalny komunikat o przerwie w dostawie wody.',
      mode: TextMode.simplify,
    );
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    void resetScroll(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        position.jumpTo(position.minScrollExtent);
        stdout.writeln('$name: scroll extent ${position.maxScrollExtent}');
      }
      element.visitChildren(resetScroll);
    }

    resetScroll(boundaryKey.currentContext! as Element);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await save(name);
  }

  await showResult(
    'Jutro od 8:00 do 14:00 nie będzie wody.\n\n'
        'W tym czasie będą trwały prace przy wodociągu. '
        'Przygotuj wcześniej zapas wody.',
    'result-short',
  );
  await showResult(
    'Jutro od 8:00 do 14:00 nie będzie wody.\n\n'
        'Pracownicy naprawią wodociąg przy ulicy Lipowej. '
        'Przerwa dotyczy wszystkich budynków przy tej ulicy.\n\n'
        'Jak się przygotować?\n\n'
        'Nalej wcześniej wodę do butelek lub dzbanka. '
        'Przygotuj tyle wody, ile potrzebujesz do picia, '
        'gotowania i mycia rąk.\n\n'
        'Jeśli możesz, zrób pranie i umyj naczynia przed 8:00. '
        'Podczas przerwy nie uruchamiaj pralki ani zmywarki.\n\n'
        'Co zrobić po zakończeniu prac?\n\n'
        'Odkręć kran i sprawdź, czy woda jest czysta. '
        'Na początku może być lekko mętna. '
        'Poczekaj, aż znów będzie przejrzysta.\n\n'
        'Jeśli po 14:00 nadal nie będzie wody, '
        'skontaktuj się z administracją budynku. '
        'Numer telefonu znajdziesz na tablicy ogłoszeń przy wejściu.\n\n'
        'Przekaż tę informację sąsiadom, którzy mogą jej potrzebować.',
    'result-long',
  );
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
