import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final String? imageBase64;
  final String description;
  final DateTime createdAt;
  final String fullName;
  final double? latitude;
  final double? longitude;
  final String category;
  final String heroTag;

  const DetailScreen({
    super.key,
    required this.imageBase64,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
