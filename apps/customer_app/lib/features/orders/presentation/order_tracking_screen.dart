import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/osm_map.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Positions simulées (Alger)
    const livreurPos = LatLng(36.7550, 3.0550);
    const restaurantPos = LatLng(36.7520, 3.0420);
    const clientPos = LatLng(36.7600, 3.0700);

    return Scaffold(
      appBar: AppBar(title: Text('Commande #$orderId')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: OsmMap(
                center: livreurPos,
                zoom: 14,
                markers: [
                  MapMarkers.livreur(livreurPos),
                  MapMarkers.restaurant(restaurantPos),
                  MapMarkers.destination(clientPos),
                ],
                polylines: [
                  Polyline(points: [restaurantPos, livreurPos, clientPos], color: const Color(0xFFFF6B35), strokeWidth: 3),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statut de la commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatusStep('Commande confirmée', 'Votre commande a été reçue', true, true),
                  _buildStatusStep('En préparation', 'Le restaurant prépare votre commande', true, true),
                  _buildStatusStep('En livraison', 'Le livreur est en route', true, false),
                  _buildStatusStep('Livrée', 'Commande livrée', false, false),
                  const SizedBox(height: 16),
                  _buildLivreurCard(),
                  const SizedBox(height: 16),
                  _buildOrderDetails(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, String subtitle, bool isCompleted, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? const Color(0xFFFF6B35) : Colors.grey[300]),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            if (title != 'Livrée') Container(width: 2, height: 40, color: isActive ? const Color(0xFFFF6B35) : Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.black : Colors.grey)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivreurCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFF2E7D32), child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Karim M.', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('⭐ 4.8 • En route vers vous', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.phone, color: Color(0xFFFF6B35)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.message, color: Color(0xFFFF6B35)), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détails', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRow('Pizza Margherita', '1', '800 DA'),
          _buildRow('Burger Classic', '2', '1000 DA'),
          const Divider(),
          _buildRow('Sous-total', '', '1800 DA'),
          _buildRow('Livraison', '', '200 DA'),
          _buildRow('Total', '', '2000 DA', isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String qty, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(qty.isNotEmpty ? '$qty x $label' : label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFFFF6B35) : null)),
        ],
      ),
    );
  }
}
