import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stock_screen.dart';

class StockNotificationsProvider with ChangeNotifier {
  final List<Stock> _lowStockItems = [];

  List<Stock> get lowStockItems => _lowStockItems;

  void checkStockLevels(List<Stock> stocks) {
    _lowStockItems.clear();
    for (var stock in stocks) {
      if (stock.quantity < 5) {
        _lowStockItems.add(stock);
      }
    }
    notifyListeners();
  }
}

class StockNotificationsScreen extends StatelessWidget {
  const StockNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StockNotificationsProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock Notifications')),
        body: Consumer<StockNotificationsProvider>(
          builder: (context, provider, child) {
            return ListView.builder(
              itemCount: provider.lowStockItems.length,
              itemBuilder: (context, index) {
                final stock = provider.lowStockItems[index];
                return ListTile(
                  title: Text(stock.name),
                  subtitle: Text('Quantity: ${stock.quantity}'),
                  trailing: const Icon(Icons.warning, color: Colors.red),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
