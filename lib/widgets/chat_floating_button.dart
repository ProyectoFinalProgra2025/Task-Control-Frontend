import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../services/storage_service.dart';

/// Botón flotante de chat accesible desde cualquier pantalla
class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'chat_fab',
          onPressed: () => _openChat(context),
          icon: const Icon(
            Icons.chat,
            color: Colors.white,
            size: 24,
          ),
          label: const Text(
            'Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) async {
    // Verificar si el usuario está autenticado
    final storage = StorageService();
    final token = await storage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      // Navegar a la lista de chats
      Navigator.of(context).pushNamed('/chat');
    } else {
      // Mostrar snackbar indicando que debe iniciar sesión
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Debes iniciar sesión para acceder al chat',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Widget que envuelve a un hijo y añade el botón flotante de chat
class ChatFloatingButtonWrapper extends StatelessWidget {
  final Widget child;
  final bool showFloatingButton;

  const ChatFloatingButtonWrapper({
    super.key,
    required this.child,
    this.showFloatingButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showFloatingButton) const ChatFloatingButton(),
      ],
    );
  }
}