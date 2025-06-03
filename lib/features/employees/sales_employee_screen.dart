import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/stock.dart';
import '../auth/login_screen.dart';

class SalesEmployeeScreen extends StatefulWidget {
  final String employeeUsername;
  const SalesEmployeeScreen({Key? key, required this.employeeUsername})
    : super(key: key);

  @override
  State<SalesEmployeeScreen> createState() => _SalesEmployeeScreenState();
}

class _SalesEmployeeScreenState extends State<SalesEmployeeScreen> {
  List<_SaleRecord> _sales = [];
  List<Stock> _stocks = [];
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _employeeId;
  String? _employeeName;

  int get totalItemsSold => _sales.fold(0, (sum, sale) => sum + sale.quantity);
  double get totalSales => _sales.fold(0, (sum, sale) => sum + sale.total);

  @override
  void initState() {
    super.initState();
    _loadEmployeeInfo();
    _fetchStocks();
    _fetchSalesHistory();
  }

  Future<void> _loadEmployeeInfo() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'employees',
      where: 'name = ?',
      whereArgs: [widget.employeeUsername],
    );
    if (result.isNotEmpty) {
      setState(() {
        _employeeId = result.first['id'] as int;
        _employeeName = result.first['name'] as String;
      });
    } else {
      setState(() {
        _employeeId = null;
        _employeeName = null;
      });
    }
  }

  Future<void> _fetchStocks() async {
    final db = await DatabaseHelper().database;
    final stocks = await db.query('stocks');
    setState(() {
      _stocks = stocks.map((s) => Stock.fromMap(s)).toList();
    });
  }

  Future<void> _fetchSalesHistory() async {
    final db = await DatabaseHelper().database;
    // Join sales and stocks to get product name
    final sales = await db.rawQuery('''
      SELECT sales.*, stocks.name as product_name
      FROM sales
      LEFT JOIN stocks ON sales.product_id = stocks.id
      ORDER BY sales.sale_time DESC
    ''');
    setState(() {
      _sales =
          sales
              .map(
                (sale) => _SaleRecord(
                  product: sale['product_name'] as String? ?? 'Unknown',
                  quantity: sale['quantity'] as int,
                  price: 1.0, // Placeholder
                  saleTime: sale['sale_time'] as String?,
                ),
              )
              .toList();
    });
  }

  Future<void> _recordSale(Stock stock, int quantity) async {
    debugPrint(
      'Attempting to record sale. EmployeeId: \\$_employeeId, EmployeeName: \\$_employeeName',
    );
    final db = await DatabaseHelper().database;
    final productResult = await db.query(
      'stocks',
      where: 'name = ?',
      whereArgs: [stock.name],
    );
    if (productResult.isEmpty) {
      throw Exception('Product not found');
    }
    final productId = productResult.first['id'] as int;
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee not identified. Please re-login.'),
        ),
      );
      return;
    }
    await db.insert('sales', {
      'product_id': productId,
      'employee_id': _employeeId,
      'quantity': quantity,
      'sale_time': DateTime.now().toIso8601String(),
    });
    final currentQty = productResult.first['quantity'] as int;
    final newQty = currentQty - quantity;
    await db.update(
      'stocks',
      {'quantity': newQty},
      where: 'id = ?',
      whereArgs: [productId],
    );
    await _fetchStocks();
    await _fetchSalesHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale recorded: \\${stock.name} x$quantity')),
    );
  }

  void _showSellDialog(Stock stock) {
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sell ${stock.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: ${stock.quantity}'),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyController.text) ?? 1;
                if (qty > 0 && qty <= stock.quantity) {
                  await _recordSale(stock, qty);
                  Navigator.pop(context);
                }
              },
              child: const Text('Record Sale'),
            ),
          ],
        );
      },
    );
  }

  // New: Purchase Tab
  Widget _buildPurchaseTab() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final categoryController = TextEditingController();
    final expiryController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Item',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: expiryController,
            decoration: const InputDecoration(
              labelText: 'Expiry Date (YYYY-MM-DD)',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper().database;
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text) ?? 0;
              final category = categoryController.text.trim();
              final expiry = expiryController.text.trim();
              if (name.isNotEmpty && qty > 0) {
                // Check if product exists
                final existing = await db.query(
                  'stocks',
                  where: 'name = ?',
                  whereArgs: [name],
                );
                if (existing.isNotEmpty) {
                  // Update quantity
                  final currentQty = existing.first['quantity'] as int;
                  await db.update(
                    'stocks',
                    {'quantity': currentQty + qty},
                    where: 'name = ?',
                    whereArgs: [name],
                  );
                } else {
                  // Insert new product
                  await db.insert('stocks', {
                    'name': name,
                    'quantity': qty,
                    'category': category,
                    'expiryDate': expiry,
                  });
                }
                await _fetchStocks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase recorded!')),
                );
              }
            },
            child: const Text('Record Purchase'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Current Stock',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final stock = _stocks[index];
                return ListTile(
                  leading: const Icon(Icons.inventory),
                  title: Text(stock.name),
                  subtitle: Text(
                    'Qty: ${stock.quantity} | Category: ${stock.category}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Sales",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Total Items Sold: $totalItemsSold'),
                        Text('Total Sales: \$${totalSales.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Icon(
                      Icons.point_of_sale,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 400, // Set a fixed height for the list
              child: ListView.builder(
                itemCount: _stocks.length,
                itemBuilder: (context, index) {
                  final stock = _stocks[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        stock.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('In stock: ${stock.quantity}'),
                      trailing: ElevatedButton(
                        onPressed:
                            stock.quantity > 0
                                ? () => _showSellDialog(stock)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Sell'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistory() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _sales.isEmpty
                    ? const Center(child: Text('No sales recorded yet.'))
                    : ListView.builder(
                      itemCount: _sales.length,
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt_long,
                              color: Colors.blueAccent,
                            ),
                            title: Text('${sale.product} x${sale.quantity}'),
                            subtitle:
                                sale.saleTime != null
                                    ? Text(
                                      DateFormat(
                                        'yyyy-MM-dd – kk:mm',
                                      ).format(DateTime.parse(sale.saleTime!)),
                                    )
                                    : null,
                            trailing: Text(
                              '\$${sale.total.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue, size: 40),
              title: Text(
                _employeeName ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Employee ID:  24{_employeeId ?? "-"}'),
                  const SizedBox(height: 2),
                  Text('Username:  24{widget.employeeUsername}'),
                  // Add more fields as needed
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: const Text('About'),
              subtitle: const Text(
                'This is your profile. You can view your information here.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildDashboard(context),
      _buildSalesHistory(),
      _buildPurchaseTab(),
      _buildProfile(),
    ];
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Sales Employee'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.person, color: Colors.blue, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Sales Employee',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Sales History'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Purchase'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Sales History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Purchase',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _SaleRecord {
  final String product;
  final int quantity;
  final double price;
  final String? saleTime;
  _SaleRecord({
    required this.product,
    required this.quantity,
    required this.price,
    this.saleTime,
  });
  double get total => price * quantity;
}
