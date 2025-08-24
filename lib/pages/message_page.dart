import 'package:flutter/material.dart';
import '../modules/message/message_module.dart';

/// Page d'accès au module "Le Message"
class MessagePage extends StatelessWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: MessageModule(),
      ),
    );
  }
}
