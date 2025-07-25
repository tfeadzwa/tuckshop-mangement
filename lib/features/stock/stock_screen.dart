// Stock management screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/stock.dart';

class StockProvider with ChangeNotifier {
  final List<Stock> _stocks = [];

  List<Stock> get stocks => _stocks;

  Future<void> addStock(Stock stock) async {
    final db = await DatabaseHelper().database;
    await db.insert('stocks', stock.toMap());
    _stocks.add(stock);
    notifyListeners();
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';
  final categories = ['All', 'Category 1', 'Category 2', 'Category 3'];

  void _showAddStockDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final categoryController = TextEditingController();
    final expiryDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Stock'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: expiryDateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Expiry Date'),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      expiryDateController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(selectedDate);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newStock = Stock(
                  name: nameController.text,
                  quantity: int.tryParse(quantityController.text) ?? 0,
                  category: categoryController.text,
                  expiryDate: expiryDateController.text,
                );
                Provider.of<StockProvider>(
                  context,
                  listen: false,
                ).addStock(newStock);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStockOut(context);
    });
  }

  void _checkStockOut(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final outOfStockItems =
        stockProvider.stocks.where((stock) => stock.quantity <= 0).toList();
    if (outOfStockItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Stock Out Notification'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The following items are out of stock:'),
                  const SizedBox(height: 10),
                  ...outOfStockItems
                      .map((item) => Text('-  9${item.name}'))
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final filteredStocks =
        stockProvider.stocks.where((stock) {
          final matchesSearch = stock.name.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
          final matchesCategory =
              selectedCategory == 'All' || stock.category == selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              items:
                  categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredStocks.length,
                itemBuilder: (context, index) {
                  final stock = filteredStocks[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(stock.name),
                      subtitle: Text('Category: ${stock.category}'),
                      trailing: Text('Qty: ${stock.quantity}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStockDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
