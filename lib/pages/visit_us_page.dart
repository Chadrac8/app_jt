import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:url_launcher/url_launcher.dart';

class VisitUsPage extends StatelessWidget {
  const VisitUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nous visiter'),
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                child: Image.asset(
                  'assets/logo_jt.png',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              Text(
                'Bienvenue à Jubilé Tabernacle',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Nous sommes une assemblée chrétienne interdénominationnelle et ouverte à tous. Que vous soyez déjà croyant, en recherche spirituelle ou simplement curieux, vous êtes le bienvenu !',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              _buildSectionTitle(context, 'Informations pratiques'),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildInfoRow(
                context,
                icon: Icons.location_on_rounded,
                title: 'Adresse',
                subtitle: '124 bis rue de l’Épidème\n59200 Tourcoing',
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildInfoRow(
                context,
                icon: Icons.calendar_month_rounded,
                title: 'Horaires des cultes',
                subtitle: 'Dimanche : 10h00\nMercredi : 19h00',
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildInfoRow(
                context,
                icon: Icons.phone_rounded,
                title: 'Contact',
                subtitle: '+33 6 77 45 72 78',
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              _buildSectionTitle(context, 'À quoi s’attendre ?'),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildExpectationList(context),
              const SizedBox(height: AppTheme.spaceXLarge),
              _buildSectionTitle(context, 'Plan d’accès'),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildMapCard(context),
              const SizedBox(height: AppTheme.spaceXLarge),
              _buildSectionTitle(context, 'Questions fréquentes'),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildFAQ(context),
              const SizedBox(height: AppTheme.spaceXLarge),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Open maps with church address
                    const address = '123 Rue de l\'\u00c9glise, Paris';
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
                    try {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Impossible d\'ouvrir Maps')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Obtenir l’itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: AppTheme.fontBold,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: AppTheme.fontBold)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpectationList(BuildContext context) {
    final items = [
      {
        'icon': Icons.people_alt_rounded,
        'text': 'Accueil chaleureux et inclusif',
      },
      {
        'icon': Icons.music_note_rounded,
        'text': 'Moments de louange et d\'adoration',
      },
      {
        'icon': Icons.menu_book_rounded,
        'text': 'Prédication biblique',
      },
      {
        'icon': Icons.coffee_rounded,
        'text': 'Moment convivial après le culte',
      },
      {
        'icon': Icons.child_care_rounded,
        'text': 'Ecole du dimanche pour les enfants',
      },
    ];
    return Column(
      children: items.map((item) => ListTile(
        leading: Icon(item['icon'] as IconData, color: Theme.of(context).colorScheme.primary),
        title: Text(item['text'] as String, style: Theme.of(context).textTheme.bodyLarge),
      )).toList(),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          children: [
            // Google Maps Static API preview
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              child: Image.network(
                'https://maps.googleapis.com/maps/api/staticmap?center=124+bis+rue+de+l%E2%80%99%C3%89pid%C3%A8me,59200+Tourcoing,France&zoom=16&size=600x220&markers=color:blue%7C124+bis+rue+de+l%E2%80%99%C3%89pid%C3%A8me,59200+Tourcoing,France&key=YOUR_API_KEY',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.map_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=124+bis+rue+de+l%E2%80%99%C3%89pid%C3%A8me,59200+Tourcoing,France');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(BuildContext context) {
    final faqs = [
      {
        'q': 'Dois-je m’inscrire avant de venir ?',
        'a': 'Non, l’entrée est libre et ouverte à tous. Vous pouvez venir spontanément.'
      },
      {
        'q': 'Comment s’habiller ?',
        'a': 'Venez comme vous êtes ! Il n’y a pas de code vestimentaire imposé.'
      },
      {
        'q': 'Y a-t-il un accueil pour les enfants ?',
        'a': 'Oui, un espace dédié et des activités adaptées sont proposés pour les enfants.'
      },
      {
        'q': 'Puis-je poser des questions ou rencontrer un responsable ?',
        'a': 'Bien sûr ! Après le culte, l’équipe pastorale est disponible pour échanger.'
      },
      {
        'q': 'L’église est-elle accessible aux personnes à mobilité réduite ?',
        'a': 'Oui, l’accès est adapté et nous veillons à accueillir chacun dans les meilleures conditions.'
      },
    ];
    return Column(
      children: faqs.map((faq) => ExpansionTile(
        title: Text(faq['q']!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: AppTheme.fontSemiBold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Text(faq['a']!, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      )).toList(),
    );
  }
}
