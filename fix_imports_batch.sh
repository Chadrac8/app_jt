#!/bin/bash

# Liste des fichiers à corriger
files_to_fix=(
"lib/widgets/group_meetings_list.dart"
"lib/widgets/group_member_attendance_stats.dart"
"lib/widgets/home_widget_renderer.dart"
"lib/widgets/event_recurrence_widget.dart"
"lib/widgets/member_view_toggle_button.dart"
"lib/widgets/urgent_diagnostic_banner.dart"
"lib/widgets/team_card.dart"
"lib/widgets/task_list_card.dart"
"lib/widgets/tab_page_builder.dart"
"lib/widgets/task_calendar_view.dart"
"lib/widgets/blog_comments_section.dart"
"lib/widgets/task_card.dart"
"lib/widgets/form_card.dart"
"lib/widgets/song_search_filter_bar.dart"
"lib/widgets/admin_navigation_wrapper.dart"
"lib/widgets/family_info_widget.dart"
"lib/widgets/image_picker_widget.dart"
"lib/widgets/page_card.dart"
"lib/widgets/group_card.dart"
"lib/widgets/form_field_editor.dart"
"lib/widgets/event_form_builder.dart"
"lib/widgets/search_filter_bar.dart"
"lib/widgets/recurring_event_card.dart"
"lib/widgets/image_gallery_widget.dart"
"lib/widgets/media_player_mode_toggle.dart"
"lib/widgets/optimized_form_widgets.dart"
"lib/widgets/service_sheet_editor.dart"
"lib/widgets/song_card.dart"
"lib/widgets/family_widget.dart"
"lib/widgets/appointment_card.dart"
"lib/widgets/workflow_tracker.dart"
"lib/widgets/role_card.dart"
"lib/widgets/prayer_card.dart"
"lib/widgets/availability_editor.dart"
"lib/widgets/setlist_card.dart"
"lib/widgets/admin_view_toggle_button.dart"
"lib/widgets/custom_fields_widget.dart"
"lib/widgets/bottom_navigation_wrapper.dart"
"lib/widgets/latest_sermon_widget.dart"
"lib/widgets/setlist_card_perfect13.dart"
"lib/widgets/service_search_filter_bar.dart"
"lib/widgets/event_card.dart"
"lib/widgets/blog_post_preview_dialog.dart"
"lib/widgets/task_comments_widget.dart"
"lib/widgets/form_statistics_view.dart"
"lib/widgets/custom_tabs_widget.dart"
"lib/widgets/person_card.dart"
"lib/widgets/event_calendar_view.dart"
"lib/widgets/event_registrations_list.dart"
"lib/widgets/blog_post_metadata.dart"
"lib/widgets/task_search_filter_bar.dart"
"lib/widgets/prayer_search_filter_bar.dart"
"lib/widgets/songs_import_export_button.dart"
"lib/widgets/blog_post_card.dart"
"lib/widgets/task_kanban_view.dart"
"lib/widgets/blog_post_actions.dart"
"lib/widgets/dashboard_diagnostic_widget.dart"
"lib/widgets/youtube_picker_widget.dart"
"lib/widgets/media_player_config_widget.dart"
"lib/widgets/event_statistics_view.dart"
"lib/widgets/page_components/component_editor.dart"
"lib/widgets/page_components/component_renderer.dart"
"lib/widgets/sunday_calendar_widget.dart"
"lib/widgets/song_card_perfect13.dart"
"lib/widgets/service_assignments_list.dart"
"lib/widgets/position_card.dart"
"lib/widgets/icon_selector.dart"
"lib/widgets/appointment_statistics_widget.dart"
"lib/widgets/service_card.dart"
"lib/widgets/grid_container_builder.dart"
"lib/widgets/service_calendar_view.dart"
)

echo "Correction des imports AppTheme pour ${#files_to_fix[@]} fichiers..."

for file in "${files_to_fix[@]}"; do
    if [ -f "$file" ]; then
        # Vérifier si le fichier utilise AppTheme mais n'a pas l'import
        if grep -q "AppTheme\." "$file" && ! grep -q "import.*theme\.dart" "$file"; then
            # Ajouter l'import en tête de fichier après les autres imports
            sed -i '' '1,/^import/{ /^import.*$/a\
import '\''../theme.dart'\'';
}' "$file"
            echo "Import ajouté dans: $file"
        fi
    else
        echo "Fichier non trouvé: $file"
    fi
done

echo "Correction terminée!"