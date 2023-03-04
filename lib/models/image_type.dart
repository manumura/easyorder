enum ImageType {
  product,
  category,
}

class ImageTypeDirectory {
  static String? getDirectory(ImageType imageType) {
    switch (imageType) {
      case ImageType.product:
        return 'products';
      case ImageType.category:
        return 'categories';
      default:
        return null;
    }
  }
}
