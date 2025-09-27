import 'package:flutter/material.dart';

// Este widget auxiliar se usa dentro de la función `showAttachmentMenu`
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

// Esta función muestra el menú
Future<void> showAttachmentMenu(
  BuildContext context, {
  required VoidCallback onPickFromGallery,
  required VoidCallback onPickFromCamera,
  required VoidCallback onPickMusic,
  required VoidCallback onPickContact,
  required VoidCallback onPickDocument,
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext bc) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 15,
          crossAxisSpacing: 10,
          children: [
            _AttachmentButton(
              icon: Icons.photo_library,
              color: Colors.purple,
              label: 'Galería',
              onTap: () {
                Navigator.of(context).pop();
                onPickFromGallery();
              },
            ),
            _AttachmentButton(
              icon: Icons.camera_alt,
              color: Colors.red,
              label: 'Cámara',
              onTap: () {
                Navigator.of(context).pop();
                onPickFromCamera();
              },
            ),
            _AttachmentButton(
              icon: Icons.headset,
              color: Colors.orange,
              label: 'Audio',
              onTap: () {
                Navigator.of(context).pop();
                onPickMusic();
              },
            ),
            _AttachmentButton(
              icon: Icons.person,
              color: Colors.blue,
              label: 'Contacto',
              onTap: () {
                Navigator.of(context).pop();
                onPickContact();
              },
            ),
            _AttachmentButton(
              icon: Icons.insert_drive_file,
              color: Colors.indigo,
              label: 'Documento',
              onTap: () {
                Navigator.of(context).pop();
                onPickDocument();
              },
            ),
            _AttachmentButton(
              icon: Icons.location_on,
              color: Colors.green,
              label: 'Ubicación',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de ubicación próximamente.')),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}