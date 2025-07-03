import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/ui/User/Individual/Individual.dart';
import 'package:sem4_fe/ui/User/Notification/Notification.dart';
import 'package:sem4_fe/ui/User/Propose/Propose.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sem4_fe/ui/User/QR/Qrscanner.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/User/QR/Facecame.dart';
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
    // Thêm dòng này để bật chế độ edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    fetchUserInfo();
    _loadAttendanceStatus();
    _loadAvatar();
    fetchWorkShifts();
  }

  Future<void> _loadAvatar() async {
    if (mounted) {
      setState(() => isLoadingAvatar = true);
    }
    try {
      final url = await fetchEmployeeAvatar();

      if (mounted) {
        setState(() {
          avatarUrl = url;
          isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingAvatar = false);
      }
      print('Error loading avatar: $e');
    }
  }

  Future<void> _loadAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final storedDate = prefs.getString('lastAttendanceDate');

    if (storedDate != currentDate) {
      // New day, reset status
      await prefs.setBool('hasCheckedIn', false);
      await prefs.setBool('hasCheckedOut', false);
      await prefs.setString('lastAttendanceDate', currentDate);
      setState(() {
        hasCheckedIn = false;
        hasCheckedOut = false;
        lastAttendanceDate = currentDate;
      });
    } else {
      // Same day, load status
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

          print('Gọi API chức vụ với ID: ${userData!['positionId']}');
          print('Dữ liệu trả về: $responseData');

          print('userData: $userData');
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

      // Kiểm tra xem đã có employeeId chưa
      String? employeeId = prefs.getString('employeeId');
      if (employeeId == null || employeeId.isEmpty) {
        // Nếu chưa có thì lấy từ API
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
        if (userId == null) return null;

        final employeeIdResponse = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (employeeIdResponse.statusCode != 200) return null;
        employeeId = employeeIdResponse.body.trim();
        if (employeeId.isEmpty) return null;
        await prefs.setString('employeeId', employeeId);
      }

      // Lấy thông tin chi tiết nhân viên
      final employeeDetailResponse = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeDetailResponse.statusCode == 200) {
        final data = json.decode(employeeDetailResponse.body);
        final imageUrl = data['img']?.toString();
        print('Ảnh lấy được từ API: ${data['img']}');

        if (mounted) {
          setState(() {
            avatarUrl = imageUrl != null && imageUrl.isNotEmpty
                ? (!imageUrl.startsWith('http')
                ? '${Constants.baseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl'
                : imageUrl)
                : null;

            positionName = data['positionName']; // 👈 LẤY Ở ĐÂY
          });
        }

        print('Thông tin chi tiết nhân viên: $data');

        // Kiểm tra và xử lý URL ảnh
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Xử lý URL tương đối (nếu cần)
          if (!imageUrl.startsWith('http')) {
            return '${Constants.baseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
          }
          return imageUrl;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi fetchEmployeeAvatar: $e');
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

    // Nếu có dữ liệu ca làm việc mới từ result, cập nhật
    if (result['shifts'] != null) {
      setState(() {
        workShifts = result['shifts'];
      });
    } else {
      // Nếu không, gọi API fetch lại từ server
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

        // Sắp xếp bản ghi theo thời gian giảm dần
        data.sort((a, b) =>
            DateTime.parse(b['scanTime']).compareTo(DateTime.parse(a['scanTime'])));

        // Lấy 2 bản ghi gần nhất: CheckIn & CheckOut
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


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCheckInOption(
                      icon: Icons.gps_fixed,
                      title: 'GPS',
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToFaceAttendance();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCheckInOption(
                      icon: Icons.qr_code,
                      title: 'QrCode',
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToQRScanner();
                      },
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

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(token: widget.token),
      ),
    )..then((result) async {
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

  Widget _buildHomePage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userData == null) {
      return const Center(child: Text("Không tìm thấy người dùng"));
    }

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight + statusBarHeight;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 16,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  // Trong _buildHomePage() của HomeScreen
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
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
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ca làm việc",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...workShifts.map((shift) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vào: ${shift['checkInTime'] ?? '---'}'),
                          Text('Ra: ${shift['checkOutTime'] ?? '---'}'),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: showCheckInOptions,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange,
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 28),
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
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasCheckedIn && hasCheckedOut
                      ? Colors.green.shade100
                      : hasCheckedIn
                      ? Colors.blue.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    hasCheckedIn && hasCheckedOut
                        ? "Hôm nay bạn đã chấm công đầy đủ"
                        : hasCheckedIn
                        ? "Hôm nay bạn đã chấm công vào"
                        : "Hôm nay bạn chưa chấm công",
                    style: TextStyle(
                      color: hasCheckedIn && hasCheckedOut
                          ? Colors.green.shade800
                          : hasCheckedIn
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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

  Widget _buildCheckInOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        onTap: _onItemTapped,
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
