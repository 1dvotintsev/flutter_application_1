import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';

enum _IdentifyState { idle, photoSelected, loading }

class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  _IdentifyState _state = _IdentifyState.idle;
  File? _selectedFile;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, maxWidth: 1024);
    if (xfile == null) return;
    setState(() {
      _selectedFile = File(xfile.path);
      _state = _IdentifyState.photoSelected;
    });
  }

  Future<void> _identify() async {
    if (_selectedFile == null) return;
    setState(() => _state = _IdentifyState.loading);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final base64Str = base64Encode(bytes);
      final result =
          await ref.read(apiServiceProvider).identifyPlant(base64Str);
      if (mounted) {
        context.push('/identify/result', extra: result);
        setState(() => _state = _IdentifyState.idle);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _IdentifyState.photoSelected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Определить растение')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _IdentifyState.idle:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Сфотографируйте растение'),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        );

      case _IdentifyState.photoSelected:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedFile!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _identify,
                  child: const Text('Определить растение'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _state = _IdentifyState.idle),
                  child: const Text('Выбрать другое'),
                ),
              ),
            ],
          ),
        );

      case _IdentifyState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Определяем растение...'),
            ],
          ),
        );
    }
  }
}
