import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<DocumentSnapshot> selectedMessages;
  final VoidCallback onExitSelection;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const SelectionAppBar({
    super.key,
    required this.selectedMessages,
    required this.onExitSelection,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // El botón de copiar solo se muestra si se ha seleccionado 1 solo mensaje
    // y si ese mensaje contiene texto.
    final canCopy = selectedMessages.length == 1 &&
        (selectedMessages.first.data() as Map<String, dynamic>)
            .containsKey('text');

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onExitSelection,
      ),
      title: Text('${selectedMessages.length} seleccionado(s)'),
      actions: [
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
