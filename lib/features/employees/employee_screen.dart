// Employee management screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  final List<Employee> _employees = [];

  List<Employee> get employees => _employees;

  Future<void> addEmployee(Employee employee) async {
    final db = await DatabaseHelper().database;
    await db.insert('employees', employee.toMap());
    _employees.add(employee);
    notifyListeners();
  }

  Future<void> updatePerformanceScore(int id, int newScore) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'employees',
      {'performanceScore': newScore},
      where: 'id = ?',
      whereArgs: [id],
    );
    final index = _employees.indexWhere((employee) => employee.id == id);
    if (index != -1) {
      _employees[index] = Employee(
        id: _employees[index].id,
        name: _employees[index].name,
        role: _employees[index].role,
        duty: _employees[index].duty,
        performanceScore: newScore,
      );
      notifyListeners();
    }
  }
}

class EmployeeScreen extends StatelessWidget {
  const EmployeeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final dutyController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Employees'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Employee',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: roleController,
              decoration: InputDecoration(
                labelText: 'Role',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: dutyController,
              decoration: InputDecoration(
                labelText: 'Duty',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final employee = Employee(
                    name: nameController.text,
                    role: roleController.text,
                    duty: dutyController.text,
                  );
                  Provider.of<EmployeeProvider>(
                    context,
                    listen: false,
                  ).addEmployee(employee);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add Employee',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount:
                    Provider.of<EmployeeProvider>(context).employees.length,
                itemBuilder: (context, index) {
                  final employee =
                      Provider.of<EmployeeProvider>(context).employees[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(employee.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${employee.role}'),
                          Text('Duty: ${employee.duty}'),
                          Text(
                            'Performance Score: ${employee.performanceScore}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final scoreController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Update Performance Score'),
                                content: TextField(
                                  controller: scoreController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'New Score',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final newScore =
                                          int.tryParse(scoreController.text) ??
                                          employee.performanceScore;
                                      Provider.of<EmployeeProvider>(
                                        context,
                                        listen: false,
                                      ).updatePerformanceScore(
                                        employee.id!,
                                        newScore,
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Update'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
}
