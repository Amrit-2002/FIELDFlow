import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';

class TaskMapPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;
  final String customerName;

  const TaskMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(latitude, longitude);
    // Approximate worker nearby (simulated offset for demonstration)
    final workerLocation = LatLng(latitude - 0.005, longitude - 0.006);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Navigation Map'),
      ),
      body: Stack(
        children: [
          // OpenStreetMap Layer (Zero paid API keys needed)
          FlutterMap(
            options: MapOptions(
              initialCenter: destination,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.fieldflow.mobile',
              ),
              MarkerLayer(
                markers: [
                  // Customer Destination Pin
                  Marker(
                    point: destination,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.error,
                      size: 44,
                    ),
                  ),
                  // Current Field Technician Location Pin
                  Marker(
                    point: workerLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: AppColors.accent,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Destination Overlay Card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Starting turn-by-turn route to ($latitude, $longitude)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_car, size: 18),
                      label: const Text('Start Turn-By-Turn Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
