import 'package:sedno_app/l10n/localization.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/photo/presentation/photo_crop_view_model.dart';

class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({required this.model, super.key});
  final PhotoCropViewModel model;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.model.load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = context.l10n;
    if (widget.model.strings.localeName != strings.localeName) {
      widget.model.message = null;
    }
    widget.model.localizations = () => strings;
  }

  @override
  void dispose() {
    widget.model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final model = widget.model;
      return PopScope(
        canPop: !model.busy,
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.selectText)),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    '${context.l10n.cropInstructions}${context.l10n.cropWholePhotoNotice}',
                  ),
                ),
                Expanded(
                  child: model.image == null
                      ? Center(
                          child: model.message == null
                              ? CircularProgressIndicator(
                                  semanticsLabel: context.l10n.openingPhoto,
                                )
                              : const SizedBox.shrink(),
                        )
                      : _Selection(model: model),
                ),
                if (model.message != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(model.message!),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 56),
                      ),
                      onPressed: model.image == null || model.busy
                          ? null
                          : () async {
                              final path = await model.read();
                              if (context.mounted && path != null) {
                                Navigator.pop(context, path);
                              }
                            },
                      child: Text(
                        model.busy
                            ? context.l10n.preparing
                            : context.l10n.simplify,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Selection extends StatelessWidget {
  const _Selection({required this.model});
  final PhotoCropViewModel model;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final image = model.image!;
      // Leave room around the photo for all 48 dp touch targets, even when
      // the initial selection includes the entire image.
      final scale = math.min(
        math.max(1, constraints.maxWidth - 64) / image.width,
        math.max(1, constraints.maxHeight - 64) / image.height,
      );
      final width = image.width * scale;
      final height = image.height * scale;
      final selection = Rect.fromLTRB(
        model.selection.left * width,
        model.selection.top * height,
        model.selection.right * width,
        model.selection.bottom * height,
      );
      return Center(
        child: SizedBox(
          width: width + 48,
          height: height + 48,
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 24,
                width: width,
                height: height,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    foregroundPainter: _SelectionPainter(selection),
                    child: RawImage(image: image, fit: BoxFit.fill),
                  ),
                ),
              ),
              for (final corner in CropCorner.values)
                _handle(context, corner, selection, width, height),
            ],
          ),
        ),
      );
    },
  );

  Widget _handle(
    BuildContext context,
    CropCorner corner,
    Rect rect,
    double width,
    double height,
  ) {
    final left =
        corner == CropCorner.topLeft || corner == CropCorner.bottomLeft;
    final top = corner == CropCorner.topLeft || corner == CropCorner.topRight;
    final label = switch (corner) {
      CropCorner.topLeft => context.l10n.cropTopLeft,
      CropCorner.topRight => context.l10n.cropTopRight,
      CropCorner.bottomLeft => context.l10n.cropBottomLeft,
      CropCorner.bottomRight => context.l10n.cropBottomRight,
    };
    void adjust(double amount) => model.moveCorner(
      corner,
      Offset(left ? amount : -amount, top ? amount : -amount),
    );
    return Positioned(
      left: left ? rect.left : rect.right,
      top: top ? rect.top : rect.bottom,
      width: 48,
      height: 48,
      child: Semantics(
        label: label,
        value: context.l10n.cropPosition(
          '${((left ? model.selection.left : model.selection.right) * 100).round()}',
          '${((top ? model.selection.top : model.selection.bottom) * 100).round()}',
        ),
        increasedValue: context.l10n.smallerSelection,
        decreasedValue: context.l10n.largerSelection,
        hint: context.l10n.cropResizeHint,
        onIncrease: model.busy ? null : () => adjust(0.025),
        onDecrease: model.busy ? null : () => adjust(-0.025),
        child: GestureDetector(
          key: ValueKey(corner),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onPanUpdate: model.busy
              ? null
              : (details) => model.moveCorner(
                  corner,
                  Offset(details.delta.dx / width, details.delta.dy / height),
                ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.blue,
                border: Border.all(color: Colors.white, width: 3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter(this.selection);
  final Rect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(selection);
    canvas.drawPath(mask, Paint()..color = const Color(0x99000000));
    canvas.drawRect(
      selection,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRect(
      selection,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      selection != oldDelegate.selection;
}
