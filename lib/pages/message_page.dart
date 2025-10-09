import 'package:flutter/material.dart';
import '../modules/message/message_module.dart';

/// Page d'accès au module "Le Message"
class MessagePage extends StatelessWidget {
  final TabController? tabController; // MD3: TabController fourni par le wrapper
  
  const MessagePage({Key? key, this.tabController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MessageModule(tabController: tabController),
      ),
    );
  }
}
