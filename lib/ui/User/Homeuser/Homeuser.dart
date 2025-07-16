import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/ui/User/Individual/Individual.dart';
import 'package:sem4_fe/ui/User/Notification/Notification.dart';
import 'package:sem4_fe/ui/User/Propose/Propose.dart';
import 'package:sem4_fe/ui/User/QR/Qrscanner.dart';
import 'package:sem4_fe/ui/User/QR/Facecame.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/WorkHistory.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/histotyqr.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Information.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;

  const HomeScreen({
    Key? key,
    required this.username,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _selectedIndex = 0;

  Map<String, dynamic>? lastCheckInData;
  bool hasCheckedIn = false;
  bool hasCheckedOut = false;
  String? lastAttendanceDate;
  String? avatarUrl;
  bool isLoadingAvatar = false;
  String? positionName;
  List<dynamic> workShifts = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    fetchUserInfo();
    _loadAttendanceStatus();
    _loadAvatar();
    fetchWorkShifts();
  }

  Future<void> _loadAvatar() async {
    if (mounted) setState(() => isLoadingAvatar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) return;

      final employeeIdRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeIdRes.statusCode != 200) return;

      final employeeId = employeeIdRes.body.trim();
      await prefs.setString('employeeId', employeeId);

      final detailRes = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (detailRes.statusCode == 200) {
        final data = json.decode(detailRes.body);
        final base64Img = data['img']?.toString().trim() ?? '';

        if (mounted) {
          setState(() {
            userData?['img'] = base64Img;
            positionName = data['positionName'];
            isLoadingAvatar = false;
          });
        }
      }
    } catch (e) {
      print("❗ Lỗi avatar: $e");
      if (mounted) setState(() => isLoadingAvatar = false);
    }
  }

  Future<void> _loadAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = prefs.getString('lastAttendanceDate');

    if (storedDate != currentDate) {
      await prefs.setBool('hasCheckedIn', false);
      await prefs.setBool('hasCheckedOut', false);
      await prefs.setString('lastAttendanceDate', currentDate);
      setState(() {
        hasCheckedIn = false;
        hasCheckedOut = false;
        lastAttendanceDate = currentDate;
      });
    } else {
      setState(() {
        hasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
        hasCheckedOut = prefs.getBool('hasCheckedOut') ?? false;
        lastAttendanceDate = storedDate;
      });
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.homeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['result'] != null) {
          List users = responseData['result'];
          final user = users.firstWhere(
                (u) => u['username'] == widget.username,
            orElse: () => null,
          );

          setState(() {
            userData = user != null ? Map<String, dynamic>.from(user) : null;
            isLoading = false;
          });
        } else {
          throw Exception('Không có dữ liệu người dùng trong kết quả');
        }
      } else {
        throw Exception('Không thể lấy thông tin người dùng (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải người dùng: $e')),
      );
    }
  }

  Future<String?> fetchEmployeeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) return null;

      final employeeIdRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeIdRes.statusCode != 200) return null;

      final employeeId = employeeIdRes.body.trim();
      if (employeeId.isEmpty) return null;

      await prefs.setString('employeeId', employeeId);

      final detailRes = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (detailRes.statusCode == 200) {
        final data = json.decode(detailRes.body);
        final img = (data['img'] ?? '').toString().trim();
        final fullImgUrl = img.isNotEmpty
            ? (img.startsWith('http') ? img : '${Constants.baseUrl}${img.startsWith('/') ? '' : '/'}$img')
            : null;

        if (mounted) {
          setState(() {
            avatarUrl = fullImgUrl;
            positionName = data['positionName'];
          });
        }
        return fullImgUrl;
      }
      return null;
    } catch (e) {
      print('❗ Lỗi khi fetch avatar: $e');
      return null;
    }
  }

  Future<void> _handleCheckInResult(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();

    if (result['type'] == 'checkin') {
      setState(() => hasCheckedIn = true);
      await prefs.setBool('hasCheckedIn', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chấm công vào thành công!')),
      );
    } else if (result['type'] == 'checkout') {
      setState(() => hasCheckedOut = true);
      await prefs.setBool('hasCheckedOut', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chấm công ra thành công!')),
      );
    }

    if (result['shifts'] != null) {
      setState(() {
        workShifts = result['shifts'];
      });
    } else {
      await fetchWorkShifts();
    }

    await fetchUserInfo();
    await _loadAttendanceStatus();
  }

  Future<void> fetchWorkShifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final employeeId = prefs.getString('employeeId');
      if (token == null || employeeId == null) return;

      final response = await http.get(
        Uri.parse(Constants.qrAttendancesByEmployeeUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        data.sort((a, b) => DateTime.parse(b['scanTime']).compareTo(DateTime.parse(a['scanTime'])));

        Map<String, dynamic>? checkIn, checkOut;
        for (var record in data) {
          if (record['status'] == 'CheckIn' && checkIn == null) {
            checkIn = record;
          } else if (record['status'] == 'CheckOut' && checkOut == null) {
            checkOut = record;
          }
          if (checkIn != null && checkOut != null) break;
        }

        setState(() {
          workShifts = [
            {
              'checkInTime': checkIn?['scanTime'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(checkIn!['scanTime']))
                  : '---',
              'checkOutTime': checkOut?['scanTime'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(checkOut!['scanTime']))
                  : '---',
            }
          ];
        });
      }
    } catch (e) {
      print('Lỗi fetchWorkShifts (QR): $e');
    }
  }

  ImageProvider _buildAvatarFromBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return const AssetImage('assets/images/avatar_placeholder.png');
    }
    try {
      return MemoryImage(base64Decode(base64Str));
    } catch (e) {
      print("Lỗi decode ảnh base64: $e");
      return const AssetImage('assets/images/avatar_placeholder.png');
    }
  }

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(token: widget.token),
      ),
    ).then((result) async {
      if (result != null && result['status'] == 'success') {
        await _handleCheckInResult(result);
      }
    });
  }

  void _navigateToFaceAttendance() async {
    if (hasCheckedIn && hasCheckedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã hoàn thành chấm công trong ngày hôm nay')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceAttendanceScreen(),
      ),
    );
    if (result != null && result['status'] == 'success') {
      await _handleCheckInResult(result);
    }
  }

  void _navigateToWorkHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkHistoryScreen(token: widget.token),
      ),
    );
  }

  void _navigateToAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryScreen(token: widget.token),
      ),
    );
  }

  void showCheckInOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn phương thức chấm công',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              _navigateToFaceAttendance();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.gps_fixed, color: Colors.blue, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    'GPS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              _navigateToQRScanner();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.qr_code_2, color: Colors.green, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    'QR Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.orange),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userData == null) {
      return const Center(child: Text("Không tìm thấy người dùng"));
    }

    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _buildAvatarFromBase64(userData?['img']),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào,",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData!['fullName'] ?? widget.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          positionName ?? 'Cộng tác viên kinh doanh',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: showCheckInOptions,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        "Chấm công",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _quickActionButton(
                      icon: Icons.calendar_today,
                      label: "Lịch làm việc",
                      color: Colors.orange.shade100,
                      onTap: _navigateToWorkHistory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionButton(
                      icon: Icons.history,
                      label: "Lịch sử chấm công",
                      color: Colors.orange.shade100,
                      onTap: _navigateToAttendanceHistory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void refreshAvatar() async {
    final url = await fetchEmployeeAvatar();
    if (mounted) {
      setState(() {
        avatarUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      ProposalPage(),
      NotificationPage(token: widget.token),
      PersonalPage(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Đề xuất'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}