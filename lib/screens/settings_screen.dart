import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simplechat/providers/theme_provider.dart';
import 'package:simplechat/screens/profile_screen.dart';
import 'package:simplechat/services/firestore_service.dart';
import '../services/auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Cuenta'),
          content: const Text(
              'Esta acción es irreversible. Se eliminará tu perfil, todos tus contactos y chats. ¿Estás seguro de que quieres continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                // --- OPTIMIZACIÓN: Usar context.read para llamar a un método ---
                final result = await context.read<FirestoreService>().deleteUserAccount();
                if (context.mounted) {
                  if (result == null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                      (route) => false,
                    );
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cuenta eliminada con éxito.')),
                    );
                  } else {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  }
                }
              },
              child: const Text('Eliminar Definitivamente'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- OPTIMIZACIÓN: Se usan los métodos modernos de Provider ---
    // .watch() -> Escucha los cambios y reconstruye el widget. Se usa para mostrar datos.
    final themeProvider = context.watch<ThemeProvider>();
    // .read() -> Llama a un método sin necesidad de escuchar cambios. Es más eficiente.
    final themeSetter = context.read<ThemeProvider>();

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            // --- SECCIÓN DE CUENTA ---
            _buildSectionHeader(context, 'Cuenta'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Perfil'),
                    subtitle: const Text('Edita tu nombre, estado y foto'),
                    onTap: () {
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: currentUser.uid),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
                    title: Text('Eliminar mi cuenta', style: TextStyle(color: Colors.red.shade400)),
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN DE APARIENCIA (CON DROPDOWN) ---
            _buildSectionHeader(context, 'Apariencia'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonFormField<AppTheme>(
                  value: themeProvider.currentTheme,
                  decoration: const InputDecoration(
                    labelText: 'Tema de la aplicación',
                    border: InputBorder.none,
                    icon: Icon(Icons.color_lens_outlined),
                  ),
                  items: AppTheme.values.map((AppTheme theme) {
                    return DropdownMenuItem<AppTheme>(
                      value: theme,
                      child: Text(themeProvider.themeNames[theme] ?? 'Desconocido'),
                    );
                  }).toList(),
                  onChanged: (AppTheme? newTheme) {
                    if (newTheme != null) {
                      // Se usa themeSetter para no reconstruir innecesariamente
                      themeSetter.setTheme(newTheme);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN DE SALIDA ---
            Card(
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade400),
                title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red.shade400)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                     Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir los encabezados de sección
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}