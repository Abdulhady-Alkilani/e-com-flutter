import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/shimmer_loading.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      _nameCtrl.text = auth.currentUser!.name;
      _emailCtrl.text = auth.currentUser!.email;
      _phoneCtrl.text = auth.currentUser!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('select_image')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: Text(context.tr('camera')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: Text(context.tr('gallery')),
          ),
        ],
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordCtrl.text.isNotEmpty && _passwordCtrl.text != _passwordConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwords_dont_match')), backgroundColor: AppColors.error),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      password: _passwordCtrl.text,
      passwordConfirmation: _passwordConfirmCtrl.text,
      avatarPath: _selectedImage?.path,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('update_success')), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? context.tr('server_error')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: auth.isLoading
          ? const ShimmerForm()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _selectedImage != null
                                  ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                  : (user?.avatar != null
                                      ? DecorationImage(image: CachedNetworkImageProvider(user!.avatar!), fit: BoxFit.cover)
                                      : null),
                            ),
                            child: (_selectedImage == null && user?.avatar == null)
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr('name'),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr('phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordConfirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('password_confirm'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('save_changes'), style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
