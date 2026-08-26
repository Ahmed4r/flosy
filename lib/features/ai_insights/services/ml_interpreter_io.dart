import 'package:tflite_flutter/tflite_flutter.dart';

Future<dynamic> createInterpreterFromAsset(String assetPath) {
  return Interpreter.fromAsset(assetPath);
}

void closeInterpreter(dynamic interpreter) {
  if (interpreter is Interpreter) {
    interpreter.close();
  }
}
