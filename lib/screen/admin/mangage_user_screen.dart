import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:http/http.dart' as http;

const kPrimaryColor = Color(0xFF1976D2);
const kLightBackground = Color(0xFFE9F1FB);
const kCardBackground = Colors.white;
const kTitleColor = Color(0xFF002856);

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({Key? key}) : super(key: key);

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchText = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConstants.baseUrl}/getAllUser'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kLightBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: kTitleColor),
          title: const Text(
            " Quản lý người dùng",
            style: TextStyle(
              color: kTitleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child:
                        Text("❌ $_error", style: TextStyle(color: Colors.red)))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 40, // giảm chiều cao
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Tìm kiếm theo tên',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchText = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Paginated table
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.95, // Gần full màn
                              child: PaginatedDataTable(
                                header: const Text('Danh sách người dùng'),
                                rowsPerPage: 5,
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                                columns: [
                                  DataColumn(
                                    label: const Text('Tên'),
                                    onSort: (columnIndex, ascending) {
                                      setState(() {
                                        _sortColumnIndex = columnIndex;
                                        _sortAscending = ascending;
                                        _users.sort((a, b) {
                                          final nameA = a['fullname'] ?? '';
                                          final nameB = b['fullname'] ?? '';
                                          return ascending
                                              ? nameA.compareTo(nameB)
                                              : nameB.compareTo(nameA);
                                        });
                                      });
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Phòng ban'),
                                    onSort: (columnIndex, ascending) {
                                      setState(() {
                                        _sortColumnIndex = columnIndex;
                                        _sortAscending = ascending;
                                        _users.sort((a, b) {
                                          final deptA = a['department'] ?? '';
                                          final deptB = b['department'] ?? '';
                                          return ascending
                                              ? deptA.compareTo(deptB)
                                              : deptB.compareTo(deptA);
                                        });
                                      });
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Vai trò'),
                                    onSort: (columnIndex, ascending) {
                                      setState(() {
                                        _sortColumnIndex = columnIndex;
                                        _sortAscending = ascending;
                                        _users.sort((a, b) {
                                          final roleA = a['role'] ?? '';
                                          final roleB = b['role'] ?? '';
                                          return ascending
                                              ? roleA.compareTo(roleB)
                                              : roleB.compareTo(roleA);
                                        });
                                      });
                                    },
                                  ),
                                  const DataColumn(label: Text('Hành động')),
                                ],
                                source: UserDataSource(
                                  users: _users
                                      .where((user) => user['fullname']
                                          .toString()
                                          .toLowerCase()
                                          .contains(_searchText))
                                      .toList(),
                                  onRoleChanged: _updateUserRole,
                                  onDelete: _confirmDelete,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));
  }

  void _confirmDelete(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(userId);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/delete/$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user['_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xoá người dùng thành công')),
        );
      } else {
        throw Exception('Lỗi xoá: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/users/updateRole'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'role': newRole}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật vai trò thành công')),
        );
      } else {
        throw Exception('Lỗi cập nhật: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }
}

class UserDataSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  final Function(String, String) onRoleChanged;
  final Function(String) onDelete;

  UserDataSource({
    required this.users,
    required this.onRoleChanged,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;

    final user = users[index];
    final userId = user['_id'] ?? '';
    final name = user['fullname'] ?? 'Không rõ';
    final department = user['department'] ?? 'Không có phòng ban';
    final role = user['role'] ?? 'user';

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(name)),
        DataCell(Text(department)),
        DataCell(DropdownButton<String>(
          value: role,
          items: ['admin', 'user'].map((r) {
            return DropdownMenuItem(
              value: r,
              child: Text(
                r,
                style: TextStyle(
                  color: r == 'admin' ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          onChanged: (newRole) {
            if (newRole != null) {
              onRoleChanged(userId, newRole);
              user['role'] = newRole;
              notifyListeners();
            }
          },
          underline: Container(),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDelete(userId),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => users.length;
  @override
  int get selectedRowCount => 0;
}
