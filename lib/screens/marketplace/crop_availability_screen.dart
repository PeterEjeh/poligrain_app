import 'package:flutter/material.dart';

// Crop Availability data model
class CropAvailability {
  final String cropName;
  final String farmName;
  final String timeAgo;

  CropAvailability({
    required this.cropName,
    required this.farmName,
    required this.timeAgo,
  });
}

// Mock crop availability data
final List<CropAvailability> mockCropAvailability = [
  CropAvailability(
    cropName: 'Maize harvest ready',
    farmName: 'Ama Farms',
    timeAgo: '3 mins ago',
  ),
  CropAvailability(
    cropName: 'Fresh tomatoes now available',
    farmName: 'Kwabena Agro',
    timeAgo: '10 mins ago',
  ),
  CropAvailability(
    cropName: 'Sweet potatoes ready for pickup',
    farmName: "Nana's Farm",
    timeAgo: '1 hour ago',
  ),
];

// Simulated API call for crop availability
Future<List<CropAvailability>> fetchCropAvailability() async {
  await Future.delayed(const Duration(seconds: 1));
  return mockCropAvailability;
}

class CropAvailabilityScreen extends StatefulWidget {
  const CropAvailabilityScreen({super.key});

  @override
  State<CropAvailabilityScreen> createState() => _CropAvailabilityScreenState();
}

class _CropAvailabilityScreenState extends State<CropAvailabilityScreen> {
  late Future<List<CropAvailability>> _availabilityFuture;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = fetchCropAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoliGrain Crop Availability'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<CropAvailability>>(
          future: _availabilityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No crop availability updates found.'));
            } else {
              final availability = snapshot.data!;
              return ListView.builder(
                itemCount: availability.length,
                itemBuilder: (context, index) {
                  final item = availability[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cropName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\\${item.farmName} • \\${item.timeAgo}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
} 