import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';

class AppProvider with ChangeNotifier {
  List<CategoryModel> categories = [];
  List<TransactionModel> _allTransactions = [];

  DateTime selectedMonth = DateTime.now();

  // Sadece seçili aya ait işlemleri getir (Ana ekran için)
  List<TransactionModel> get transactions {
    return _allTransactions.where((t) => 
      t.date.year == selectedMonth.year && t.date.month == selectedMonth.month
    ).toList();
  }

  double get totalIncome {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  AppProvider() {
    loadData();
  }

  void previousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    notifyListeners();
  }

  Future<void> loadData() async {
    categories = await DatabaseHelper.instance.readAllCategories();
    _allTransactions = await DatabaseHelper.instance.readAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadData();
  }

  Future<void> addCategory(CategoryModel category) async {
    await DatabaseHelper.instance.createCategory(category);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    final isUsed = _allTransactions.any((t) => t.categoryId == id);
    if (!isUsed) {
      await DatabaseHelper.instance.deleteCategory(id);
      await loadData();
    } else {
      throw Exception('Bu kategori geçmiş işlemlerde kullanıldığı için silinemez.');
    }
  }

  CategoryModel getCategoryById(int id) {
    return categories.firstWhere((c) => c.id == id, orElse: () => CategoryModel(name: 'Bilinmeyen', type: 'expense'));
  }

  // --- Asistan (Chatbot) Mantığı Yeni Format ---
  String getBotResponse(String query, {required bool isMonthly}) {
    if (_allTransactions.isEmpty) return "Sistemde henüz işlem bulunmuyor. Öncelikle uygulamanın ana ekranından harcama/gelir eklemelisiniz.";

    final targetTransactions = isMonthly
        ? _allTransactions.where((t) => t.date.year == selectedMonth.year && t.date.month == selectedMonth.month).toList()
        : _allTransactions.where((t) => t.date.year == selectedMonth.year).toList();

    final String periyotAd = isMonthly
        ? "Seçili ayınız ${DateFormat('MMMM yyyy', 'tr_TR').format(selectedMonth)}"
        : "Seçili yılınız ${selectedMonth.year}";

    if (targetTransactions.isEmpty) {
      return "$periyotAd için incelenecek herhangi bir hareket bulunamadı. Lütfen ilgili dönemlere kayıt girin.";
    }

    if (query == 'Durum Özeti') {
      final tIncome = targetTransactions.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
      final tExpense = targetTransactions.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
      final tBal = tIncome - tExpense;
      final balColor = tBal >= 0 ? '<g>' : '<r>';
      
      return "$periyotAd boyunca Keskin Hafriyat hesabınızın detaylı durum özeti şöyledir:\n\n"
             "• Yekün Gelirler: <g>+${tIncome.toStringAsFixed(2)} ₺</g>\n"
             "• Yekün Giderler: <r>-${tExpense.toStringAsFixed(2)} ₺</r>\n"
             "• Net Kalan Bakiye: $balColor${tBal.toStringAsFixed(2)} ₺${tBal >= 0 ? '</g>' : '</r>'}\n\n"
             "Bu hesaplamalar şirketinizin sağlıklı büyümesini takip edebilmeniz adına son derece önemlidir.";
    }
    
    else if (query == 'En Büyük Gider') {
      final expenses = targetTransactions.where((t) => t.type == 'expense').toList();
      if (expenses.isEmpty) return "Seçilen periyotta herhangi bir masraf bulunamadı.";
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      final maxExp = expenses.first;
      final cat = getCategoryById(maxExp.categoryId).name;
      final desc = maxExp.description.isNotEmpty ? maxExp.description : 'Açıklama belirtilmemiş';
      
      return "İncelediğimiz periyot ($periyotAd) içerisinde yapmış olduğunuz en ağır harcama kalemi bulundu.\n\n"
             "Bu harcama '${cat}' kategorisine ait olup tutarı <r>-${maxExp.amount.toStringAsFixed(2)} ₺</r> olarak kaydedilmiştir.\n"
             "Kayıt sırasındaki açıklamanız ise: \"$desc\". Lütfen yüksek meblağlı işlemlerinize daha detaylı açıklamalar girmeyi unutmayın.";
    }

    else if (query == 'En Büyük Gelir') {
      final incomes = targetTransactions.where((t) => t.type == 'income').toList();
      if (incomes.isEmpty) return "Seçilen periyotta şirkete giren bir kazanç kaydı maalesef yok.";
      incomes.sort((a, b) => b.amount.compareTo(a.amount));
      final maxInc = incomes.first;
      final cat = getCategoryById(maxInc.categoryId).name;
      final desc = maxInc.description.isNotEmpty ? maxInc.description : 'Açıklama girilmemiş';
      
      return "$periyotAd içerisinde kayıtlarınıza geçen en muazzam kazanç kaleminiz detaylarıyla çıkarıldı.\n\n"
             "Bu gelir '${cat}' klasöründen sağlanmış olup, şirkete <g>+${maxInc.amount.toStringAsFixed(2)} ₺</g> katkı sağlamıştır.\n"
             "İşlemin açıklamasında ise: \"$desc\" yazmaktadır.\n"
             "Böyle rekor gelirlerin artarak devam etmesini diliyorum!";
    }

    else if (query == 'En Çok Harcanan Kategori') {
      final expenses = targetTransactions.where((t) => t.type == 'expense').toList();
      if (expenses.isEmpty) return "Bu filtrede hesaplanabilecek bir maliyet bulunamadı.";
      
      Map<int, double> categorySums = {};
      for (var exp in expenses) {
        categorySums[exp.categoryId] = (categorySums[exp.categoryId] ?? 0) + exp.amount;
      }
      
      int maxCatId = categorySums.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      double maxVal = categorySums[maxCatId]!;
      String catName = getCategoryById(maxCatId).name;
      
      return "$periyotAd baz alındığında şirket kasanızdan damla damla en çok eksilen, toplamda en yüksek hacme ulaşan kategori belirlendi.\n\n"
             "Özellikle '$catName' alanında yoğun bir harcama yapılmış ve buraya toplam <r>-${maxVal.toStringAsFixed(2)} ₺</r> ödenmiştir.\n"
             "Bu alanı yakın takibe almak, şirketinizin gider optimizasyonu için verimli olabilir.";
    }

    else if (query == 'Son İşlemler') {
      var takes = targetTransactions.length > 5 ? 5 : targetTransactions.length;
      String res = "Yakın zamanda ($periyotAd için) sisteme eklenen son işlemlerinizin dökümüdür:\n\n";
      for (int i = 0; i < takes; i++) {
        final t = targetTransactions[i];
        final typeStr = t.type == 'income' ? 'Gelir' : 'Gider';
        final color = t.type == 'income' ? '<g>+' : '<r>-';
        final colorExt = t.type == 'income' ? '</g>' : '</r>';
        final dateStr = DateFormat('dd MMM', 'tr_TR').format(t.date);
        final desc = t.description.isNotEmpty ? " / ${t.description}" : "";
        res += "• $dateStr ▸ ${getCategoryById(t.categoryId).name} ($typeStr)\n  Tutar: $color${t.amount.toStringAsFixed(2)} ₺$colorExt$desc\n\n";
      }
      res += "Kayıt detaylarının tutulması şirketinizin şeffaf muhasebesi için çok faydalıdır.";
      return res;
    }

    return "Anlayamadım, lütfen tekrar deneyin.";
  }
}
