const String _cloudFrontBaseUrl = 'https://d1234567890.cloudfront.net';

/// Constructs a CloudFront URL for the given image key/path
String getCloudFrontImageUrl(String imageUrl) {
  // If the URL is already a full URL, return it as is
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }

  // Remove any leading slash to prevent double slashes
  final path = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

  // Combine the base URL with the image path
  return '$_cloudFrontBaseUrl/$path';
}
