import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../models/don_model.dart';
import '../services/dons_service.dart';
import '../widgets/don_form_dialog.dart';
import '../widgets/don_details_dialog.dart';
import '../widgets/dons_statistics_widget.dart';

class DonsAdminView extends StatefulWidget {
  const DonsAdminView({Key? key}) : super(key: key);

  @override
  State<DonsAdminView> createState() => _DonsAdminViewState();
}

class _DonsAdminViewState extends State<DonsAdminView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedPurpose = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Administration - Dons',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.list, size: 20),
              text: 'Liste des dons',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: 20),
              text: 'Statistiques',
            ),
            Tab(
              icon: Icon(Icons.settings, size: 20),
              text: 'Configuration',
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonsList(),
          _buildStatistics(),
          _buildConfiguration(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showDonForm(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDonsList() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<Don>>(
            stream: DonsService.getAllDonsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorWidget();
              }

              List<Don> dons = snapshot.data ?? [];

              // Appliquer les filtres
              dons = _applyFilters(dons);

              if (dons.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dons.length,
                itemBuilder: (context, index) {
                  return _buildDonCard(dons[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tous')),
                    ...DonStatus.values.map((status) => DropdownMenuItem(
                          value: status.value,
                          child: Text(status.label),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPurpose,
                  decoration: InputDecoration(
                    labelText: 'Objectif',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tous')),
                    ...DonPurpose.values.map((purpose) => DropdownMenuItem(
                          value: purpose.value,
                          child: Text(purpose.label),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedPurpose = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Don> _applyFilters(List<Don> dons) {
    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      dons = dons.where((don) {
        return (don.donorName?.toLowerCase().contains(query) ?? false) ||
               (don.donorEmail?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtre par statut
    if (_selectedStatus != 'all') {
      dons = dons.where((don) => don.status == _selectedStatus).toList();
    }

    // Filtre par objectif
    if (_selectedPurpose != 'all') {
      dons = dons.where((don) => don.purpose == _selectedPurpose).toList();
    }

    return dons;
  }

  Widget _buildDonCard(Don don) {
    final status = DonStatus.fromValue(don.status);
    final purpose = DonPurpose.fromValue(don.purpose);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDonDetails(don),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      don.isAnonymous ? 'Don anonyme' : (don.donorName ?? 'Inconnu'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.euro, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(don.amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(don.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    purpose.label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (don.isRecurring) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.repeat, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Récurrent',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (don.message != null && don.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    don.message!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return const DonsStatisticsWidget();
  }

  Widget _buildConfiguration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration du module Dons',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres généraux',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Accepter les dons anonymes'),
                    subtitle: const Text('Permettre aux membres de faire des dons anonymes'),
                    value: true,
                    onChanged: (value) {
                      // TODO: Implémenter la logique de configuration
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Dons récurrents'),
                    subtitle: const Text('Autoriser les dons mensuels et annuels'),
                    value: true,
                    onChanged: (value) {
                      // TODO: Implémenter la logique de configuration
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Messages des donateurs'),
                    subtitle: const Text('Permettre aux donateurs d\'ajouter un message'),
                    value: true,
                    onChanged: (value) {
                      // TODO: Implémenter la logique de configuration
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objectifs de dons',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gérez les objectifs disponibles pour les dons',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Ouvrir le gestionnaire d'objectifs
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Gérer les objectifs'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun don trouvé',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les dons apparaîtront ici une fois créés',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
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

  void _showDonForm({Don? don}) {
    showDialog(
      context: context,
      builder: (context) => DonFormDialog(don: don),
    ).then((result) {
      if (result == true) {
        setState(() {}); // Refresh the list
      }
    });
  }

  void _showDonDetails(Don don) {
    showDialog(
      context: context,
      builder: (context) => DonDetailsDialog(don: don),
    );
  }
}
