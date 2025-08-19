import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../models/don_model.dart';
import '../services/dons_service.dart';

class DonDetailsDialog extends StatelessWidget {
  final Don don;

  const DonDetailsDialog({
    Key? key,
    required this.don,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = DonStatus.fromValue(don.status);
    final purpose = DonPurpose.fromValue(don.purpose);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9 > 500 
            ? 500 
            : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Détails du don',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Donateur', don.isAnonymous ? 'Anonyme' : (don.donorName ?? 'Inconnu')),
            if (!don.isAnonymous && don.donorEmail != null)
              _buildDetailRow('Email', don.donorEmail!),
            _buildDetailRow('Montant', NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(don.amount)),
            _buildDetailRow('Devise', don.currency),
            _buildDetailRow('Type', DonType.fromValue(don.type).label),
            _buildDetailRow('Objectif', purpose.label),
            if (don.customPurpose != null)
              _buildDetailRow('Objectif personnalisé', don.customPurpose!),
            _buildDetailRow('Statut', status.label, statusColor: _getStatusColor(status)),
            if (don.paymentMethod != null)
              _buildDetailRow('Méthode de paiement', _getPaymentMethodLabel(don.paymentMethod!)),
            if (don.transactionId != null)
              _buildDetailRow('ID transaction', don.transactionId!),
            _buildDetailRow('Date de création', DateFormat('dd/MM/yyyy à HH:mm').format(don.createdAt)),
            if (don.processedAt != null)
              _buildDetailRow('Date de traitement', DateFormat('dd/MM/yyyy à HH:mm').format(don.processedAt!)),
            if (don.isRecurring) ...[
              _buildDetailRow('Don récurrent', 'Oui'),
              if (don.nextPaymentDate != null)
                _buildDetailRow('Prochain paiement', DateFormat('dd/MM/yyyy').format(don.nextPaymentDate!)),
            ],
            if (don.message != null && don.message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Message du donateur :',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  don.message!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor ?? AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (don.status == 'pending') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _processDon(context),
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _cancelDon(context),
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(DonStatus status) {
    switch (status.value) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'Carte bancaire';
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'cash':
        return 'Espèces';
      case 'check':
        return 'Chèque';
      default:
        return method;
    }
  }

  void _processDon(BuildContext context) async {
    try {
      await DonsService.processDon(don.id, 'admin'); // TODO: Utiliser l'ID de l'admin connecté
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Don validé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelDon(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce don ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DonsService.cancelDon(don.id, 'admin'); // TODO: Utiliser l'ID de l'admin connecté
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Don annulé avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
