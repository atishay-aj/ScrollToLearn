import 'dart:convert';
import 'package:educationapp/image_popup.dart';
import 'package:educationapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
