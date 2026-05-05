import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGeneratingAI = false;
  List<String> _categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Umum Rusak',
    'Pipa Bocor',
    'Vadalisme',
    'Banjir',
    'Lainnya',
  ];

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: _categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _aiCategory = category;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage != null) {
        setState(() {
          _base64Image = base64Encode(compressedImage);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error compressing image: $e')));
      }
    }
  }

  Future<void> _generateDescriptionAI() async {
    if (_image == null) return;
    setState(() => _isGeneratingAI = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview:generateContent',
        apiKey: 'AIzaSyCXbm8sCRTWm91zQBBXwkGvG-WMl2vD8nk',
      );
      final imageBytes = await _image!.readAsBytes();
      final content = Content.multi({
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori utama kerusakan fasilitas umum '
          'dari daftar berikut: Jalan Rusak, Marka Pudar, Lampu Mati, Trotoar Rusak, '
          'Rambu Rusak, Jembatan Rusak, Sampah Menumpuk, Saluran Tersumbat, Sungai Tercemar, '
          'Sampah Sungai, Pohon Tumbang, Taman Rusak, Fasilitas Rusak, Pipa Bocor, '
          'Vandalisme, Banjir, dan Lainnya. '
          'Pilih kategori yang paling dominan atau paling mendesak untuk dilaporkan. '
          'Buat deskripsi singkat untuk laporan perbaikan, dan tambahkan permohonan perbaikan. '
          'Fokus pada kerusakan yang terlihat dan hindari spekulasi.\n\n'
          'Format output yang diinginkan:\n'
          'Kategori: [satu kategori yang dipilih]\n'
          'Deskripsi: [deskripsi singkat]',
        ),
      });
      final response = await model.generateContent({content});
      final aiText = response.text;
      print('ai text: $aiText');
      if (aiText != null && aiText.isNotEmpty) {
        final lines = aiText.trim().split('\n');
        String? category;
        String? description;
        for (var line in lines) {
          final lower = line.toLowerCase();
          if (lower.startsWith('kategori:')) {
            category = line.substring(9).trim();
          } else if (lower.startsWith('deskripsi:')) {
            description = line.substring(10).trim();
          } else if (lower.startsWith('keterangan:')) {
            description = line.substring(11).trim();
          }
        }
        description ??= aiText.trim();
        setState(() {
          _aiCategory = category ?? 'tidak diketahui';
          _aiDescription = description;
          _descriptionController.text = _aiDescription!;
        });
      }
    } catch (e) {
      debugPrint('Error generating AI description: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve location: $e')),
      );
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image and description')),
      );
      return;
    }
    setState(() => _isUploading = true);
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please sign in.')),
      );
      return;
    }
    try {
      await _getLocation();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final fullName = userDoc.data()?['fullbane'] ?? 'Annonymus';
      await FirebaseFirestore.instance.collection('post').add({
        'image': _base64Image,
        'description': _descriptionController.text,
        'category': _aiCategory ?? 'Tidak diketahui',
        'createdAt': now,
        'latitude': _latitude,
        'longitude': _longitude,
        'fullName': fullName,
        'userId': uid,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully!')),
      );
    } catch (e) {
      debugPrint('Upload Failed: $e');
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload the post : $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage((ImageSource.gallery));
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(onTap: _showImageSourceDialog, child: Container()),
            const SizedBox(height: 16),
            if (_isGeneratingAI) Shimmer.fromColors(),
            if (_aiCategory != null && !_isGeneratingAI)
              Padding(padding: EdgeInsetsGeometry.all(15)),
            Offstage(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitPost,
              child: const Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}
