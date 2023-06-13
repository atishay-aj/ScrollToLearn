import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(LearntoScrollApp());
}

class LearntoScrollApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn to Scroll',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        title: Text('Learn to Scroll'),
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
      });
    } else {
      print('Error fetching posts. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostWidget(post: posts[index]);
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
      child: Column(
        children: [
          Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(post.text),
          ),
        ],
      ),
    );
  }
}
