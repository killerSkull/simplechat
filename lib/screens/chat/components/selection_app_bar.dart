import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<DocumentSnapshot> selectedMessages;
  final VoidCallback onExitSelection;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  // --- MEJORA 2: Se recibe el estado de "editable" desde fuera ---
  final bool canEdit;

  const SelectionAppBar({
    super.key,
    required this.selectedMessages,
    required this.onExitSelection,
    required this.onCopy,
    required this.onDelete,
    required this.onEdit,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    // La lógica para saber si se puede copiar se mantiene aquí porque es simple
    bool canCopy = false;
    if (selectedMessages.length == 1) {
      final messageData = selectedMessages.first.data() as Map<String, dynamic>;
      final hasText = messageData.containsKey('text') && (messageData['text'] as String).isNotEmpty;
      canCopy = hasText;
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onExitSelection,
      ),
      title: Text('${selectedMessages.length} seleccionado(s)'),
      actions: [
        // --- MEJORA 2: Se usa la nueva propiedad 'canEdit' para mostrar el botón ---
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: onCopy,
          ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}