import 'package:flutter/material.dart';
import '../theme.dart';

class GiveLifeToJesusPage extends StatelessWidget {
  const GiveLifeToJesusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donner sa vie à Jésus'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.surfaceColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSteps(),
            const SizedBox(height: 24),
            _buildPrayer(),
            const SizedBox(height: 24),
            _buildContact(),
          ])));
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ])),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              size: 60,
              color: AppTheme.surfaceColor),
            const SizedBox(height: 16),
            Text(
              'Un nouveau départ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.surfaceColor)),
            const SizedBox(height: 8),
            Text(
              'Découvrez l\'amour de Dieu et commencez une nouvelle vie avec Jésus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.surfaceColor.withOpacity(0.9))),
          ])));
  }

  Widget _buildSteps() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment donner sa vie à Jésus ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 20),
            
            _buildStep(
              number: '1',
              title: 'Reconnaître',
              description: 'Reconnaissez que vous êtes pécheur et avez besoin de Dieu.',
              verse: '"Car tous ont péché et sont privés de la gloire de Dieu" - Romains 3:23'),
            
            const SizedBox(height: 20),
            
            _buildStep(
              number: '2',
              title: 'Croire',
              description: 'Croyez que Jésus est mort sur la croix pour vos péchés et qu\'Il est ressuscité.',
              verse: '"Car Dieu a tant aimé le monde qu\'il a donné son Fils unique" - Jean 3:16'),
            
            const SizedBox(height: 20),
            
            _buildStep(
              number: '3',
              title: 'Confesser',
              description: 'Confessez Jésus comme votre Seigneur et Sauveur personnel.',
              verse: '"Si tu confesses de ta bouche le Seigneur Jésus... tu seras sauvé" - Romains 10:9'),
            
            const SizedBox(height: 20),
            
            _buildStep(
              number: '4',
              title: 'Vivre',
              description: 'Commencez une nouvelle vie en suivant Jésus et en lisant Sa Parole.',
              verse: '"Si quelqu\'un est en Christ, il est une nouvelle créature" - 2 Corinthiens 5:17'),
          ])));
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required String verse,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.surfaceColor)))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(
                  verse,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.primaryColor))),
            ])),
      ]);
  }

  Widget _buildPrayer() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prière de salut',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            Text(
              'Si vous souhaitez donner votre vie à Jésus, vous pouvez prier cette prière avec sincérité :',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2))),
              child: Text(
                '"Seigneur Jésus, je reconnais que je suis pécheur et que j\'ai besoin de Toi. Je crois que Tu es mort sur la croix pour mes péchés et que Tu es ressuscité. Je Te demande de me pardonner et de venir dans ma vie. Je veux Te suivre et T\'obéir. Merci pour Ton amour et Ton salut. Amen."',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center)),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.celebration, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Félicitations !',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                        const SizedBox(height: 4),
                        Text(
                          'Si vous avez prié cette prière avec sincérité, vous êtes maintenant enfant de Dieu !',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700)),
                      ])),
                ])),
          ])));
  }

  Widget _buildContact() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prochaines étapes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            
            _buildNextStep(
              icon: Icons.menu_book,
              title: 'Lisez la Bible',
              description: 'Commencez par l\'Évangile de Jean pour mieux connaître Jésus'),
            
            _buildNextStep(
              icon: Icons.favorite,
              title: 'Priez régulièrement',
              description: 'Parlez à Dieu chaque jour, Il vous écoute toujours'),
            
            _buildNextStep(
              icon: Icons.church,
              title: 'Rejoignez une église',
              description: 'Trouvez une communauté pour grandir dans la foi'),
            
            _buildNextStep(
              icon: Icons.people,
              title: 'Partagez votre foi',
              description: 'Témoignez de l\'amour de Dieu autour de vous'),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigation vers page de contact ou formulaire
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.contact_support),
                label: const Text(
                  'Nous contacter pour plus d\'aide',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)))),
          ])));
  }

  Widget _buildNextStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor)),
              ])),
        ]));
  }
}
