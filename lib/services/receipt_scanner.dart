import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/models.dart';
import '../domain/receipt_parser.dart';
import '../domain/receipt_layout.dart';

class ReceiptScanner {
  Future<ReceiptDraft> scan(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      ReceiptDraft? draft;
      Object? fileError;
      try {
        draft = _parse(
          await recognizer.processImage(InputImage.fromFilePath(path)),
          path,
        );
      } catch (error) {
        fileError = error;
      }
      // Small WhatsApp images and EXIF/decoder differences can yield no text.
      // Decode with Flutter, normalize orientation/size, and send actual RGBA
      // pixels to ML Kit. The original photo remains the one saved on confirm.
      if (draft == null ||
          draft.total == null ||
          draft.date == null ||
          draft.merchant == null) {
        try {
          final buffer = await ui.ImmutableBuffer.fromUint8List(
            await File(path).readAsBytes(),
          );
          final descriptor = await ui.ImageDescriptor.encoded(buffer);
          final scale = 1800 / math.max(descriptor.width, descriptor.height);
          final codec = await descriptor.instantiateCodec(
            targetWidth: math.max(1, (descriptor.width * scale).round()),
            targetHeight: math.max(1, (descriptor.height * scale).round()),
          );
          try {
            final frame = await codec.getNextFrame();
            try {
              final pixels = await frame.image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              if (pixels != null) {
                final enhanced = _parse(
                  await recognizer.processImage(
                    InputImage.fromBitmap(
                      bitmap: pixels.buffer.asUint8List(
                        pixels.offsetInBytes,
                        pixels.lengthInBytes,
                      ),
                      width: frame.image.width,
                      height: frame.image.height,
                    ),
                  ),
                  path,
                );
                draft = ReceiptDraft(
                  total: draft?.total ?? enhanced.total,
                  date: draft?.date ?? enhanced.date,
                  merchant: draft?.merchant ?? enhanced.merchant,
                  rawText: enhanced.rawText.isNotEmpty
                      ? enhanced.rawText
                      : draft?.rawText ?? '',
                  imagePath: path,
                );
              }
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
            descriptor.dispose();
            buffer.dispose();
          }
        } catch (_) {
          if (draft == null && fileError != null) throw fileError;
        }
      }
      return draft ?? ReceiptParser().parse('', imagePath: path);
    } finally {
      await recognizer.close();
    }
  }

  ReceiptDraft _parse(RecognizedText result, String path) {
    final ordered = receiptReadingOrder(
      result.blocks.expand((block) => block.lines).map((line) {
        final box = line.boundingBox;
        return ReceiptTextLine(
          line.text,
          box.left,
          box.top,
          box.width,
          box.height,
        );
      }),
    );
    return ReceiptParser().parse(
      ordered.isEmpty ? result.text : ordered,
      imagePath: path,
    );
  }
}
