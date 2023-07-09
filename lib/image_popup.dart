import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
