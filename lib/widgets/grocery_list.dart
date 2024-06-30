import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-5d7f5-default-rtdb.europe-west1.firebasedatabase.app',
      "/shopping-list.json",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch data. Please try again later!";
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> groceriesListData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (var item in groceriesListData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Something went wrong. Please try again later!";
      });
    }
  }

  void _addItem() async {
    // You should always add the type of data you should return with when doing a pop action
    // otherwise it will be set to string
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item) async {
    final itemIndex = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'shopping-list-5d7f5-default-rtdb.europe-west1.firebasedatabase.app',
      "/shopping-list/${item.id}.json",
    );

    final response = await http.delete(url);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      response.statusCode <= 400
          ? SnackBar(
              duration: const Duration(seconds: 3),
              content: const Text("Item deleted."),
              action: SnackBarAction(
                label: "Undo",
                onPressed: () async {
                  setState(() {
                    _groceryItems.insert(itemIndex, item);
                  });

                  // Resave the item to the database
                  final url = Uri.https(
                    'shopping-list-5d7f5-default-rtdb.europe-west1.firebasedatabase.app',
                    "/shopping-list.json",
                  );

                  final response = await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                    },
                    body: json.encode({
                      'name': item.name,
                      'quantity': item.quantity,
                      'category': item.category.title,
                    }),
                  );

                  if (response.statusCode >= 400) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Failed to re-save item. Please try again."),
                        action: SnackBarAction(
                          label: "Retry",
                          onPressed: () async {
                            // Retry the save operation
                            setState(() {
                              _groceryItems.remove(item);
                            });
                            removeItem(item);
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            )
          : SnackBar(
              duration: const Duration(seconds: 3),
              content: const Text("An error occurred while trying to delete the item."),
              action: SnackBarAction(
                label: "Retry",
                onPressed: () {
                  removeItem(item);
                },
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text('No Groceries items available yet!'),
    );

    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      mainContent = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add_circle),
          ),
        ],
      ),
      body: mainContent,
    );
  }
}
