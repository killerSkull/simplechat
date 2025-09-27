import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;

  const FullScreenMediaViewer({super.key, this.imageUrl, this.videoUrl})
      : assert(imageUrl != null || videoUrl != null);

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  // --- NUEVO: Estado para controlar la visibilidad de la UI ---
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            // No lo ponemos en bucle para que el usuario pueda ver el final
            // _videoController!.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _saveMedia() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final hasPermission = await Gal.requestAccess();
      if (hasPermission) {
        if (widget.imageUrl != null) {
          final response = await http.get(Uri.parse(widget.imageUrl!));
          final bytes = response.bodyBytes;
          await Gal.putImageBytes(bytes);
        } else if (widget.videoUrl != null) {
          await Gal.putVideo(widget.videoUrl!);
        }
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('¡Guardado en la galería!')),
          );
        }
      } else {
         if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Permiso denegado para acceder a la galería.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Error al guardar.')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // --- MODIFICADO: La AppBar ahora depende del estado _showControls ---
      appBar: _showControls ? AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _saveMedia,
                ),
        ],
      ) : null,
      // --- MODIFICADO: GestureDetector para mostrar/ocultar controles ---
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Center(
          child: widget.imageUrl != null
              ? InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
                )
              : (_videoController != null && _videoController!.value.isInitialized
                  // --- MODIFICADO: Stack para superponer los controles de video ---
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        // --- NUEVO: Controles de video con línea de tiempo ---
                        if (_showControls)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                    });
                                  },
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.white,
                                      bufferedColor: Colors.grey,
                                      backgroundColor: Colors.transparent
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    )
                  : const CircularProgressIndicator()),
        ),
      ),
    );
  }
}
