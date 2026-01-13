import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final MapController? controller;
  final void Function(TapPosition, LatLng)? onTap;

  const OsmMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers,
    this.polylines,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dzdelivery.app',
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
      width: 50,
      height: 50,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D32),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 30),
      ),
    );
  }

  static Marker restaurant(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE65100),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
      ),
    );
  }

  static Marker client(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1976D2),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 22),
      ),
    );
  }

  static Marker currentLocation(LatLng position) {
    return Marker(
      point: position,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.my_location, color: Colors.blue, size: 16),
        ),
      ),
    );
  }
}
