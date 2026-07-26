import 'dart:convert';
import 'package:http/http.dart' as http;

/// SymbolTalk API Client Service
/// This service provides optional integration with the SymbolTalk backend API.
/// It's designed to work alongside the local storage services, not replace them.
/// 
/// Usage:
/// - Enable cloud sync when user wants backup/restore
/// - Use for board sharing
/// - Access multi-language symbol library
/// - Analytics (optional)
/// 
/// The service is optional - the app works perfectly without it using local storage.

class SymbolTalkApiService {
  static const String defaultBaseUrl = 'http://localhost:8080';
  String _baseUrl;
  String? _accessToken;
  String? _refreshToken;

  SymbolTalkApiService({String baseUrl = defaultBaseUrl}) : _baseUrl = baseUrl;

  /// Set the base URL for the API (useful for testing/production)
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Set authentication tokens
  void setTokens(String accessToken, String? refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get authorization header
  Map<String, String> get _authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ==================== AUTHENTICATION ====================

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// Logout
  Future<void> logout() async {
    if (_refreshToken == null) {
      clearTokens();
      return;
    }

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/logout'),
        headers: _authHeaders,
        body: json.encode({'refreshToken': _refreshToken}),
      );
    } finally {
      clearTokens();
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/refresh'),
      headers: _headers,
      body: json.encode({'refreshToken': _refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      return data;
    } else {
      throw Exception('Token refresh failed: ${response.body}');
    }
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/auth/me'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get user failed: ${response.body}');
    }
  }

  // ==================== PROFILES ====================

  /// Get current user's profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/profiles/me'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get profile failed: ${response.body}');
    }
  }

  /// Update profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/profiles/me'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Update profile failed: ${response.body}');
    }
  }

  /// Get profile settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/profiles/me/settings'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get settings failed: ${response.body}');
    }
  }

  /// Update settings
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/profiles/me/settings'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Update settings failed: ${response.body}');
    }
  }

  // ==================== BOARDS ====================

  /// Get user's boards
  Future<List<Map<String, dynamic>>> getBoards() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/boards'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get boards failed: ${response.body}');
    }
  }

  /// Create a board
  Future<Map<String, dynamic>> createBoard(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/boards'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Create board failed: ${response.body}');
    }
  }

  /// Get a specific board
  Future<Map<String, dynamic>> getBoard(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/boards/$id'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get board failed: ${response.body}');
    }
  }

  /// Update a board
  Future<Map<String, dynamic>> updateBoard(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/boards/$id'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Update board failed: ${response.body}');
    }
  }

  /// Delete a board
  Future<void> deleteBoard(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/boards/$id'),
      headers: _authHeaders,
    );

    if (response.statusCode != 204) {
      throw Exception('Delete board failed: ${response.body}');
    }
  }

  /// Duplicate a board
  Future<Map<String, dynamic>> duplicateBoard(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/boards/$id/duplicate'),
      headers: _authHeaders,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Duplicate board failed: ${response.body}');
    }
  }

  // ==================== SYMBOLS ====================

  /// Search symbols
  Future<List<Map<String, dynamic>>> searchSymbols({
    required String query,
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = {
      'q': query,
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (categoryId != null) 'categoryId': categoryId,
    };

    final uri = Uri.parse('$_baseUrl/api/v1/symbols/search')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Search symbols failed: ${response.body}');
    }
  }

  /// Get symbols by category
  Future<List<Map<String, dynamic>>> getSymbolsByCategory(String? categoryId) async {
    final queryParams = {
      if (categoryId != null) 'categoryId': categoryId,
    };

    final uri = Uri.parse('$_baseUrl/api/v1/symbols')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get symbols failed: ${response.body}');
    }
  }

  // ==================== SENTENCES ====================

  /// Get user's sentences
  Future<List<Map<String, dynamic>>> getSentences({
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final uri = Uri.parse('$_baseUrl/api/v1/sentences')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get sentences failed: ${response.body}');
    }
  }

  /// Create a sentence
  Future<Map<String, dynamic>> createSentence(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/sentences'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Create sentence failed: ${response.body}');
    }
  }

  /// Get favorites
  Future<List<Map<String, dynamic>>> getFavorites({
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final uri = Uri.parse('$_baseUrl/api/v1/favorites')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get favorites failed: ${response.body}');
    }
  }

  // ==================== SYNC ====================

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/sync/status'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get sync status failed: ${response.body}');
    }
  }

  /// Pull changes from server
  Future<Map<String, dynamic>> pullChanges(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/sync/pull'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Pull changes failed: ${response.body}');
    }
  }

  /// Push changes to server
  Future<Map<String, dynamic>> pushChanges(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/sync/push'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Push changes failed: ${response.body}');
    }
  }

  /// Get sync conflicts
  Future<List<Map<String, dynamic>>> getConflicts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/sync/conflicts'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get conflicts failed: ${response.body}');
    }
  }

  /// Resolve a sync conflict
  Future<void> resolveConflict(String conflictId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/sync/conflicts/$conflictId/resolve'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Resolve conflict failed: ${response.body}');
    }
  }

  // ==================== SHARING ====================

  /// Share a board
  Future<Map<String, dynamic>> shareBoard(String boardId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/boards/$boardId/share'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Share board failed: ${response.body}');
    }
  }

  /// Create a share link
  Future<Map<String, dynamic>> createShareLink(String boardId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/boards/$boardId/share/share-link'),
      headers: _authHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Create share link failed: ${response.body}');
    }
  }

  /// Get shared board via token
  Future<Map<String, dynamic>> getSharedBoard(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/share/$token'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get shared board failed: ${response.body}');
    }
  }

  // ==================== LANGUAGES ====================

  /// Get all available languages
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/languages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Get languages failed: ${response.body}');
    }
  }

  /// Get language by code
  Future<Map<String, dynamic>> getLanguage(String code) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/languages/$code'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Get language failed: ${response.body}');
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Check if API is available
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
