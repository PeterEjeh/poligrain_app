import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart'; // For CognitoAuthSession

import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:poligrain_app/models/product.dart';
import '../../services/draft_service.dart';
import 'marketplace_screen.dart'; // For fetchProductById
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

const String cloudFrontDomain = 'https://dqsnae4wms22.cloudfront.net';

String getCloudFrontImageUrl(String s3Key) {
  if (s3Key.isEmpty) return '';
  return '$cloudFrontDomain/$s3Key';
}

class ProductCreateScreen extends StatefulWidget {
  final Product? product;
  final ProductDraft? draft;
  const ProductCreateScreen({super.key, this.product, this.draft});

  @override
  State<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends State<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherCategoryController =
      TextEditingController();

  bool _isLoading = false;
  File? _pickedImageFile; // legacy, keep for backward compatibility
  String? _s3ImageUrl; // legacy, keep for backward compatibility
  bool _isFetchingProduct = false;

  // Multiple media
  List<XFile> _pickedImages = [];
  List<XFile> _pickedVideos = [];
  List<String> _uploadedImageUrls = [];
  List<String> _uploadedVideoUrls = [];

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Dairy',
    'Grains',
    'Livestock',
    'Poultry',
    'Fishery',
    'Others',
  ];
  String? _selectedCategory;

  // Map product keywords to categories
  final Map<String, String> _productCategoryMap = {
    'tomato': 'Vegetables',
    'cabbage': 'Vegetables',
    'beans': 'Grains',
    'rice': 'Grains',
    'yam': 'Grains',
    'cassava': 'Grains',
    'corn': 'Grains',
    'cucumber': 'Vegetables',
    'oil palm': 'Livestock',
    'cocoa': 'Livestock',
    'coconut': 'Livestock',
    'piggery': 'Livestock',
    'grasscutter': 'Livestock',
    'goat': 'Livestock',
    'fish': 'Fishery',
    'milk': 'Dairy',
    'egg': 'Poultry',
    'chicken': 'Poultry',
    'maize': 'Grains',
    // Add more as needed
  };

  void _autoFillCategory(String name) {
    final lower = name.toLowerCase();
    for (final entry in _productCategoryMap.entries) {
      if (lower.contains(entry.key)) {
        if (_selectedCategory != entry.value) {
          setState(() {
            _selectedCategory = entry.value;
          });
        }
        return;
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Optimize image before upload
        final bytes = await image.readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Resize to max width 1024px
          final resized = img.copyResize(decoded, width: 1024);
          // Compress to JPEG quality 80
          final jpg = img.encodeJpg(resized, quality: 80);
          // Save to temp file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/optimized_${image.name}');
          await tempFile.writeAsBytes(jpg);
          setState(() {
            _pickedImageFile = tempFile;
          });
        } else {
          _showError("Failed to decode image for optimization.");
        }
      } else {
        _showError("No image selected.");
      }
    } catch (e) {
      _showError("Failed to pick image: $e");
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile>? images = await picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images);
        });
      }
    } catch (e) {
      _showError("Failed to pick images: $e");
    }
  }

  Future<void> _pickVideos() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _pickedVideos.add(video);
        });
      }
    } catch (e) {
      _showError("Failed to pick video: $e");
    }
  }

  Future<List<String>> _uploadFiles(List<XFile> files, String folder) async {
    List<String> uploadedKeys = [];
    for (final file in files) {
      final String fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final uploadOp = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        path: StoragePath.fromString(fileName),
        options: const StorageUploadFileOptions(),
      );
      final StorageUploadFileResult result = await uploadOp.result;
      uploadedKeys.add(result.uploadedItem.path);
    }
    return uploadedKeys;
  }

  Future<void> createOrUpdateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedImages.isEmpty && widget.product == null) {
      _showError('Please select at least one image for the product.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      if (!session.isSignedIn) {
        _showError(
          "User not signed in. Please log in to create or update a product.",
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      _showError("Could not determine authentication status: " + e.toString());
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    List<String> imageUrlsToUse = [];
    List<String> videoUrlsToUse = [];

    try {
      if (_pickedImages.isNotEmpty) {
        imageUrlsToUse = await _uploadFiles(_pickedImages, 'product_images');
      } else if (widget.product != null &&
          widget.product!.imageUrl.isNotEmpty) {
        imageUrlsToUse = [widget.product!.imageUrl];
      }
      if (_pickedVideos.isNotEmpty) {
        videoUrlsToUse = await _uploadFiles(_pickedVideos, 'product_videos');
      }

      final Map<String, dynamic> productData = {
        'name': _nameController.text.trim(),
        'category':
            _selectedCategory == 'Others'
                ? _otherCategoryController.text.trim()
                : _selectedCategory ?? '',
        'imageUrls': imageUrlsToUse,
        'videoUrls': videoUrlsToUse,
        'unit': _unitController.text.trim(),
        'price':
            double.tryParse(_priceController.text.trim().replaceAll(',', '')) ??
            0.0,
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
      };

      const String apiName = 'PoligrainAPI';

      var response;
      if (widget.product == null) {
        // Create new product
        response =
            await Amplify.API
                .post(
                  '/products',
                  apiName: apiName,
                  body: HttpPayload.json(productData),
                  headers: {'Content-Type': 'application/json'},
                )
                .response;
        safePrint('Create product API response status: ${response.statusCode}');
        safePrint('Create product API response body: ${response.decodeBody()}');
        if (response.statusCode == 201) {
          // Clear the specific draft if we're editing from one
          if (widget.draft != null) {
            await DraftService.deleteDraftById(widget.draft!.id);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product created successfully!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          String errorMsg = "Failed to create product";
          try {
            final responseBody = response.decodeBody();
            if (responseBody.isNotEmpty) {
              final decodedError = jsonDecode(responseBody);
              errorMsg =
                  decodedError['message'] ??
                  decodedError['error'] ??
                  responseBody;
            } else {
              errorMsg =
                  'Failed to create product (Status: ${response.statusCode})';
            }
          } catch (e) {
            errorMsg =
                'Failed to create product (Status: ${response.statusCode}, unparsable error body)';
          }
          _showError(errorMsg);
        }
      } else {
        // Update existing product
        response =
            await Amplify.API
                .put(
                  '/products/${widget.product!.id}',
                  apiName: apiName,
                  queryParameters: {'owner': widget.product!.owner ?? ''},
                  body: HttpPayload.json(productData),
                  headers: {'Content-Type': 'application/json'},
                )
                .response;
        safePrint('Update product API response status: ${response.statusCode}');
        safePrint('Update product API response body: ${response.decodeBody()}');
        if (response.statusCode == 200) {
          // Clear the specific draft if we're editing from one
          if (widget.draft != null) {
            await DraftService.deleteDraftById(widget.draft!.id);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product updated successfully!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          String errorMsg = "Failed to update product";
          try {
            final responseBody = response.decodeBody();
            if (responseBody.isNotEmpty) {
              final decodedError = jsonDecode(responseBody);
              errorMsg =
                  decodedError['message'] ??
                  decodedError['error'] ??
                  responseBody;
            } else {
              errorMsg =
                  'Failed to update product (Status: ${response.statusCode})';
            }
          } catch (e) {
            errorMsg =
                'Failed to update product (Status: ${response.statusCode}, unparsable error body)';
          }
          _showError(errorMsg);
        }
      }
    } on StorageException catch (e) {
      _showError('Storage Error: ${e.message}');
      safePrint('Storage Exception: ${e.toString()}');
    } on ApiException catch (e) {
      // Log the full API exception for more details
      safePrint('Full API Exception: ${e.toString()}');
      _showError('API Error: ${e.message} (Code: ${e.underlyingException})');
    } on AuthException catch (e) {
      // Catch potential AuthExceptions during session fetch
      _showError('Authentication Error: ${e.message}');
      safePrint('Auth Exception: ${e.toString()}');
    } catch (e) {
      _showError('An unexpected error occurred: ${e.toString()}');
      safePrint('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Save or update a draft (instance method)
  Future<void> saveOrUpdateDraft({String? draftId}) async {
    final now = DateTime.now();
    final draftData = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'otherCategory': _otherCategoryController.text,
      'unit': _unitController.text,
      'price': _priceController.text,
      'quantity': _quantityController.text,
      'description': _descriptionController.text,
      'imageUrls': _pickedImages.map((x) => x.path).toList(),
      'videoUrls': _pickedVideos.map((x) => x.path).toList(),
    };
    final title =
        _nameController.text.isNotEmpty
            ? _nameController.text
            : 'Untitled Draft';

    final draft = ProductDraft(
      id: draftId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      savedAt: now,
      data: draftData,
    );

    final success = await DraftService.saveDraft(draft);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draft saved!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save draft')));
      }
    }
  }

  // Load a draft by id (instance method)
  Future<void> loadDraftById(String draftId) async {
    final draft = await DraftService.getDraftById(draftId);
    if (draft == null) {
      throw Exception('Draft not found');
    }

    final data = draft.data;
    setState(() {
      _nameController.text = data['name'] ?? '';
      _selectedCategory = data['category'];
      _otherCategoryController.text = data['otherCategory'] ?? '';
      _unitController.text = data['unit'] ?? '';
      _priceController.text = data['price'] ?? '';
      _quantityController.text = data['quantity'] ?? '';
      _descriptionController.text = data['description'] ?? '';

      // Restore uploaded URLs
      _uploadedImageUrls = List<String>.from(data['imageUrls'] ?? []);
      _uploadedVideoUrls = List<String>.from(data['videoUrls'] ?? []);

      // Restore local files if they exist
      final List images = data['imageUrls'] ?? [];
      _pickedImages =
          images
              .map<XFile?>(
                (path) =>
                    path != null && File(path).existsSync()
                        ? XFile(path)
                        : null,
              )
              .whereType<XFile>()
              .toList();

      final List videos = data['videoUrls'] ?? [];
      _pickedVideos =
          videos
              .map<XFile?>(
                (path) =>
                    path != null && File(path).existsSync()
                        ? XFile(path)
                        : null,
              )
              .whereType<XFile>()
              .toList();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  void _loadDraftData(ProductDraft draft) {
    final data = draft.data;
    _nameController.text = data['name'] ?? '';
    _selectedCategory = data['category'];
    _otherCategoryController.text = data['otherCategory'] ?? '';
    _unitController.text = data['unit'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _quantityController.text = data['quantity']?.toString() ?? '';
    _descriptionController.text = data['description'] ?? '';

    // Restore uploaded URLs
    _uploadedImageUrls = List<String>.from(data['imageUrls'] ?? []);
    _uploadedVideoUrls = List<String>.from(data['videoUrls'] ?? []);

    // Restore local files if they exist
    final List images = data['imageUrls'] ?? [];
    _pickedImages =
        images
            .map<XFile?>(
              (path) =>
                  path != null && File(path).existsSync() ? XFile(path) : null,
            )
            .whereType<XFile>()
            .toList();

    final List videos = data['videoUrls'] ?? [];
    _pickedVideos =
        videos
            .map<XFile?>(
              (path) =>
                  path != null && File(path).existsSync() ? XFile(path) : null,
            )
            .whereType<XFile>()
            .toList();
  }

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_formatPrice);
    _nameController.addListener(() {
      _autoFillCategory(_nameController.text);
    });
    if (widget.draft != null) {
      _loadDraftData(widget.draft!);
    }
    if (widget.product != null) {
      _fetchAndPopulateProduct(widget.product!);
    }
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      final response =
          await Amplify.API
              .get('/products/$id', apiName: 'PoligrainAPI')
              .response;

      if (response.statusCode == 200) {
        final jsonData =
            jsonDecode(await response.decodeBody()) as Map<String, dynamic>;
        return Product.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  Future<void> _fetchAndPopulateProduct(Product product) async {
    setState(() {
      _isFetchingProduct = true;
    });
    final latest = await fetchProductById(product.id);
    final p = latest ?? product;
    _nameController.text = p.name;
    _selectedCategory =
        _categories.contains(p.category) ? p.category : 'Others';
    if (_selectedCategory == 'Others') {
      _otherCategoryController.text = p.category;
    }
    _unitController.text = p.unit ?? '';
    _priceController.text = p.price.toString();
    _quantityController.text = p.quantity.toString();
    _descriptionController.text = p.description;
    // Prefill S3 image URL for preview
    if (p.imageUrl.isNotEmpty) {
      _s3ImageUrl = p.imageUrl;
    }
    setState(() {
      _isFetchingProduct = false;
    });
  }

  void
  _formatPrice() {} // Placeholder, will be implemented if direct formatting is needed on change

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child:
            _isFetchingProduct
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Form ---
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- Media Section ---
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              margin: const EdgeInsets.only(bottom: 28),
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFEFE9E9,
                                            ), // Almost white
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.photo_library,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Media',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            fontFamily: 'Lato',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Max 5 images, 1 video)',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMediaPickerGrid(),
                                  ],
                                ),
                              ),
                            ),
                            // --- Product Info Section ---
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              margin: const EdgeInsets.only(bottom: 28),
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.green[700],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Product Info',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            fontFamily: 'Lato',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Product Name
                                    _buildTextField(
                                      controller: _nameController,
                                      labelText: 'Product Name *',
                                      hintText: 'Enter product name',
                                      prefixIcon: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 20,
                                      ),
                                      validator:
                                          (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Product name is required'
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),
                                    // Category
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Category',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const Text(
                                              ' *',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButtonFormField<String>(
                                          value: _selectedCategory,
                                          items:
                                              _categories
                                                  .map(
                                                    (cat) => DropdownMenuItem(
                                                      value: cat,
                                                      child: Text(cat),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged:
                                              _isLoading
                                                  ? null
                                                  : (val) {
                                                    setState(() {
                                                      _selectedCategory = val;
                                                      if (val != 'Others')
                                                        _otherCategoryController
                                                            .clear();
                                                    });
                                                  },
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.category_outlined,
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.green[700]!,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.green[700]!,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                  horizontal: 16,
                                                ),
                                          ),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.green[700],
                                            size: 20,
                                          ),
                                          dropdownColor: Colors.white,
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Category is required';
                                            if (v == 'Others' &&
                                                _otherCategoryController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Please specify the category';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                    if (_selectedCategory == 'Others')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Please specify category',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const Text(
                                                  ' *',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller:
                                                  _otherCategoryController,
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(
                                                  Icons.edit_outlined,
                                                  size: 20,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 16,
                                                    ),
                                              ),
                                              validator: (v) {
                                                if (_selectedCategory ==
                                                        'Others' &&
                                                    (v == null ||
                                                        v.trim().isEmpty)) {
                                                  return 'Please specify the category';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    // Unit
                                    _buildTextField(
                                      controller: _unitController,
                                      labelText: 'Unit (kg/liters/box)',
                                      hintText: 'e.g. kg, liters, box',
                                      prefixIcon: Icon(
                                        Icons.scale_outlined,
                                        size: 20,
                                      ),
                                      validator: (v) => null,
                                    ),
                                    const SizedBox(height: 16),
                                    // Description
                                    _buildTextField(
                                      controller: _descriptionController,
                                      labelText: 'Description *',
                                      hintText: 'Describe your product...',
                                      maxLines: 4,
                                      prefixIcon: Icon(
                                        Icons.description_outlined,
                                        size: 20,
                                      ),
                                      validator:
                                          (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Description is required'
                                                  : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // --- Pricing Section ---
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              margin: const EdgeInsets.only(bottom: 28),
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.green[700],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.local_offer,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pricing',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            fontFamily: 'Lato',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Price
                                    _buildTextField(
                                      controller: _priceController,
                                      labelText: 'Price (₦) *',
                                      hintText: '0.00',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      prefixText: '₦ ',
                                      prefixIcon: Icon(
                                        Icons.local_offer,
                                        size: 20,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        ThousandsSeparatorInputFormatter(),
                                      ],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter a valid price';
                                        final cleaned = v.replaceAll(',', '');
                                        final price = double.tryParse(cleaned);
                                        if (price == null || price <= 0)
                                          return 'Enter a valid price';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Quantity
                                    _buildTextField(
                                      controller: _quantityController,
                                      labelText: 'Quantity *',
                                      hintText: 'Enter quantity',
                                      keyboardType: TextInputType.number,
                                      prefixIcon: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Quantity is required';
                                        final quantity = int.tryParse(v.trim());
                                        if (quantity == null || quantity <= 0)
                                          return 'Enter a valid quantity';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // --- Submit Button ---
                            AnimatedScale(
                              scale: _isLoading ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () => saveOrUpdateDraft(),
                                  icon: Icon(
                                    Icons.save_alt,
                                    color: Colors.green[700],
                                  ),
                                  label: Text(
                                    'Save as Draft',
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.green[700]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedScale(
                              scale: _isLoading ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : createOrUpdateProduct,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    elevation: 4,
                                  ),
                                  child:
                                      _isLoading
                                          ? const CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          )
                                          : const Text('Sell'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixIcon,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              labelText.replaceAll(' *', ''),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (labelText.contains('*') || requiredField)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            // labelText: labelText, // Remove floating label
            hintText: hintText,
            prefixText: prefixText,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          enabled: !_isLoading,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  Widget _buildMediaPickerGrid() {
    final media = [
      ..._pickedImages.map((x) => {'type': 'image', 'file': x}),
      ..._pickedVideos.map((x) => {'type': 'video', 'file': x}),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImages,
              icon: Icon(Icons.photo_library),
              label: Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickVideos,
              icon: Icon(Icons.videocam),
              label: Text('Add Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (media.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = media[index];
              final type = item['type'];
              final file = item['file'] as XFile;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        type == 'image'
                            ? Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                            : Container(
                              color: Colors.black12,
                              child: Center(
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.blueGrey,
                                  size: 40,
                                ),
                              ),
                            ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (type == 'image') {
                            _pickedImages.remove(file);
                          } else {
                            _pickedVideos.remove(file);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class SomeOtherWidget extends StatelessWidget {
  const SomeOtherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductCreateScreen()),
          );
        } else {
          // Show login prompt or error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to create a product.')),
          );
        }
      },
      child: Text('Go to Product Create Screen'),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String newText = newValue.text.replaceAll(',', '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue; // Keep old value if not a valid number
    }

    final String formattedText = _formatNumber(number);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatNumber(int number) => number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}
