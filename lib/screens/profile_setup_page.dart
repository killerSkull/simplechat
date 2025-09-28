import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:simplechat/services/storage_service.dart';
import '../services/firestore_service.dart';

class ProfileSetupPage extends StatefulWidget {
  final User user;
  const ProfileSetupPage({super.key, required this.user});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  File? _imageFile;
  bool _isSaving = false;
  bool _isPickingImage = false;

  Country _selectedCountry = Country(
    phoneCode: '1', countryCode: 'US', e164Sc: 0, geographic: true, level: 1,
    name: 'United States', example: '2015550123',
    displayName: 'United States (US) [+1]',
    displayNameNoCountryCode: 'United States (US)', e164Key: '1-US-0',
  );

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
    _statusController.text = '¡Hola! Estoy usando SimpleChat.';
  }

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
        final uploadTask = _storageService.uploadProfileImage(
          userId: widget.user.uid,
          file: _imageFile!,
        );
        photoUrl = await (await uploadTask).ref.getDownloadURL();
      }

      final fullPhoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';

      await _firestoreService.updateUserProfile(
        uid: widget.user.uid,
        displayName: _nameController.text.trim(),
        status: _statusController.text.trim(),
        phoneNumber: fullPhoneNumber,
        photoUrl: photoUrl ?? widget.user.photoURL,
        // --- CORRECCIÓN CRÍTICA ---
        // Se establece 'profileCompleted' en true.
        // Sin esto, la app te enviaría a esta pantalla en un bucle infinito.
        profileCompleted: true, 
      );

      // No necesitamos setState(false) porque AuthGate nos llevará a la siguiente pantalla
      // una vez que el perfil esté marcado como completo.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar para la foto de perfil
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.user.photoURL != null
                                ? NetworkImage(widget.user.photoURL!)
                                : null) as ImageProvider?,
                        child: _imageFile == null && widget.user.photoURL == null
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
                  // Campo de nombre
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
                  // Campo de estado
                  TextFormField(
                    controller: _statusController,
                    decoration: const InputDecoration(labelText: 'Tu Estado'),
                  ),
                  const SizedBox(height: 16),
                   // Campo de teléfono con selector de país
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Número de teléfono',
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
                            '${_selectedCountry.flagEmoji} +${_selectedCountry.phoneCode}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                     validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, introduce tu número de teléfono.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Botón de guardar
                  _isSaving
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Guardar y Continuar'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}