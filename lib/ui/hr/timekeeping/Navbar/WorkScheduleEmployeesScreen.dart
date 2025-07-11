// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:sem4_fe/Service/Constants.dart';
//
// class WorkScheduleEmployeesScreen extends StatefulWidget {
//   final String token;
//   final String scheduleId;
//   final String scheduleName;
//
//   const WorkScheduleEmployeesScreen({
//     Key? key,
//     required this.token,
//     required this.scheduleId,
//     required this.scheduleName,
//   }) : super(key: key);
//
//   @override
//   State<WorkScheduleEmployeesScreen> createState() => _WorkScheduleEmployeesScreenState();
// }
//
// class _WorkScheduleEmployeesScreenState extends State<WorkScheduleEmployeesScreen> {
//   late Future<List<Employee>> _futureEmployees;
//
//   @override
//   void initState() {
//     super.initState();
//     _futureEmployees = fetchEmployeesBySchedule(widget.scheduleId);
//   }
//
//   Future<List<Employee>> fetchEmployeesBySchedule(String scheduleId) async {
//     final url = Uri.parse('${Constants.employeeByScheduleUrl}$scheduleId');
//
//     final response = await http.get(
//       url,
//       headers: {
//         'Authorization': 'Bearer ${widget.token}',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final body = jsonDecode(response.body);
//       final List<dynamic> data = body['result'];
//       return data.map((e) => Employee.fromJson(e)).toList();
//     } else {
//       throw Exception('Không thể tải danh sách nhân viên: ${response.body}');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Nhân viên - ${widget.scheduleName}'),
//         backgroundColor: Colors.orange,
//       ),
//       body: FutureBuilder<List<Employee>>(
//         future: _futureEmployees,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Lỗi: ${snapshot.error}'));
//           }
//
//           final employees = snapshot.data!;
//           if (employees.isEmpty) {
//             return const Center(child: Text('Không có nhân viên trong ca làm này.'));
//           }
//
//           return ListView.builder(
//             itemCount: employees.length,
//             itemBuilder: (context, index) {
//               final e = employees[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 3,
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.orange.shade100,
//                     child: const Icon(Icons.person, color: Colors.deepOrange),
//                   ),
//                   title: Text(e.fullName),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Email: ${e.email}'),
//                       if (e.phone != null) Text('SĐT: ${e.phone!}'),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// class Employee {
//   final String employeeId;
//   final String fullName;
//   final String email;
//   final String? phone;
//
//   Employee({
//     required this.employeeId,
//     required this.fullName,
//     required this.email,
//     this.phone,
//   });
//
//   factory Employee.fromJson(Map<String, dynamic> json) {
//     return Employee(
//       employeeId: json['employeeId']?.toString() ?? '',
//       fullName: json['fullName'] ?? '',
//       email: json['email'] ?? '',
//       phone: json['phone'],
//     );
//   }
// }
