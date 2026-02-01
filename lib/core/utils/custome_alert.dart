import 'package:flutter/material.dart';

class CustomeAlert extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  const CustomeAlert({super.key, this.title, this.content, this.actions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions ?? [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
