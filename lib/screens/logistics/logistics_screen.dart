import 'package:flutter/material.dart';

// Logistics Request data model
class LogisticsRequest {
  final String description;
  final String status;
  final String type;

  LogisticsRequest({
    required this.description,
    required this.status,
    required this.type,
  });
}

// Mock logistics request data
final List<LogisticsRequest> mockLogisticsRequests = [
  LogisticsRequest(
    description: 'Pickup for 50 crates of tomatoes',
    status: 'Pending',
    type: 'Pickup',
  ),
  LogisticsRequest(
    description: 'Storage needed for pineapples',
    status: 'In Review',
    type: 'Storage',
  ),
  LogisticsRequest(
    description: 'Delivery of maize to market',
    status: 'Completed',
    type: 'Delivery',
  ),
];

// Simulated API call for logistics requests
Future<List<LogisticsRequest>> fetchLogisticsRequests() async {
  await Future.delayed(const Duration(seconds: 1));
  return mockLogisticsRequests;
}

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  late Future<List<LogisticsRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = fetchLogisticsRequests();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Review':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRequestIcon(String type) {
     switch (type) {
      case 'Pickup':
        return Icons.local_shipping;
      case 'Storage':
        return Icons.warehouse;
      case 'Delivery':
        return Icons.delivery_dining;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoliGrain Logistics'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<LogisticsRequest>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No logistics requests found.'));
            } else {
              final requests = snapshot.data!;
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(_getRequestIcon(request.type), size: 30, color: Theme.of(context).primaryColor), // Use theme color or a specific color
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.description,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: \\${request.status}',
                                  style: TextStyle(color: _getStatusColor(request.status), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
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