import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  runApp(ScrollToLearnApp());
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

class PostListView extends StatefulWidget {
  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  List<Post> posts = [];
  ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _isLoading = false;
  bool _hasMorePosts = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    fetchPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (_hasMorePosts) {
          fetchPosts();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categoryProvider = Provider.of<CategoryProvider>(context);
    if (categoryProvider.selectedCategory != _selectedCategory) {
      _selectedCategory = categoryProvider.selectedCategory;
      resetPosts();
    }
  }

  void resetPosts() {
    setState(() {
      posts.clear();
      _page = 1;
      _isLoading = false;
      _hasMorePosts = true;
    });
    fetchPosts();
  }

  void fetchPosts() async {
    print("here calling hurray");
    if (!_isLoading && _hasMorePosts) {
      setState(() {
        _isLoading = true;
      });

      final url =
          'https://scrolltolearn.onrender.com/api/posts?page=$_page&limit=10&category=$_selectedCategory';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Post> fetchedPosts = responseData.map((data) {
          return Post(
            imageUrl: data['imageUrl'],
            text: data['title'],
          );
        }).toList();

        setState(() {
          posts.addAll(fetchedPosts);
          _page++;
          _isLoading = false;
          if (fetchedPosts.length < 10) {
            _hasMorePosts = false;
          }
        });
      } else {
        print('Error fetching posts. Status code: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(posts.length);
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index < posts.length) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: PostWidget(post: posts[index]),
          );
        } else if (_isLoading) {
          return Container(
            padding: EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}

class Post {
  final String imageUrl;
  final String text;

  Post({required this.imageUrl, required this.text});
}

class PostWidget extends StatelessWidget {
  final Post post;

  PostWidget({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ImagePopup(
                    imageUrls: [post.imageUrl],
                  );
                },
              );
            },
            child: Container(
              height: 200.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              ),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.fill,
                errorWidget: (context, url, error) => Icon(Icons.error),
                cacheManager: DefaultCacheManager(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              post.text,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () {
                  // Handle like button pressed
                },
              ),
              IconButton(
                icon: Icon(Icons.bookmark_border),
                onPressed: () {
                  // Handle save button pressed
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImagePopup extends StatelessWidget {
  final List<String> imageUrls;
  final int initialPage;

  ImagePopup({required this.imageUrls, this.initialPage = 0});

  @override
  Widget build(BuildContext context) {
    final PageController pageController =
        PageController(initialPage: initialPage);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: PhotoViewGallery.builder(
          itemCount: imageUrls.length,
          pageController: pageController,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(imageUrls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(
            color: Colors.black,
          ),
          loadingBuilder: (context, event) {
            if (event == null) return Container();
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
