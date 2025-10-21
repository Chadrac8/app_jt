import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';

class TaskSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final List<String> selectedStatusFilters;
  final List<String> selectedPriorityFilters;
  final Function(List<String>, List<String>, DateTime?, DateTime?) onFiltersChanged;

  const TaskSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedStatusFilters,
    required this.selectedPriorityFilters,
    required this.onFiltersChanged,
  });

  @override
  State<TaskSearchFilterBar> createState() => _TaskSearchFilterBarState();
}

class _TaskSearchFilterBarState extends State<TaskSearchFilterBar> {
  bool _showFilters = false;
  
  final List<String> _allStatuses = ['todo', 'in_progress', 'completed'];
  final List<String> _allPriorities = ['low', 'medium', 'high'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.searchController,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher des tâches...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.grey500),
                  prefixIcon: Icon(Icons.search, color: AppTheme.grey500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: const BorderSide(color: AppTheme.blueStandard),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(
                Icons.filter_list,
                color: _showFilters ? AppTheme.blueStandard : AppTheme.grey500,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _showFilters ? AppTheme.blueStandard.withOpacity(0.1) : AppTheme.grey100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: AppTheme.space12),
          _buildFiltersSection(),
        ],
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildStatusFilters(),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildPriorityFilters(),
          const SizedBox(height: AppTheme.spaceMedium),
          Row(
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Effacer',
                  style: GoogleFonts.poppins(color: AppTheme.grey600),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueStandard,
                  foregroundColor: AppTheme.white100,
                ),
                child: Text(
                  'Appliquer',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.grey700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Wrap(
          spacing: 8,
          children: _allStatuses.map((status) {
            final isSelected = widget.selectedStatusFilters.contains(status);
            return FilterChip(
              label: Text(_getStatusLabel(status)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.selectedStatusFilters.add(status);
                  } else {
                    widget.selectedStatusFilters.remove(status);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriorityFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priorité',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.grey700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Wrap(
          spacing: 8,
          children: _allPriorities.map((priority) {
            final isSelected = widget.selectedPriorityFilters.contains(priority);
            return FilterChip(
              label: Text(_getPriorityLabel(priority)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.selectedPriorityFilters.add(priority);
                  } else {
                    widget.selectedPriorityFilters.remove(priority);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Faible';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Élevée';
      default:
        return priority;
    }
  }

  void _clearFilters() {
    setState(() {
      widget.selectedStatusFilters.clear();
      widget.selectedPriorityFilters.clear();
    });
    _applyFilters();
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      widget.selectedStatusFilters,
      widget.selectedPriorityFilters,
      null, // dueAfter
      null, // dueBefore
    );
  }
}
