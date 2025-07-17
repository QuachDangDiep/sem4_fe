import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/ui/Hr/Staff/Narbar/AddEditStaffScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Staff/Narbar/StaffDetailScreen.dart';

class UserResponse {
  final String id, username, email, role, status;
  final String? shift, img;
  final String? positionName;
  final String? departmentName;
  final String? gender;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? hireDate;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.shift,
    this.img,
    this.positionName,
    this.departmentName,
    this.gender,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.hireDate,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['userId']?.toString() ?? 'Unknown',
    username: json['username'] ?? 'Không xác định',
    email: json['email'] ?? 'Không có email',
    role: json['role']?.toString() ?? 'Không xác định',
    status: json['status'] == 'Active' ? 'Đang làm việc' : (json['status']?.toString() ?? 'Không xác định'),
    shift: json['shift']?.toString(),
    img: json['img']?.toString() ?? 'assets/avatar.jpg',
    positionName: json['positionName']?.toString(),
    departmentName: json['departmentName']?.toString(),
    gender: json['gender']?.toString(),
    phone: json['phone']?.toString(),
    address: json['address']?.toString(),
    dateOfBirth: json['dateOfBirth']?.toString(),
    hireDate: json['hireDate']?.toString(),
  );
}

class StaffScreen extends StatefulWidget {
  final String username, token;

  const StaffScreen({Key? key, required this.token, required this.username}) : super(key: key);

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String? avatarUrl;
  String? positionName;
  String? departmentName;
  String? gender;
  String? phone;
  String? address;
  String? dateOfBirth;
  String? hireDate;
  String? _selectedPosition;
  String? _selectedDepartment;
  String? _userRoleId;
  List<String> _positions = [];
  List<String> _departments = [];
  List<UserResponse> _allUsers = [];
  List<UserResponse> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  late Future<List<UserResponse>> _usersFuture;
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];

  @override
  void initState() {
    super.initState();
    _usersFuture = Future.value([]);
    _initializeUsersFuture();
    fetchEmployeeAvatar();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _initializeUsersFuture() async {
    try {
      final roleId = await getUserRoleId();
      if (roleId != null) {
        _userRoleId = roleId;
        setState(() {
          _usersFuture = fetchUsers(roleId: _userRoleId);
        });
      } else {
        setState(() {
          _usersFuture = Future.error('Không tìm thấy roleId của User');
        });
      }
    } catch (e) {
      setState(() {
        _usersFuture = Future.error('Lỗi khởi tạo dữ liệu: $e');
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployeeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      String? employeeId = prefs.getString('employeeId');
      if (employeeId == null || employeeId.isEmpty) {
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
        if (userId == null) return;

        final employeeIdResponse = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (employeeIdResponse.statusCode != 200) return;
        employeeId = employeeIdResponse.body.trim();
        await prefs.setString('employeeId', employeeId);
      }

      final employeeDetailResponse = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeDetailResponse.statusCode == 200) {
        final data = json.decode(employeeDetailResponse.body);
        print('Chi tiết nhân viên: $data');
        print('Giá trị img: ${data['img']}');
        setState(() {
          avatarUrl = data['img']?.toString();
          positionName = data['positionName']?.toString();
          departmentName = data['departmentName']?.toString();
          gender = data['gender']?.toString();
          phone = data['phone']?.toString();
          address = data['address']?.toString();
          dateOfBirth = data['dateOfBirth']?.toString();
          hireDate = data['hireDate']?.toString();
        });
      }
    } catch (e) {
      print('Lỗi fetchEmployeeAvatar: $e');
    }
  }

  Future<String?> getUserRoleId() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.rolesUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final roles = decoded['result'] ?? [];
        print('Danh sách vai trò: $roles');

        final userRole = roles.firstWhere(
              (role) => role['roleName'] == 'User',
          orElse: () => null,
        );

        if (userRole != null) {
          return userRole['roleId']?.toString();
        }
      } else {
        print('Lỗi lấy danh sách vai trò: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi getUserRoleId: $e');
    }
    return null;
  }

  Future<List<UserResponse>> fetchUsers({String? roleId, String? status}) async {
    try {
      final queryParameters = status != null ? {'status': status} : <String, String>{};
      final uri = Uri.parse(Constants.homeUrl).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final usersRaw = jsonDecode(response.body)['result'] ?? [];
        List<UserResponse> users = [];

        for (final json in usersRaw) {
          if (roleId != null && json['role']?.toString() != roleId) {
            continue;
          }
          String userId = json['userId'].toString();

          final employeeIdResponse = await http.get(
            Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          );

          if (employeeIdResponse.statusCode != 200 || employeeIdResponse.body.trim().isEmpty) {
            continue;
          }

          final employeeId = employeeIdResponse.body.trim();

          final detailResponse = await http.get(
            Uri.parse(Constants.employeeDetailUrl(employeeId)),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          );

          if (detailResponse.statusCode == 200) {
            final detailData = jsonDecode(detailResponse.body);
            print('Chi tiết nhân viên của quản lý nhân sự: $detailData');
            print('Giá trị img: ${detailData['img']}');

            final user = UserResponse.fromJson({
              ...json,
              'positionName': detailData['positionName'],
              'departmentName': detailData['departmentName'],
              'gender': detailData['gender'],
              'phone': detailData['phone'],
              'address': detailData['address'],
              'dateOfBirth': detailData['dateOfBirth'],
              'hireDate': detailData['hireDate'],
              'img': detailData['img']?.toString(),
            });
            users.add(user);
          }
        }
        return users;
      }
      throw Exception('Không thể tải danh sách người dùng: ${response.statusCode}');
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người dùng: $e');
    }
  }

  Future<void> deleteEmployee(String employeeId, String token, BuildContext context) async {
    final response = await http.delete(
      Uri.parse(Constants.employeeDetailUrl(employeeId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa nhân viên thành công')),
      );
    } else {
      final error = jsonDecode(response.body);
      final message = error['message'] ?? 'Đã có lỗi xảy ra';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $message')),
      );
    }
  }

  void refreshUsers() async {
    try {
      if (_userRoleId == null) {
        _userRoleId = await getUserRoleId();
      }
      final users = await fetchUsers(roleId: _userRoleId);
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _usersFuture = Future.value(users);
        _positions = users
            .map((u) => u.positionName ?? '')
            .where((p) => p.isNotEmpty)
            .toSet()
            .toList();
        _departments = users
            .map((u) => u.departmentName ?? '')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
      });
      print('Danh sách người dùng đã được làm mới!');
    } catch (e) {
      print('Lỗi khi làm mới người dùng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi làm mới danh sách: $e')),
      );
      setState(() {
        _usersFuture = Future.error('Lỗi khi làm mới: $e');
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesName = user.username.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesPosition = _selectedPosition == null || user.positionName == _selectedPosition;
        final matchesDepartment = _selectedDepartment == null || user.departmentName == _selectedDepartment;
        return matchesName && matchesPosition && matchesDepartment;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Nền nhẹ nhàng
      appBar: AppBar(
        backgroundColor: colors[1],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quản lý Nhân sự',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            tooltip: 'Thêm nhân viên',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEmployeeScreen(token: widget.token),
                ),
              );
              if (result == true) refreshUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Tìm kiếm nhân viên...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.search, color: colors[2], size: 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors[2], width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors[2].withOpacity(0.3), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors[2], width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final selectedFilters = await showDialog<Map<String, String?>>(
                      context: context,
                      builder: (BuildContext context) {
                        String? selectedPosition = _selectedPosition;
                        String? selectedDepartment = _selectedDepartment;
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text(
                            'Lọc nhân viên',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors[2].withOpacity(0.3)),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedPosition,
                                  hint: const Text('Chọn chức vụ', style: TextStyle(fontSize: 16)),
                                  isExpanded: true,
                                  items: _positions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: const TextStyle(fontSize: 16)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPosition = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors[2].withOpacity(0.3)),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedDepartment,
                                  hint: const Text('Chọn phòng ban', style: TextStyle(fontSize: 16)),
                                  isExpanded: true,
                                  items: _departments.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: const TextStyle(fontSize: 16)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDepartment = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, {
                                'position': selectedPosition,
                                'department': selectedDepartment,
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors[3],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'Lọc',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (selectedFilters != null) {
                      setState(() {
                        _selectedPosition = selectedFilters['position'];
                        _selectedDepartment = selectedFilters['department'];
                        _filterUsers();
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[2], colors[3]],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors[2].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Lọc',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPosition = null;
                      _selectedDepartment = null;
                      _searchController.clear();
                      _filteredUsers = _allUsers;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Xóa lọc',
                      style: TextStyle(
                        color: colors[2],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserResponse>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi: ${snapshot.error}',
                          style: TextStyle(
                            color: colors[2],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: refreshUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors[3],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Thử lại',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy người dùng',
                      style: TextStyle(
                        color: colors[2],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                if (_allUsers.isEmpty) {
                  _allUsers = snapshot.data!;
                  _filteredUsers = _allUsers;
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return StaffCard(
                      name: user.username,
                      id: user.id,
                      status: user.status,
                      shift: user.shift ?? 'Không có ca',
                      image: user.img ?? 'assets/avatar.jpg',
                      colors: colors,
                      positionName: user.positionName,
                      departmentName: user.departmentName,
                      gender: user.gender,
                      phone: user.phone,
                      address: user.address,
                      dateOfBirth: user.dateOfBirth,
                      hireDate: user.hireDate,
                      token: widget.token,
                      onDelete: (employeeId) async {
                        await deleteEmployee(employeeId, widget.token, context);
                        refreshUsers();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshUsers,
        backgroundColor: colors[3],
        elevation: 4,
        child: const Icon(Icons.refresh, size: 28),
      ),
    );
  }
}

Widget _buildTag({required String text, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class StaffCard extends StatelessWidget {
  final String name, id, status, shift, image;
  final String? positionName;
  final String? departmentName;
  final String? gender;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? hireDate;
  final List<Color> colors;
  final String token;
  final Future<void> Function(String employeeId)? onDelete;

  const StaffCard({
    Key? key,
    required this.name,
    required this.id,
    required this.status,
    required this.shift,
    required this.image,
    required this.colors,
    this.positionName,
    this.departmentName,
    this.gender,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.hireDate,
    required this.token,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider getImageProvider() {
      if (image.startsWith('http')) {
        return NetworkImage(image);
      } else if (image.startsWith('/9j/') || image.startsWith('data:image')) {
        try {
          String base64String = image.startsWith('data:image')
              ? image.split(',')[1]
              : image;
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          print('Lỗi giải mã hình ảnh Base64: $e');
          return const AssetImage('assets/avatar.jpg');
        }
      } else {
        return const AssetImage('assets/avatar.jpg');
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDetailScreen(
              employeeId: id,
              fullName: name,
              token: token,
              status: status,
              image: image,
              positionName: positionName,
              departmentName: departmentName,
              gender: gender,
              phone: phone,
              address: address,
              dateOfBirth: dateOfBirth,
              hireDate: hireDate,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[2].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: getImageProvider(),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Lỗi tải hình ảnh: $exception');
                  },
                  child: image.isEmpty
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors[2]),
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mã NV: $id',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (positionName != null && positionName!.isNotEmpty)
                      Text(
                        'Chức vụ: $positionName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (departmentName != null && departmentName!.isNotEmpty)
                      Text(
                        'Phòng ban: $departmentName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(
                          text: status,
                          color: status == 'Đang làm việc' ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        if (shift != 'Không có ca')
                          _buildTag(
                            text: shift,
                            color: colors[2],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Nút sửa / xóa
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: colors[2],
                      size: 26,
                    ),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () async {
                      final isEditing = id != null && id.isNotEmpty;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEmployeeScreen(
                            token: token,
                            employeeId: isEditing ? id : null,
                          ),
                        ),
                      );
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Cập nhật thành công'),
                            backgroundColor: colors[3],
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 26,
                    ),
                    tooltip: 'Xóa nhân viên',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Xác nhận xóa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          content: const Text(
                            'Bạn có chắc muốn xóa nhân viên này không?',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'Xóa',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && onDelete != null) {
                        await onDelete!(id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}