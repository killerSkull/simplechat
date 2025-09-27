import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart'; // <-- CORRECCIÓN AQUÍ

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _phoneController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  QueryDocumentSnapshot? _foundUserDoc;
  String _feedbackMessage = '';

  Country _selectedCountry = Country(
    phoneCode: '1', countryCode: 'US', e164Sc: 0, geographic: true, level: 1,
    name: 'United States', example: '2015550123',
    displayName: 'United States (US) [+1]',
    displayNameNoCountryCode: 'United States (US)', e164Key: '1-US-0',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _feedbackMessage = 'Por favor, introduce un número de teléfono.';
        _foundUserDoc = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = '';
      _foundUserDoc = null;
    });

    final fullPhoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    final result = await _firestoreService.searchUserByPhone(fullPhoneNumber);

    if (!mounted) return;

    if (result.docs.isEmpty) {
      setState(() {
        _feedbackMessage = 'No se encontró ningún usuario con ese número.';
      });
    } else {
      final foundUser = result.docs.first;
      if (foundUser.id == _currentUser?.uid) {
         setState(() => _feedbackMessage = 'No puedes añadirte a ti mismo.');
      } else {
         setState(() => _foundUserDoc = foundUser);
      }
    }
    setState(() => _isLoading = false);
  }
  
  Future<void> _showAddContactDialog(UserModel user) async {
    final nicknameController = TextEditingController(text: user.displayName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Añadir a ${user.displayName}'),
          content: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(labelText: 'Guardar como (apodo)'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nickname = nicknameController.text.trim();
                if (nickname.isNotEmpty) {
                  await _addContact(user.uid, nickname);
                  if(mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addContact(String contactUid, String nickname) async {
    final isAlreadyContact = await _firestoreService.isContact(contactUid);

    if (isAlreadyContact) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este usuario ya está en tus contactos.')),
        );
      }
      return;
    }
    
    await _firestoreService.addContact(contactUid, nickname);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Contacto añadido con éxito!')),
      );
      setState(() {
        _foundUserDoc = null;
        _phoneController.clear();
        _feedbackMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Contacto'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchUser,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading) const CircularProgressIndicator(),
              if (_feedbackMessage.isNotEmpty) Text(_feedbackMessage),
              if (_foundUserDoc != null) _buildFoundUserTile(_foundUserDoc!),
              
              const Divider(height: 40),
              const Text('Tus Contactos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: _buildContactsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoundUserTile(QueryDocumentSnapshot userDoc) {
    final user = UserModel.fromFirestore(userDoc);
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
            ? CachedNetworkImageProvider(user.photoUrl!)
            : null,
        child: user.photoUrl == null || user.photoUrl!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.displayName ?? 'Usuario'),
      subtitle: Text(user.status ?? ''),
      trailing: ElevatedButton(
        onPressed: () => _showAddContactDialog(user),
        child: const Text('Añadir'),
      ),
    );
  }

  Widget _buildContactsList() {
    return StreamBuilder<Map<String, String>>(
      stream: _firestoreService.getContactsMapStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final contactsMap = snapshot.data ?? {};
        if (contactsMap.isEmpty) {
          return const Center(child: Text('Aún no has añadido a nadie.', style: TextStyle(color: Colors.grey)));
        }

        final contactUids = contactsMap.keys.toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: contactUids)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No se encontraron perfiles de tus contactos.'));
            }

            final users = userSnapshot.data!.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final nickname = contactsMap[user.uid];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(nickname ?? user.displayName ?? 'Usuario'),
                  subtitle: Text(user.status ?? ''),
                  onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(otherUser: user, nickname: nickname)),
                      );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}