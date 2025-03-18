import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'finance_model.dart';
import 'finance_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  String? _selectedCategory;
  bool _isRecurring = false;
  String _recurrenceFrequency = 'Daily';
  TimeOfDay _notificationTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: provider.categories
                    .map((category) => DropdownMenuItem(
                          value: category.name,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Expense', 'Income']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SwitchListTile(
                title: const Text('Recurring Transaction'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value!),
              ),
              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  value: _recurrenceFrequency,
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map((frequency) => DropdownMenuItem(
                            value: frequency,
                            child: Text(frequency),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _recurrenceFrequency = value!),
                ),
                ListTile(
                  title: Text('Notification Time: ${_notificationTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _notificationTime,
                    );
                    if (time != null) {
                      setState(() => _notificationTime = time);
                    }
                  },
                ),
              ],
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    provider.addTransaction(Transaction(
                      id: Uuid().v4(),
                      amount: _selectedType == 'Expense'
                          ? -double.parse(_amountController.text)
                          : double.parse(_amountController.text),
                      title: _titleController.text,
                      date: DateTime.now(),
                      type: _selectedType,
                      // category: _selectedCategory,
                      isRecurring: _isRecurring,
                      recurrenceFrequency: _isRecurring ? _recurrenceFrequency : null,
                      notificationTime: _isRecurring
                          ? '${_notificationTime.hour}:${_notificationTime.minute}'
                          : null,
                          category: _selectedCategory ?? ""
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}