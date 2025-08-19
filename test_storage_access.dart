import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Test simple pour vérifier l'accès aux images Firebase Storage
/// Exécuter ce test après avoir déployé les nouvelles règles storage
class StorageAccessTest extends StatelessWidget {
  const StorageAccessTest({super.key});

  // URLs d'exemple des images qui posaient problème
  static const List<String> testImageUrls = [
    'https://firebasestorage.googleapis.com/v0/b/hjye25u8iwm0i0zls78urffsc0jcgj.firebasestorage.app/o/resources%2Fresource_5EpZ0VofFjLrEeKl9083_1752535595627.jpg?alt=media&token=04b4dc1d-3a84-4790-b88c-49a4deaa57bd',
    'https://firebasestorage.googleapis.com/v0/b/hjye25u8iwm0i0zls78urffsc0jcgj.firebasestorage.app/o/resources%2Fresource_N0MmGwcQeFbyxmmdyV97_1752535946419.jpg?alt=media&token=18873ff7-2e2a-4ddc-8d3f-a2e5ece0efde',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test d\'accès Firebase Storage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test d\'accès aux images Firebase Storage',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Les images ci-dessous devraient se charger sans erreur 403:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: testImageUrls.length,
                itemBuilder: (context, index) {
                  return _buildImageTestCard(context, index, testImageUrls[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTestCard(BuildContext context, int index, String imageUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${imageUrl.substring(0, 100)}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Chargement...'),
                        ],
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.red[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.red[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Si cette image se charge correctement, les règles Firebase Storage fonctionnent !',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
