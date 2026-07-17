import 'dart:io';

import 'package:video_compress/video_compress.dart';

class CompressedVideoFile {
  final String path;
  final int sizeBytes;

  const CompressedVideoFile({required this.path, required this.sizeBytes});
}

Future<CompressedVideoFile?> compressChatVideoUnderLimit({
  required String path,
  required int maxBytes,
}) async {
  final qualities = <VideoQuality>[
    VideoQuality.MediumQuality,
    VideoQuality.LowQuality,
    VideoQuality.Res640x480Quality,
  ];

  for (final quality in qualities) {
    final info = await VideoCompress.compressVideo(
      path,
      quality: quality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 24,
    );
    final compressedPath = info?.path;
    if (compressedPath == null || compressedPath.isEmpty) {
      continue;
    }

    final file = File(compressedPath);
    if (!await file.exists()) {
      continue;
    }

    final size = await file.length();
    if (size <= maxBytes) {
      return CompressedVideoFile(path: compressedPath, sizeBytes: size);
    }
  }

  return null;
}
