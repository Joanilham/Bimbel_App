// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart';

void main() {
  final file = File('assets/images/app_logo.jpg');
  final bytes = file.readAsBytesSync();
  final img = decodeImage(bytes)!;
  
  // Adaptive icons need a lot of padding.
  // The safe zone is 72/108 = 66% of the image.
  // So we need the original image to take up at most 66% of the new canvas.
  // Let's create a new square image that is 1.6x the size of the original.
  final newSize = (img.width * 1.6).toInt();
  final paddedImg = Image(width: newSize, height: newSize);
  
  // Fill with white
  fill(paddedImg, color: ColorRgb8(255, 255, 255));
  
  // Draw original image in center
  final dstX = (newSize - img.width) ~/ 2;
  final dstY = (newSize - img.height) ~/ 2;
  compositeImage(paddedImg, img, dstX: dstX, dstY: dstY);
  
  File('assets/images/app_logo_padded.jpg').writeAsBytesSync(encodeJpg(paddedImg, quality: 100));
  print('Padded image created!');
}
