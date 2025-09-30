import 'package:flutter/material.dart';
import '../../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class OffrandesAdminView extends StatefulWidget {
  const OffrandesAdminView({super.key});

  @override
  State<OffrandesAdminView> createState() => _OffrandesAdminViewState();
}

class _OffrandesAdminViewState extends State<OffrandesAdminView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _donorController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'offrande';
  String _selectedMethod = 'especes';

  @override
  void dispose() {
    _amountController.dispose();
    _donorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gestion des Offrandes',
          style: GoogleFonts.inter(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.white100,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        foregroundColor: AppTheme.white100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 32),
            _buildDonationForm(),
            const SizedBox(height: 32),
            _buildRecentDonations(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.greenStandard.withOpacity(0.1),
            AppTheme.greenStandard.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.greenStandard.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.volunteer_activism,
              color: AppTheme.greenStandard,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Offrandes',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enregistrez et suivez les dons et offrandes de l\'église',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total du mois',
            '€ 2,450',
            Icons.trending_up,
            AppTheme.greenStandard,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Nombre de dons',
            '47',
            Icons.people,
            AppTheme.blueStandard,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Moyenne',
            '€ 52',
            Icons.analytics,
            AppTheme.orangeStandard,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enregistrer un don',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    'Type de don',
                    _selectedType,
                    ['offrande', 'dime', 'mission', 'construction'],
                    (value) => setState(() => _selectedType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    'Méthode',
                    _selectedMethod,
                    ['especes', 'cheque', 'virement', 'carte'],
                    (value) => setState(() => _selectedMethod = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Montant (€)',
              _amountController,
              TextInputType.number,
              'Entrez le montant',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Donateur (optionnel)',
              _donorController,
              TextInputType.name,
              'Nom du donateur',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Notes (optionnel)',
              _notesController,
              TextInputType.multiline,
              'Notes ou commentaires',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenStandard,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  'Enregistrer le don',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.textTertiaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.textTertiaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(_getDisplayName(item)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.textTertiaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.textTertiaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          validator: keyboardType == TextInputType.number 
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                if (double.tryParse(value) == null) {
                  return 'Veuillez entrer un montant valide';
                }
                return null;
              }
            : null,
        ),
      ],
    );
  }

  Widget _buildRecentDonations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dons récents',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Naviguer vers la liste complète
                },
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDonationItem('Offrande', '€ 50', 'Espèces', 'Aujourd\'hui'),
          _buildDonationItem('Dîme', '€ 120', 'Virement', 'Hier'),
          _buildDonationItem('Mission', '€ 200', 'Chèque', '2 jours'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.greenStandard.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.greenStandard, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les dons anonymes sont acceptés. Seuls les montants sont enregistrés.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.greenStandard,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationItem(String type, String amount, String method, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.volunteer_activism,
              color: AppTheme.greenStandard,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  method,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.greenStandard,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String value) {
    switch (value) {
      case 'offrande': return 'Offrande';
      case 'dime': return 'Dîme';
      case 'mission': return 'Mission';
      case 'construction': return 'Construction';
      case 'especes': return 'Espèces';
      case 'cheque': return 'Chèque';
      case 'virement': return 'Virement';
      case 'carte': return 'Carte bancaire';
      default: return value;
    }
  }

  void _submitDonation() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implémenter la logique de sauvegarde
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Don de ${_amountController.text}€ enregistré avec succès'),
          backgroundColor: AppTheme.greenStandard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      
      // Réinitialiser le formulaire
      _formKey.currentState!.reset();
      _amountController.clear();
      _donorController.clear();
      _notesController.clear();
      setState(() {
        _selectedType = 'offrande';
        _selectedMethod = 'especes';
      });
    }
  }
}