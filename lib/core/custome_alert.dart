
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class CustomAlert extends StatelessWidget {
  final String title;
  final String body;

  const CustomAlert({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CustomAlert(title: title, body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElasticIn(
        duration: const Duration(milliseconds: 500),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}