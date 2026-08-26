Future<dynamic> createInterpreterFromAsset(String assetPath) async {
  throw UnsupportedError(
    'TFLite interpreter is not supported on this platform.',
  );
}

void closeInterpreter(dynamic interpreter) {
  // No-op on non-IO platforms.
}
