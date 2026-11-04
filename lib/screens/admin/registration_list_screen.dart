import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/registration_model.dart';
import '../../services/api_service.dart';

class RegistrationListScreen extends StatefulWidget {
  const RegistrationListScreen({super.key});

  @override
  State<RegistrationListScreen> createState() => _RegistrationListScreenState();
}

class _RegistrationListScreenState extends State<RegistrationListScreen> {
  List<RegistrationModel> _registrations = [];
  List<RegistrationModel> _filteredRegistrations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegistrations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await ApiService.getAllRegistrations();
      if (!mounted) return;
      setState(() {
        _registrations = list;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading registrations: $e')),
      );
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredRegistrations = List.from(_registrations);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredRegistrations = _registrations.where((reg) {
        return reg.name.toLowerCase().contains(query) ||
            reg.phoneNumber.toLowerCase().contains(query) ||
            reg.tokenNumber.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Registered Customers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRegistrations,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Summary Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applySearch();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by token, name, or phone...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _applySearch();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Registrations: ${_filteredRegistrations.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ApiService.useMockData
                              ? Colors.amber.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ApiService.useMockData ? 'Mock Mode' : 'Live API Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ApiService.useMockData
                                ? Colors.amber.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Registration List View
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                      ),
                    )
                  : _filteredRegistrations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No customer registrations yet'
                                    : 'No matching records found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRegistrations,
                          color: const Color(0xFF4F46E5),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 8.0,
                            ),
                            itemCount: _filteredRegistrations.length,
                            itemBuilder: (context, index) {
                              final item = _filteredRegistrations[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Token Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          item.tokenNumber,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Customer Details (Name, Phone, Time)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone_rounded,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  item.phoneNumber,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF475569),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 13,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  dateFormat.format(item.registrationTime),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
