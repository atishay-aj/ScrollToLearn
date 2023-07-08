import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

void main() {
  runApp(ScrollToLearnApp());
}

class ScrollToLearnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Add your filter logic here
              print('Filter icon pressed');
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

  void fetchPosts() async {
    if (!_isLoading && _hasMorePosts) {
      setState(() {
        _isLoading = true;
      });

      final url =
          'https://scrolltolearn.onrender.com/api/posts?page=$_page&limit=10';
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
                image: DecorationImage(
                  image: NetworkImage(post.imageUrl),
                  fit: BoxFit.fill,
                ),
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
              imageProvider: NetworkImage(imageUrls[index]),
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
