// Dashboard screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../employees/employee_screen.dart';
import '../stock/stock_screen.dart';
import '../../data/models/stock.dart';
import '../auth/login_screen.dart';

class DashboardProvider with ChangeNotifier {
  // Example: Add logic to fetch and manage stock summaries
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key, this.userRole}) : super(key: key);
  final String? userRole;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _adminScreens = [];

  @override
  void initState() {
    super.initState();
    _adminScreens.addAll([
      _DashboardMainView(userRole: widget.userRole),
      const EmployeeScreen(),
      const _AddProductScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Stock out notification on dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final outOfStockItems =
          stockProvider.stocks.where((stock) => stock.quantity <= 0).toList();
      if (outOfStockItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock out: ${outOfStockItems.map((e) => e.name).join(', ')}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final stockProvider = Provider.of<StockProvider>(context);
    // Product In: count of all unique stock items
    final totalProductsIn = stockProvider.stocks.length;
    // Product Out: count of out-of-stock items
    final totalProductsOut =
        stockProvider.stocks.where((stock) => stock.quantity <= 0).length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF42a5f5), Color(0xFF1976d2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tuckshop',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueAccent),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body:
          widget.userRole == 'admin'
              ? _adminScreens[_currentIndex]
              : _DashboardMainView(userRole: widget.userRole),
      bottomNavigationBar:
          widget.userRole == 'admin'
              ? BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  selectedItemColor: Colors.blueAccent,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_add),
                      label: 'Add Employee',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_box),
                      label: 'Add Product',
                    ),
                  ],
                )
              : null,
    );
  }
}

class _DashboardMainView extends StatelessWidget {
  final String? userRole;
  const _DashboardMainView({Key? key, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe3f2fd), Color(0xFFbbdefb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Product In', stockProvider.stocks.length.toString(), Colors.blue),
                _buildStatCard('Product Out', stockProvider.stocks.where((stock) => stock.quantity <= 0).length.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (userRole == 'admin')
                        _buildNavigationCard(
                          context,
                          'Manage Employees',
                          Icons.people,
                          Colors.green,
                          const EmployeeScreen(),
                        ),
                      _buildNavigationCard(
                        context,
                        'Manage Stock',
                        Icons.inventory,
                        Colors.purple,
                        const StockScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'Chart Placeholder',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: color)),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductScreen extends StatefulWidget {
  const _AddProductScreen({Key? key}) : super(key: key);

  @override
  State<_AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<_AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _showEditDialog(Stock stock, int index) {
    _nameController.text = stock.name;
    _quantityController.text = stock.quantity.toString();
    _categoryController.text = stock.category;
    _expiryDateController.text = stock.expiryDate;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) => value == null || int.tryParse(value) == null ? 'Enter valid quantity' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter category' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _expiryDateController,
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
                      _expiryDateController.text =
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Select expiry date' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final stockProvider = Provider.of<StockProvider>(context, listen: false);
                  final updatedStock = Stock(
                    name: _nameController.text.trim(),
                    quantity: int.parse(_quantityController.text),
                    category: _categoryController.text.trim(),
                    expiryDate: _expiryDateController.text.trim(),
                  );
                  // Remove old and add updated (simulate update)
                  stockProvider.stocks.removeAt(index);
                  await stockProvider.addStock(updatedStock);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Add New Product',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || int.tryParse(value) == null ? 'Enter valid quantity' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter category' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _expiryDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            _expiryDateController.text =
                                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Select expiry date' : null,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isLoading = true);
                                    try {
                                      await stockProvider.addStock(
                                        Stock(
                                          name: _nameController.text.trim(),
                                          quantity: int.parse(_quantityController.text),
                                          category: _categoryController.text.trim(),
                                          expiryDate: _expiryDateController.text.trim(),
                                        ),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green),
                                      );
                                      _formKey.currentState!.reset();
                                      _nameController.clear();
                                      _quantityController.clear();
                                      _categoryController.clear();
                                      _expiryDateController.clear();
                                      setState(() {});
                                    } catch (e) {
                                      setState(() => _error = 'Failed to add product');
                                    } finally {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Add Product', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'All Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stockProvider.stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stockProvider.stocks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(stock.name),
                        subtitle: Text('Qty: ${stock.quantity} | Category: ${stock.category} | Exp: ${stock.expiryDate}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showEditDialog(stock, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                stockProvider.stocks.removeAt(index);
                                setState(() => _isLoading = false);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
