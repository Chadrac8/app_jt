import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/don_model.dart';
import '../services/dons_service.dart';

class DonFormDialog extends StatefulWidget {
  final Don? don;

  const DonFormDialog({
    Key? key,
    this.don,
  }) : super(key: key);

  @override
  State<DonFormDialog> createState() => _DonFormDialogState();
}

class _DonFormDialogState extends State<DonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _donorNameController = TextEditingController();
  final _donorEmailController = TextEditingController();
  final _customPurposeController = TextEditingController();
  final _messageController = TextEditingController();
  final _transactionIdController = TextEditingController();

  bool _isLoading = false;
  bool _isAnonymous = false;
  bool _isRecurring = false;
  
  DonType _selectedType = DonType.oneTime;
  DonPurpose _selectedPurpose = DonPurpose.general;
  DonStatus _selectedStatus = DonStatus.pending;
  String _selectedCurrency = 'EUR';
  String? _selectedPaymentMethod = 'card';

  @override
  void initState() {
    super.initState();
    if (widget.don != null) {
      _initializeFromDon(widget.don!);
    }
  }

  void _initializeFromDon(Don don) {
    _amountController.text = don.amount.toString();
    _donorNameController.text = don.donorName ?? '';
    _donorEmailController.text = don.donorEmail ?? '';
    _customPurposeController.text = don.customPurpose ?? '';
    _messageController.text = don.message ?? '';
    _transactionIdController.text = don.transactionId ?? '';
    
    _isAnonymous = don.isAnonymous;
    _isRecurring = don.isRecurring;
    _selectedType = DonType.fromValue(don.type);
    _selectedPurpose = DonPurpose.fromValue(don.purpose);
    _selectedStatus = DonStatus.fromValue(don.status);
    _selectedCurrency = don.currency;
    _selectedPaymentMethod = don.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _donorNameController.dispose();
    _donorEmailController.dispose();
    _customPurposeController.dispose();
    _messageController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9 > 600 
            ? 600 
            : MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountSection(),
                      const SizedBox(height: 20),
                      _buildDonorSection(),
                      const SizedBox(height: 20),
                      _buildPurposeSection(),
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                      const SizedBox(height: 20),
                      _buildOptionsSection(),
                      const SizedBox(height: 20),
                      _buildMessageSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.don == null ? 'Nouveau don' : 'Modifier le don',
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
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant du don',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.euro),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Devise',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['EUR', 'USD', 'XOF'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DonType>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: 'Type de don',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: DonType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              if (value == DonType.oneTime) {
                _isRecurring = false;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDonorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du donateur',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Don anonyme'),
          value: _isAnonymous,
          onChanged: (value) {
            setState(() {
              _isAnonymous = value;
              if (value) {
                _donorNameController.clear();
                _donorEmailController.clear();
              }
            });
          },
        ),
        if (!_isAnonymous) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _donorNameController,
            decoration: InputDecoration(
              labelText: 'Nom du donateur',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: !_isAnonymous ? (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir le nom du donateur';
              }
              return null;
            } : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _donorEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email du donateur (optionnel)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email invalide';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectif du don',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DonPurpose>(
          value: _selectedPurpose,
          decoration: InputDecoration(
            labelText: 'Objectif',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: DonPurpose.values.map((purpose) {
            return DropdownMenuItem(
              value: purpose,
              child: Text(purpose.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPurpose = value!;
            });
          },
        ),
        if (_selectedPurpose == DonPurpose.other) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customPurposeController,
            decoration: InputDecoration(
              labelText: 'Objectif personnalisé',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: _selectedPurpose == DonPurpose.other ? (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez préciser l\'objectif';
              }
              return null;
            } : null,
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiement',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          decoration: InputDecoration(
            labelText: 'Méthode de paiement',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: [
            const DropdownMenuItem(value: 'card', child: Text('Carte bancaire')),
            const DropdownMenuItem(value: 'bank_transfer', child: Text('Virement bancaire')),
            const DropdownMenuItem(value: 'cash', child: Text('Espèces')),
            const DropdownMenuItem(value: 'check', child: Text('Chèque')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DonStatus>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: DonStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _transactionIdController,
          decoration: InputDecoration(
            labelText: 'ID de transaction (optionnel)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.receipt),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedType == DonType.monthly || _selectedType == DonType.yearly)
          SwitchListTile(
            title: const Text('Don récurrent'),
            subtitle: const Text('Le don sera renouvelé automatiquement'),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message du donateur (optionnel)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveDon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.don == null ? 'Créer' : 'Modifier'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final don = Don(
        id: widget.don?.id ?? '',
        donorId: 'admin', // TODO: Utiliser l'ID de l'utilisateur connecté
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        type: _selectedType.value,
        purpose: _selectedPurpose.value,
        customPurpose: _selectedPurpose == DonPurpose.other 
            ? _customPurposeController.text 
            : null,
        status: _selectedStatus.value,
        donorName: _isAnonymous ? null : _donorNameController.text,
        donorEmail: _isAnonymous ? null : _donorEmailController.text,
        isAnonymous: _isAnonymous,
        isRecurring: _isRecurring,
        paymentMethod: _selectedPaymentMethod,
        transactionId: _transactionIdController.text.isNotEmpty 
            ? _transactionIdController.text 
            : null,
        message: _messageController.text.isNotEmpty 
            ? _messageController.text 
            : null,
        createdAt: widget.don?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: _selectedStatus.value == 'completed' 
            ? DateTime.now() 
            : widget.don?.processedAt,
        nextPaymentDate: _isRecurring 
            ? DateTime.now().add(const Duration(days: 30)) 
            : null,
      );

      if (widget.don == null) {
        await DonsService.createDon(don);
      } else {
        await DonsService.updateDon(don.id, don.toFirestore());
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.don == null 
              ? 'Don créé avec succès' 
              : 'Don modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
