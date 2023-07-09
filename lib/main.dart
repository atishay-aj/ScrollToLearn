import 'dart:convert';
import 'package:educationapp/post_list_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';

void main() {
  runApp(ScrollToLearnApp());
}

class ScrollToLearnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CategoryProvider>(
        create: (_) => CategoryProvider(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Scroll To Learn',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: HomePage(),
        ));
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    fetchAndSetCategories(categoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Scroll To Learn'),
        actions: [
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              return IconButton(
                icon: Icon(Ionicons.options),
                onPressed: () {
                  // Show the category filter dropdown
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Select Category'),
                        content: DropdownButton<String>(
                          value: categoryProvider.selectedCategory,
                          onChanged: (String? newValue) {
                            categoryProvider
                                .setSelectedCategory(newValue ?? '');
                            Navigator.of(context).pop();
                          },
                          items: categoryProvider.categories
                              .map<DropdownMenuItem<String>>((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: PostListView(),
    );
  }
}

List<String> categories = []; // Store the fetched categories globally

Future<List<String>> fetchCategories() async {
  final response = await http
      .get(Uri.parse('https://scrolltolearn.onrender.com/allcategories'));

  if (response.statusCode == 200) {
    final List<dynamic> json = jsonDecode(response.body);
    categories = json.map((category) => category['name'] as String).toList();
    return categories;
  } else {
    throw Exception('Failed to load categories');
  }
}

Future<void> fetchAndSetCategories(CategoryProvider categoryProvider) async {
  final fetchedCategories = await fetchCategories();
  categoryProvider.setCategories(fetchedCategories);
}

class CategoryProvider with ChangeNotifier {
  String _selectedCategory = 'All';
  List<String> _categories = [];

  String get selectedCategory => _selectedCategory;
  List<String> get categories => _categories;

  void setSelectedCategory(String category) {
    print(category);
    _selectedCategory = category;
    notifyListeners();
  }

  void setCategories(List<String> categories) {
    _categories = categories;
    notifyListeners();
  }
}
