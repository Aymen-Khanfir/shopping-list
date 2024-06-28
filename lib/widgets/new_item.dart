import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  String _enteredGroceryName = '';
  int _enteredGroceryQuantity = 1;
  // We add the ! because we already know that a category with Categories.vegetables
  // does exit so we don't need to check
  Category _selectedCategory = categories[Categories.vegetables]!;

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.https(
          'shopping-list-5d7f5-default-rtdb.europe-west1.firebasedatabase.app', "/shopping-list.json");
      http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _enteredGroceryName,
          'quantity': _enteredGroceryQuantity,
          'category': _selectedCategory.title,
        }),
      );
      
      

      // Navigator.of(context).pop(
      //   GroceryItem(
      //     // It's not a perfect id, juste to speed process
      //     id: DateTime.now.toString(),
      //     name: _enteredGroceryName,
      //     quantity: _enteredGroceryQuantity,
      //     category: _selectedCategory,
      //   ),
      // );
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Grocery Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 caracteres.';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  // This check is redundant because we've aleardy check if the value is null in the validator
                  // if (newValue == null) {
                  //   return;
                  // }
                  _enteredGroceryName = newValue!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredGroceryQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be valid, positive number';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        // We used parse insted of tryPase because parse will throw an error if it fails
                        // to convert the string into a number while tryParse will yield to null
                        // And while we checked if the value is not null in the validator so we can make sur that
                        // the new value will never be null
                        _enteredGroceryQuantity = int.parse(newValue!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          )
                      ],
                      onChanged: (newValue) {
                        // Here we also don't need to check because we've set an initial value for the DropdownButtomFormField
                        // which is not null
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _resetForm,
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _saveItem,
                    child: const Text('Add Item'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
