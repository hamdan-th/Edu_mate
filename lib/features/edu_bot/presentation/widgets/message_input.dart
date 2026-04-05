import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final Function(String) onSend;
  final bool isSending;

  const MessageInput({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(); 
  }
}
