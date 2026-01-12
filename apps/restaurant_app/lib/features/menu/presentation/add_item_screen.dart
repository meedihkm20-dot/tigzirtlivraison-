import 'package:flutter/material.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Pizzas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un article')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey), SizedBox(height: 8), Text('Ajouter une photo', style: TextStyle(color: Colors.grey))]),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(decoration: const InputDecoration(labelText: 'Nom de l\'article', prefixIcon: Icon(Icons.fastfood)), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Prix (DA)', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                items: ['Pizzas', 'Burgers', 'Boissons', 'Desserts'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context); }, child: const Text('Ajouter l\'article')),
            ],
          ),
        ),
      ),
    );
  }
}
