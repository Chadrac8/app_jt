import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(
                Icons.filter_list,
                color: _showFilters ? Colors.blue : Colors.grey[500],
              ),
              style: IconButton.styleFrom(
                backgroundColor: _showFilters ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 12),
          _buildFiltersSection(),
        ],
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusFilters(),
          const SizedBox(height: 16),
          _buildPriorityFilters(),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Effacer',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
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
