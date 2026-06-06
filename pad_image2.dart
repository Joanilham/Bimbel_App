// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart';

void main() {
  final file = File('assets/images/app_logo.jpg');
  final bytes = file.readAsBytesSync();
  final img = decodeImage(bytes)!;
  
  // 1.25x scaling instead of 1.6x so it's not "hampa"
  final newSize = (img.width * 1.25).toInt();
  final paddedImg = Image(width: newSize, height: newSize);
  
  fill(paddedImg, color: ColorRgb8(255, 255, 255));
  
  final dstX = (newSize - img.width) ~/ 2;
  final dstY = (newSize - img.height) ~/ 2;
  compositeImage(paddedImg, img, dstX: dstX, dstY: dstY);
  
  File('assets/images/app_logo_padded.jpg').writeAsBytesSync(encodeJpg(paddedImg, quality: 100));
  print('Padded image updated!');
}
