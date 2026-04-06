import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  final inputPath = r'C:\Users\Abdulaziz\.gemini\antigravity\brain\aaf180ad-5274-4b28-8f5c-c14803ac291b\media__1775442994875.jpg';
  final outputPath = r'C:\Users\Abdulaziz\IdeaProjects\edu_mate\assets\images\university_logo.png';
  
  final bytes = File(inputPath).readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  // Make the image transparent
  final transparentImage = img.Image(width: image.width, height: image.height, numChannels: 4);
  
  bool isBackground(int r, int g, int b) {
    int maxColor = [r, g, b].reduce(math.max);
    int minColor = [r, g, b].reduce(math.min);
    if (r > 120 && g > 120 && b > 120 && (maxColor - minColor) < 30) return true;
    return false;
  }
  
  // Strip background
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      if (isBackground(p.r.toInt(), p.g.toInt(), p.b.toInt())) {
        transparentImage.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        transparentImage.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      }
    }
  }

  // Find the gap to crop out text.
  // We scan horizontally from top to bottom.
  // The first segment of continuous non-background pixels is the shield.
  // The moment we hit an empty row (after Y > 30%), we crop there!
  int cropHeight = transparentImage.height;
  bool inShield = false;
  
  for (int y = 0; y < transparentImage.height; y++) {
    bool rowHasContent = false;
    for (int x = 0; x < transparentImage.width; x++) {
      if (transparentImage.getPixel(x, y).a > 0) {
        rowHasContent = true;
        break;
      }
    }
    
    if (y > transparentImage.height * 0.1 && rowHasContent) {
      inShield = true;
    }
    
    if (inShield && !rowHasContent && y > transparentImage.height * 0.4) {
      // Gap found! The shield ended.
      cropHeight = y;
      break;
    }
  }
  
  // Crop the image
  final cropped = img.copyCrop(transparentImage, x: 0, y: 0, width: transparentImage.width, height: cropHeight);
  
  // Crop empty borders left/right
  int minX = cropped.width;
  int maxX = 0;
  int minY = cropped.height;
  int maxY = 0;
  
  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      if (cropped.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  
  // Safely pad slightly
  minX = math.max(0, minX - 10);
  minY = math.max(0, minY - 10);
  maxX = math.min(cropped.width - 1, maxX + 10);
  maxY = math.min(cropped.height - 1, maxY + 10);
  
  final tightCrop = img.copyCrop(cropped, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
  
  // Anti-bleed: Remove rogue disconnected pixels if possible (optional)
  
  File(outputPath).writeAsBytesSync(img.encodePng(tightCrop));
  print('Done. Saved to \$outputPath. Size: \${tightCrop.width}x\${tightCrop.height}, CropHeight was \$cropHeight');
}
