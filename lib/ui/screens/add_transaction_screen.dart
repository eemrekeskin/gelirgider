import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/transaction_model.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // 'income' or 'expense'

  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (amount <= 0) return;

      final transaction = TransactionModel(
        amount: amount,
        categoryId: _selectedCategoryId!,
        description: _descController.text,
        date: _selectedDate,
        type: widget.type,
      );

      context.read<AppProvider>().addTransaction(transaction);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İşlem başarıyla eklendi.'),
          backgroundColor: widget.type == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor,
        )
      );
    } else if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin!'), backgroundColor: Colors.orange)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';
    final themeColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final title = isIncome ? 'Gelir Ekle' : 'Gider Ekle';

    final categories = context.watch<AppProvider>().categories.where((c) => c.type == widget.type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor.withOpacity(0.1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: themeColor),
                decoration: InputDecoration(
                  labelText: 'Tutar (₺)',
                  labelStyle: TextStyle(color: themeColor),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.currency_lira, color: themeColor, size: 32),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Gerekli';
                  if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz tutar';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                hint: const Text('Kategori Seçin'),
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategoryId = val);
                },
                validator: (val) => val == null ? 'Gerekli' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  prefixIcon: Icon(Icons.description),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: themeColor,
                            onPrimary: Colors.white,
                            surface: AppTheme.surfaceColor,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
