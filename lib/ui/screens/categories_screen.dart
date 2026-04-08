import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/category_model.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategorileri Yönet'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Gider Kategorileri'),
              Tab(text: 'Gelir Kategorileri'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: 'expense'),
            _CategoryList(type: 'income'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    String typeStr = 'expense';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Yeni Kategori Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Kategori Adı'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: typeStr,
                    decoration: const InputDecoration(labelText: 'Türü'),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Gider')),
                      DropdownMenuItem(value: 'income', child: Text('Gelir')),
                    ],
                    onChanged: (v) => setState(() => typeStr = v!),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final cat = CategoryModel(name: nameController.text.trim(), type: typeStr);
                      context.read<AppProvider>().addCategory(cat);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Ekle', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String type;
  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppProvider>().categories.where((c) => c.type == type).toList();
    final color = type == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor;

    if (categories.isEmpty) {
      return const Center(child: Text('Kategori bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          color: AppTheme.surfaceColor,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(type == 'income' ? Icons.trending_up : Icons.trending_down, color: color),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white54),
              onPressed: () => _deleteCategory(context, cat.id!),
            ),
          ),
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, int id) {
    try {
      context.read<AppProvider>().deleteCategory(id).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red)
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    }
  }
}
