import 'dart:convert';
import 'package:educationapp/post_list_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_login/flutter_login.dart';

void main() {
  runApp(ScrollToLearnApp());
}

class ScrollToLearnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider<TokenProvider>(
          create: (_) => TokenProvider()..init(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Scroll To Learn',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokenProvider = Provider.of<TokenProvider>(context);

    if (tokenProvider.token.isNotEmpty) {
      return HomePage();
    } else {
      return LoginPage();
    }
  }
}

const mockUsers = {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
  'near.huscarl@gmail.com': 'subscribe to pewdiepie',
  '@.com': '.',
};

class LoginPage extends StatelessWidget {
  static const routeName = '/auth';

  const LoginPage({Key? key}) : super(key: key);

  Future<String?> _loginUser(BuildContext context, LoginData data) async {
    try {
      final response = await http.post(
        Uri.parse('https://scrolltolearn.onrender.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': data.name,
          'password': data.password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final token = responseData['token'];
        final tokenProvider =
            Provider.of<TokenProvider>(context, listen: false);
        await tokenProvider.saveToken(token);
        return null; // Login successful, return null
      } else {
        return responseData['error']; // Return error message
      }
    } catch (error) {
      return 'Failed to login. Please try again.'; // Return error message
    }
  }

  Future<String?> _signupUser(BuildContext context, SignupData data) async {
    try {
      final response = await http.post(
        Uri.parse('https://scrolltolearn.onrender.com/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': data.name,
          'password': data.password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final token = responseData['token'];
        final tokenProvider =
            Provider.of<TokenProvider>(context, listen: false);
        await tokenProvider.saveToken(token);
        return null; // Signup successful, return null
      } else {
        return responseData['error']; // Return error message
      }
    } catch (error) {
      return 'Failed to register. Please try again.'; // Return error message
    }
  }

  Future<String?> _recoverPassword(String name) {
    // Implement your password recovery logic here
    // Send a password recovery request to your backend API and handle the response
    // Return an error message if the recovery fails, or null if successful
    return Future.delayed(Duration(milliseconds: 2250)).then((_) {
      // Mock example: Check if the user exists in your mockUsers map
      if (!mockUsers.containsKey(name)) {
        return 'User not found';
      }
      // Password recovery successful
      return null;
    });
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Scroll To Learn',
      logo: AssetImage('assets/images/logo.jpeg'),
      onLogin: (loginData) => _loginUser(context, loginData),
      onSignup: (signupData) => _signupUser(context, signupData),
      onRecoverPassword: (name) => _recoverPassword(name),
      onSubmitAnimationCompleted: () => _navigateToHomePage(context),
      theme: LoginTheme(
        // Customize the theme according to your preferences
        primaryColor: Colors.blue,
        titleStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class TokenProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  String _token;

  TokenProvider() : _token = '';

  String get token => _token;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('token') ?? '';
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _prefs.setString('token', token);
    notifyListeners();
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Text(
                  //   'User Name',
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 16,
                  //   ),
                  // ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                final tokenProvider =
                    Provider.of<TokenProvider>(context, listen: false);
                tokenProvider.saveToken('');
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
          ],
        ),
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
