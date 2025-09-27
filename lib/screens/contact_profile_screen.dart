import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simplechat/services/firestore_service.dart';
import '../models/user_model.dart';

// --- MODIFICADO: Convertido a StatefulWidget para manejar el estado ---
class ContactProfileScreen extends StatefulWidget {
  final UserModel user;
  final String? nickname;

  const ContactProfileScreen({super.key, required this.user, this.nickname});

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  final _firestoreService = FirestoreService();
  late String _currentNickname;

  @override
  void initState() {
    super.initState();
    _currentNickname = widget.nickname ?? widget.user.displayName ?? 'Usuario';
  }

  // --- NUEVO: Maneja la selección del menú ---
  void _onMenuSelected(String value) {
    switch (value) {
      case 'share':
        final contactInfo =
            'Mira el contacto de ${_currentNickname}:\nTeléfono: ${widget.user.phoneNumber ?? 'No disponible'}';
        Share.share(contactInfo);
        break;
      case 'edit':
        _showEditNicknameDialog();
        break;
      case 'delete':
        _showDeleteConfirmationDialog();
        break;
      case 'block':
        // Lógica de bloqueo aquí (próximamente)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función de bloqueo próximamente.')),
        );
        break;
    }
  }

  // --- NUEVO: Muestra diálogo para editar el apodo ---
  void _showEditNicknameDialog() {
    final nicknameController = TextEditingController(text: _currentNickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Apodo'),
        content: TextField(
          controller: nicknameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nuevo apodo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNickname = nicknameController.text.trim();
              if (newNickname.isNotEmpty) {
                await _firestoreService.updateContactNickname(widget.user.uid, newNickname);
                setState(() {
                  _currentNickname = newNickname;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // --- NUEVO: Muestra diálogo para confirmar eliminación ---
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contacto'),
        content: Text('¿Seguro que quieres eliminar a $_currentNickname de tus contactos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await _firestoreService.deleteContact(widget.user.uid);
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Vuelve a la pantalla anterior
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        // --- NUEVO: Menú de opciones ---
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'share',
                child: ListTile(leading: Icon(Icons.share), title: Text('Compartir')),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit), title: Text('Editar')),
              ),
              const PopupMenuItem<String>(
                value: 'block',
                child: ListTile(leading: Icon(Icons.block), title: Text('Bloquear')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red.shade400),
                  title: Text('Eliminar Contacto', style: TextStyle(color: Colors.red.shade400)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 80,
                  backgroundImage: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null || widget.user.photoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 80)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.status ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 40),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Teléfono'),
                  subtitle: Text(widget.user.phoneNumber ?? 'No disponible'),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(widget.user.email ?? 'No disponible'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}