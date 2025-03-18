import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'finance_provider.dart';
import 'finance_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  // String _selectedType = 'Expense';
  Category? _editingCategory;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingCategory == null ? 'Add Category' : 'Edit Category'),
        actions: [
          if (_editingCategory == null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCategoryDialog(context, provider),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category.name),
            // subtitle: Text(category.type),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCategoryDialog(context, provider, category: category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => provider.deleteCategory(category.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, FinanceProvider provider, {Category? category}) {
    _editingCategory = category;
    if (category != null) {
      _nameController.text = category.name;
      // _selectedType = category.type;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                  validator: (value) => value!.isEmpty ? 'Enter category name' : null,
                ),
                // DropdownButtonFormField<String>(
                //   value: _selectedType,
                //   items: ['Income', 'Expense']
                //       .map((type) => DropdownMenuItem(
                //             value: type,
                //             child: Text(type),
                //           ))
                //       .toList(),
                //   onChanged: (value) => setState(() => _selectedType = value!),
                // ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final newCategory = Category(
                          id: category?.id ?? DateTime.now().toString(),
                          name: _nameController.text,
                          // type: _selectedType,
                          userId: user.uid,
                        );

                        if (_editingCategory == null) {
                          provider.addCategory(newCategory);
                        } else {
                          provider.updateCategory(newCategory);
                        }

                        Navigator.pop(context);
                        _nameController.clear();
                        _editingCategory = null;
                      }
                    }
                  },
                  child: Text(_editingCategory == null ? 'Add Category' : 'Update Category'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}