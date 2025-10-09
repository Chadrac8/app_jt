import 'package:flutter/material.dart';
import 'bible_page.dart';

class BibleModulePage extends StatelessWidget {
  final TabController? tabController; // MD3: TabController fourni par le wrapper
  
  const BibleModulePage({Key? key, this.tabController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BiblePage(tabController: tabController);
  }
}
