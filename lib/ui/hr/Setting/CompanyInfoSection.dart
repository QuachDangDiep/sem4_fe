import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class CompanyInfoSection extends StatefulWidget {
  final String username;
  final String token;

  const CompanyInfoSection({super.key, required this.username, required this.token});

  @override
  State<CompanyInfoSection> createState() => _CompanyInfoSectionState();
}

class _CompanyInfoSectionState extends State<CompanyInfoSection> {
  Map<String, dynamic>? location;

  @override
  void initState() {
    super.initState();
    fetchLocationInfo();
  }

  Future<void> fetchLocationInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.locationUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> locations = jsonDecode(response.body);
        if (locations.isNotEmpty) {
          setState(() {
            location = locations.first;
          });
        }
      } else {
        print("Failed to load location: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching location info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin công ty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: location == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Image.asset('assets/hr.png', height: 80),
                  const SizedBox(height: 16),
                  Text(
                    location!['name'] ?? 'Tên công ty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1.2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(Icons.location_on, 'Địa chỉ', location!['address']),
            _buildInfoCard(Icons.language, 'Latitude', location!['latitude']),
            _buildInfoCard(Icons.language, 'Longitude', location!['longitude']),
            _buildInfoCard(Icons.check_circle, 'Trạng thái hoạt động',
                location!['active'] == true ? 'Đang hoạt động' : 'Không hoạt động'),
            _buildInfoCard(Icons.gps_fixed, 'Địa điểm cố định',
                location!['isFixedLocation'] == true ? 'Có' : 'Không'),
            if (location!['status'] != null)
              _buildInfoCard(Icons.verified, 'Trạng thái', location!['status']),
            if (location!['createdBy'] != null)
              _buildInfoCard(Icons.person, 'Người tạo', location!['createdBy']),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, dynamic value) {
    if (value == null) return const SizedBox.shrink(); // Không hiển thị nếu null

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.orange, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(value.toString(),
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                      textAlign: TextAlign.justify),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
