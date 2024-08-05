import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart';
import 'package:telenant/utils/tile_servers.dart';
import 'package:telenant/utils/utils.dart';

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({super.key});

  @override
  InteractiveMapPageState createState() => InteractiveMapPageState();
}

class InteractiveMapPageState extends State<InteractiveMapPage> {
  final controller = MapController(
    location: const LatLng(Angle.degree(16.41385), Angle.degree(120.59135)),
  );

  void _gotoDefault() {
    controller.center = const LatLng(
      Angle.degree(16.41385),
      Angle.degree(120.59135),
    );
    setState(() {});
  }

  void _onDoubleTap(MapTransformer transformer, Offset position) {
    const delta = 0.5;
    final zoom = clamp(controller.zoom + delta, 2, 18);

    transformer.setZoomInPlace(zoom, position);
    setState(() {});
  }

  Offset? _dragStart;
  double _scaleStart = 1.0;
  void _onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;
    _scaleStart = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, MapTransformer transformer) {
    final scaleDiff = details.scale - _scaleStart;
    _scaleStart = details.scale;

    if (scaleDiff > 0) {
      controller.zoom += 0.02;
      setState(() {});
    } else if (scaleDiff < 0) {
      controller.zoom -= 0.02;
      setState(() {});
    } else {
      final now = details.focalPoint;
      final diff = now - _dragStart!;
      _dragStart = now;
      transformer.drag(diff.dx, diff.dy);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Map'),
      ),
      body: MapLayout(
        controller: controller,
        builder: (context, transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (details) => _onDoubleTap(
              transformer,
              details.localPosition,
            ),
            onScaleStart: _onScaleStart,
            onScaleUpdate: (details) => _onScaleUpdate(details, transformer),
            onTapUp: (details) async {
              final location = transformer.toLatLng(details.localPosition);

              // Store the current context in a local variable
              final currentContext = context;

              // Show loading dialog
              showDialog(
                context: currentContext,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Loading ...'),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              );

              // Perform the asynchronous operation
              await placemarkFromCoordinates(
                location.latitude.degrees,
                location.longitude.degrees,
              ).then((value) {
                Navigator.of(currentContext).pop();
                print(value);
                showDialog(
                  context: currentContext,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'You have clicked on ${value.first.street} street, ${value.first.locality}, ${value.first.subAdministrativeArea}',
                        ),
                        ElevatedButton(
                            onPressed: () {
                              Map<String, dynamic> result = {
                                'locationText':
                                    '${value.first.street} street, ${value.first.locality}, ${value.first.subAdministrativeArea}',
                                'locationLatLng': location
                              };
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(result);
                            },
                            child: const Text('Confirm Location'))
                      ],
                    ),
                  ),
                );
              }).onError((error, stackTrace) {
                Navigator.of(context).pop();
                showDialog(
                  context: currentContext,
                  builder: (context) => AlertDialog(
                    content: Text(
                      'Error: ${error.toString()} and StackTrace: ${stackTrace.toString()}',
                    ),
                  ),
                );
              });
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final delta = event.scrollDelta.dy / -1000.0;
                  final zoom = clamp(controller.zoom + delta, 2, 18);

                  transformer.setZoomInPlace(zoom, event.localPosition);
                  setState(() {});
                }
              },
              child: Stack(
                children: [
                  TileLayer(
                    builder: (context, x, y, z) {
                      final tilesInZoom = pow(2.0, z).floor();

                      while (x < 0) {
                        x += tilesInZoom;
                      }
                      while (y < 0) {
                        y += tilesInZoom;
                      }

                      x %= tilesInZoom;
                      y %= tilesInZoom;

                      return CachedNetworkImage(
                        imageUrl: google(z, x, y),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _gotoDefault,
        tooltip: 'My Location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
