import 'package:flutter/material.dart';

Future<String?> showDeleteDialog(BuildContext context, int count) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Eliminar $count mensaje(s)?'),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Eliminar para todos'),
              onTap: () => Navigator.pop(context, 'all'),
            ),
            ListTile(
              title: const Text('Eliminar para mí'),
              onTap: () => Navigator.pop(context, 'me'),
            ),
            ListTile(
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            )
          ],
        ),
      );
    },
  );
}