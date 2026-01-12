import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String _status = 'new';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.orderId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(children: const [Icon(Icons.person, color: Colors.grey), SizedBox(width: 12), Text('Ahmed B.')]),
                  const SizedBox(height: 8),
                  Row(children: const [Icon(Icons.phone, color: Colors.grey), SizedBox(width: 12), Text('+213 555 123 456')]),
                  const SizedBox(height: 8),
                  Row(children: const [Icon(Icons.location_on, color: Colors.grey), SizedBox(width: 12), Expanded(child: Text('Rue des Frères Bouadou, Bir Mourad Raïs'))]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildItem('Pizza Margherita', 1, 800),
                  _buildItem('Burger Classic', 2, 500),
                  const Divider(),
                  _buildPriceRow('Sous-total', '1,800 DA'),
                  _buildPriceRow('Commission (15%)', '-270 DA'),
                  _buildPriceRow('Net', '1,530 DA', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Statut de la commande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStatusButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String name, int qty, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood, color: Colors.grey, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w500)), Text('$qty x $price DA', style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
          Text('${qty * price} DA', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)), Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFFE65100) : null))]),
    );
  }

  Widget _buildStatusButtons() {
    return Column(
      children: [
        _buildStatusButton('new', 'Nouvelle', Colors.orange, Icons.fiber_new),
        _buildStatusButton('preparing', 'En préparation', Colors.blue, Icons.restaurant),
        _buildStatusButton('ready', 'Prête', Colors.green, Icons.check_circle),
      ],
    );
  }

  Widget _buildStatusButton(String status, String label, Color color, IconData icon) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () => setState(() => _status = status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
        child: Row(children: [Icon(icon, color: isSelected ? color : Colors.grey), const SizedBox(width: 12), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey)), const Spacer(), if (isSelected) Icon(Icons.check, color: color)]),
      ),
    );
  }
}
