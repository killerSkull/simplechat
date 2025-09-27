import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/services/storage_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  // --- CAMBIO: El widget ahora espera recibir el userId ---
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  File? _imageFile;
  bool _isSaving = false;
  bool _isPickingImage = false;

  Country? _selectedCountry;

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
    
    if (mounted) {
       setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = (await _storageService.uploadProfileImage(
          userId: widget.userId,
          file: _imageFile!,
        )) as String?;
      }
      
      String? fullPhoneNumber;
      if (_phoneController.text.isNotEmpty && _selectedCountry != null) {
        fullPhoneNumber = '+${_selectedCountry!.phoneCode}${_phoneController.text.trim()}';
      }

      await _firestoreService.updateUserProfile(
        uid: widget.userId,
        displayName: _nameController.text.trim(),
        status: _statusController.text.trim(),
        phoneNumber: fullPhoneNumber,
        photoUrl: photoUrl,
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                )
        ],
      ),
      body: SafeArea(
        // --- CAMBIO: El StreamBuilder ahora usa widget.userId ---
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('No se pudo cargar el perfil.'));
            }
            
            final user = UserModel.fromFirestore(snapshot.data!);
            _nameController.text = user.displayName ?? '';
            _statusController.text = user.status ?? '';
            // No pre-llenamos el teléfono para que el usuario pueda cambiarlo si quiere.
            
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                                    ? NetworkImage(user.photoUrl!)
                                    : null) as ImageProvider?,
                            child: _imageFile == null && (user.photoUrl == null || user.photoUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tu Nombre'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, introduce tu nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _statusController,
                        decoration: const InputDecoration(labelText: 'Tu Estado'),
                      ),
                      const SizedBox(height: 24),
                      Text("Número de teléfono actual: ${user.phoneNumber ?? 'No establecido'}", style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Introduce un nuevo número (opcional)',
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: InkWell(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  countryListTheme: const CountryListThemeData(bottomSheetHeight: 500),
                                  onSelect: (value) => setState(() => _selectedCountry = value),
                                );
                              },
                              child: Text(
                                _selectedCountry != null
                                  ? '${_selectedCountry!.flagEmoji} +${_selectedCountry!.phoneCode}'
                                  : 'País',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}