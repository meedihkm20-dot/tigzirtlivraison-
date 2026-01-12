import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Menu')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addItem),
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory('Pizzas', [
            _buildMenuItem('Pizza Margherita', '800 DA', true),
            _buildMenuItem('Pizza 4 Fromages', '1000 DA', true),
            _buildMenuItem('Pizza Végétarienne', '900 DA', false),
          ]),
          _buildCategory('Burgers', [
            _buildMenuItem('Burger Classic', '500 DA', true),
            _buildMenuItem('Burger Double', '700 DA', true),
            _buildMenuItem('Burger Chicken', '550 DA', true),
          ]),
          _buildCategory('Boissons', [
            _buildMenuItem('Coca Cola', '150 DA', true),
            _buildMenuItem('Fanta', '150 DA', true),
            _buildMenuItem('Eau minérale', '80 DA', true),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategory(String name, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...items,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem(String name, String price, bool available) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
      child: Row(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(color: Color(0xFFE65100))),
              ],
            ),
          ),
          Switch(value: available, onChanged: (v) {}, activeColor: Colors.green),
        ],
      ),
    );
  }
}
