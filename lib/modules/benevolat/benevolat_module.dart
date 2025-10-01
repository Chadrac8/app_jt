import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../vie_eglise/widgets/benevolat_tab.dart';
import '../../../theme.dart';

class BenevolatModule extends StatelessWidget {
  const BenevolatModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.volunteer_activism,
              color: AppTheme.blueStandard,
              size: 28,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              'Bénévolat',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.grey800,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.white100,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.grey800),
      ),
      body: const BenevolatTab(),
    );
  }
}
