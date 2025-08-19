import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../vie_eglise/widgets/benevolat_tab.dart';

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
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Bénévolat',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: const BenevolatTab(),
    );
  }
}
