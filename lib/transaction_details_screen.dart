import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'finance_model.dart';
import 'finance_provider.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _selectedType;
  late String _selectedCategory;
  late bool _isRecurring;
  late String _recurrenceFrequency;
  late TimeOfDay _notificationTime;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(
        text: widget.transaction.amount.abs().toString());
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _isRecurring = widget.transaction.isRecurring;
    _recurrenceFrequency = widget.transaction.recurrenceFrequency ?? 'Daily';
    
    // Parse notification time if it exists
    if (widget.transaction.notificationTime != null) {
      final timeParts = widget.transaction.notificationTime!.split(':');
      _notificationTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } else {
      _notificationTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                if (_formKey.currentState!.validate()) {
                  // Save changes
                  final updatedTransaction = Transaction(
                    id: widget.transaction.id,
                    userId: widget.transaction.userId,
                    title: _titleController.text,
                    amount: _selectedType == 'Expense'
                        ? -double.parse(_amountController.text)
                        : double.parse(_amountController.text),
                    date: widget.transaction.date,
                    type: _selectedType,
                    category: _selectedCategory,
                    isRecurring: _isRecurring,
                    recurrenceFrequency: _isRecurring ? _recurrenceFrequency : null,
                    notificationTime: _isRecurring
                        ? '${_notificationTime.hour}:${_notificationTime.minute}'
                        : null,
                    firestoreId: widget.transaction.firestoreId,
                  );
                  provider.updateTransaction(updatedTransaction);
                  Navigator.pop(context);
                }
              }
              setState(() => _isEditing = !_isEditing);
              
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Transaction'),
                  content: const Text('Are you sure you want to delete this transaction?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        provider.deleteTransaction(widget.transaction);
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to home screen
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value?.isEmpty ?? true ? 'Enter title' : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Enter amount';
                    if (double.tryParse(value!) == null) return 'Enter valid amount';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Expense', 'Income']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
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
                SwitchListTile(
                  title: const Text('Recurring Transaction'),
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value!),
                ),
                if (_isRecurring) ...[
                  DropdownButtonFormField<String>(
                    value: _recurrenceFrequency,
                    decoration: const InputDecoration(labelText: 'Recurrence Frequency'),
                    items: ['Daily', 'Weekly', 'Monthly']
                        .map((frequency) => DropdownMenuItem(
                              value: frequency,
                              child: Text(frequency),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _recurrenceFrequency = value!),
                  ),
                  ListTile(
                    title: Text('Notification Time: ${_notificationTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                ],
              ] else ...[
                _buildDetailRow('Title', widget.transaction.title),
                _buildDetailRow(
                  'Amount',
                  '${widget.transaction.type == 'Income' ? '+' : ''}${NumberFormat.currency(symbol: '\$').format(widget.transaction.amount)}',
                ),
                _buildDetailRow('Type', widget.transaction.type),
                _buildDetailRow('Category', widget.transaction.category),
                _buildDetailRow(
                  'Date',
                  DateFormat.yMMMd().format(widget.transaction.date),
                ),
                if (widget.transaction.isRecurring) ...[
                  _buildDetailRow(
                    'Recurrence',
                    widget.transaction.recurrenceFrequency ?? '',
                  ),
                  _buildDetailRow(
                    'Notification Time',
                    widget.transaction.notificationTime ?? '',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
} 