import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Render Hosted Backend URL
  static const String baseUrl = 'https://notemakingapp-4uwp.onrender.com/api';

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to backend server: $e'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to backend server: $e'};
    }
  }

  // FETCH NOTES
  static Future<List<dynamic>?> getNotes(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notes?userId=$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return null;
    }
  }

  // CREATE NOTE
  static Future<Map<String, dynamic>?> createNote({
    required String userId,
    required String title,
    required String content,
    required DateTime date,
    required int colorValue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'content': content,
          'date': date.toIso8601String(),
          'colorValue': colorValue,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating note: $e');
      return null;
    }
  }

  // UPDATE NOTE
  static Future<Map<String, dynamic>?> updateNote({
    required String noteId,
    required String title,
    required String content,
    required DateTime date,
    required int colorValue,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notes/$noteId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'date': date.toIso8601String(),
          'colorValue': colorValue,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return null;
    }
  }

  // DELETE NOTE
  static Future<bool> deleteNote(String noteId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/notes/$noteId'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }
}
