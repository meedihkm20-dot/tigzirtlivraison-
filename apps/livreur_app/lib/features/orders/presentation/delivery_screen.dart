import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _currentStep = 0;
  final List<String> _steps = ['Récupération', 'En route', 'Arrivé', 'Livré'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livraison en cours')),
      body: Column(
        children: [
          Container(
            height: 250,
            color: Colors.grey[200],
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 80, color: Colors.grey), Text('Carte de navigation', style: TextStyle(color: Colors.grey))])),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_steps.length, (i) => _buildStepIndicator(i)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      children: [
                        Row(children: [const Icon(Icons.person, color: Color(0xFF2E7D32)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ahmed B.', style: TextStyle(fontWeight: FontWeight.bold)), Text('+213 555 123 456', style: TextStyle(color: Colors.grey))])), IconButton(icon: const Icon(Icons.phone, color: Color(0xFF2E7D32)), onPressed: () {})]),
                        const Divider(),
                        Row(children: const [Icon(Icons.location_on, color: Colors.grey), SizedBox(width: 12), Expanded(child: Text('Rue des Frères Bouadou, Bir Mourad Raïs', style: TextStyle(color: Colors.grey)))]),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          _showDeliveryComplete(context);
                        }
                      },
                      child: Text(_currentStep < _steps.length - 1 ? 'Étape suivante: ${_steps[_currentStep + 1]}' : 'Confirmer la livraison'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final isCompleted = index <= _currentStep;
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300]),
          child: Icon(isCompleted ? Icons.check : Icons.circle, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(_steps[index], style: TextStyle(fontSize: 10, color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey)),
      ],
    );
  }

  void _showDeliveryComplete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Livraison terminée!'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 80), SizedBox(height: 16), Text('Vous avez gagné 200 DA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        actions: [ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false), child: const Text('Retour à l\'accueil'))],
      ),
    );
  }
}
