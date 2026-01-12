import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker>? markers;
  final List<Polyline>? polylines;

  const OsmMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers,
    this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dzdelivery.customer',
        ),
        if (polylines != null) PolylineLayer(polylines: polylines!),
        if (markers != null) MarkerLayer(markers: markers!),
      ],
    );
  }
}

class MapMarkers {
  static Marker livreur(LatLng position) {
    return Marker(
      point: position,
      width: 45, height: 45,
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 26),
      ),
    );
  }

  static Marker restaurant(LatLng position) {
    return Marker(
      point: position,
      width: 36, height: 36,
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFE65100), shape: BoxShape.circle),
        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
      ),
    );
  }

  static Marker destination(LatLng position) {
    return Marker(
      point: position,
      width: 36, height: 36,
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
        child: const Icon(Icons.home, color: Colors.white, size: 20),
      ),
    );
  }
}
