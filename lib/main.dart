import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(ScrollToLearnApp());
}

class ScrollToLearnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scroll To Learn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scroll To Learn'),
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

  @override
  void initState() {
    super.initState();
    fetchPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchPosts() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final url =
          'https://jsonplaceholder.typicode.com/photos?_page=$_page&_limit=10';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Post> fetchedPosts = responseData.map((data) {
          return Post(
            imageUrl: data['url'],
            text: data['title'],
          );
        }).toList();

        setState(() {
          posts.addAll(fetchedPosts);
          _page++;
          _isLoading = false;
        });
      } else {
        print('Error fetching posts. Status code: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              image: DecorationImage(
                  image: NetworkImage(post.imageUrl), fit: BoxFit.fill),
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
