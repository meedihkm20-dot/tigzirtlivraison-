import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final String? livreurName;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    this.livreurName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _restaurantRating = 5;
  int _livreurRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    final review = await SupabaseService.getOrderReview(widget.orderId);
    if (review != null) {
      setState(() {
        _hasExistingReview = true;
        _restaurantRating = review['restaurant_rating'] ?? 5;
        _livreurRating = review['livreur_rating'] ?? 5;
        _commentController.text = review['comment'] ?? '';
      });
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    
    try {
      final success = await SupabaseService.submitReview(
        orderId: widget.orderId,
        restaurantRating: _restaurantRating,
        livreurRating: _livreurRating,
        comment: _commentController.text.isEmpty ? null : _commentController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre avis!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasExistingReview ? 'Modifier mon avis' : 'Donner mon avis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant rating
            _buildRatingSection(
              icon: Icons.restaurant,
              title: widget.restaurantName,
              subtitle: 'Comment était la nourriture?',
              rating: _restaurantRating,
              onRatingChanged: (r) => setState(() => _restaurantRating = r),
            ),
            
            const SizedBox(height: 32),
            
            // Livreur rating
            if (widget.livreurName != null)
              _buildRatingSection(
                icon: Icons.delivery_dining,
                title: widget.livreurName!,
                subtitle: 'Comment était la livraison?',
                rating: _livreurRating,
                onRatingChanged: (r) => setState(() => _livreurRating = r),
              ),
            
            const SizedBox(height: 32),
            
            // Comment
            const Text('Commentaire (optionnel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _hasExistingReview ? 'Modifier mon avis' : 'Envoyer mon avis',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required int rating,
    required Function(int) onRatingChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    starIndex <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(rating),
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Très mauvais';
      case 2: return 'Mauvais';
      case 3: return 'Moyen';
      case 4: return 'Bien';
      case 5: return 'Excellent!';
      default: return '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
