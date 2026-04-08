import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';
import 'categories_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keskin Hafriyat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
            },
            tooltip: 'Asistan',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
            },
            tooltip: 'Kategoriler',
          )
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMonthSelector(context, provider),
                      const SizedBox(height: 16),
                      _buildBalanceCard(context, provider, currencyFormat),
                      const SizedBox(height: 24),
                      Text(
                        'Bu Ayki İşlemler',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = provider.transactions[index];
                    final category = provider.getCategoryById(transaction.categoryId);
                    final isIncome = transaction.type == 'income';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      color: AppTheme.surfaceColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? AppTheme.incomeColor.withAlpha(50) : AppTheme.expenseColor.withAlpha(50),
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                          ),
                        ),
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.date) + (transaction.description.isNotEmpty ? ' - ${transaction.description}' : '')),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                          ),
                        ),
                        onLongPress: () {
                          _showDeleteDialog(context, provider, transaction.id!);
                        },
                      ),
                    );
                  },
                  childCount: provider.transactions.length, // O aya ait tüm işlemler gösterilir
                ),
              ),
              // Eğer o ay işlem yoksa
              if (provider.transactions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Bu ay için henüz bir işlem kaydedilmiş değil.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTransactionOptions(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, AppProvider provider) {
    String monthName = DateFormat('MMMM yyyy', 'tr_TR').format(provider.selectedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: provider.previousMonth,
        ),
        Text(
          monthName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
          onPressed: provider.nextMonth,
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppProvider provider, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(75), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        children: [
          const Text('Aylık Toplam Bakiye', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(provider.balance),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseStat(
                context, 
                'Gelir', 
                currencyFormat.format(provider.totalIncome), 
                Icons.arrow_downward, 
                AppTheme.incomeColor
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildIncomeExpenseStat(
                context, 
                'Gider', 
                currencyFormat.format(provider.totalExpense), 
                Icons.arrow_upward, 
                AppTheme.expenseColor
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseStat(BuildContext context, String title, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ],
        )
      ],
    );
  }

  void _showAddTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAddOptionButton(
                    context, 
                    'Gelir Ekle', 
                    Icons.trending_up, 
                    AppTheme.incomeColor, 
                    'income'
                  ),
                  _buildAddOptionButton(
                    context, 
                    'Gider Ekle', 
                    Icons.trending_down, 
                    AppTheme.expenseColor, 
                    'expense'
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOptionButton(BuildContext context, String title, IconData icon, Color color, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(type: type)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          border: Border.all(color: color.withAlpha(125)),
          borderRadius: BorderRadius.circular(16)
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('İşlemi Sil'),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.expenseColor)),
          ),
        ],
      )
    );
  }
}
