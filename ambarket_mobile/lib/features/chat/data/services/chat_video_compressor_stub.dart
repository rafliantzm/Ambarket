class CompressedVideoFile {
  final String path;
  final int sizeBytes;

  const CompressedVideoFile({required this.path, required this.sizeBytes});
}

Future<CompressedVideoFile?> compressChatVideoUnderLimit({
  required String path,
  required int maxBytes,
}) async {
  return null;
}
