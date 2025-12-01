import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  // ========== TOKENS ==========
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

    // SOLO PARA DEBUG - Borrar en producción
  Future<void> clearOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingCompleted);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<void> deleteTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }

  // ========== USER DATA ==========
  
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUser);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // ========== AUTH COMPLETE ==========
  
  Future<void> saveAuthResponse(AuthResponse authResponse) async {
    await saveTokens(authResponse.accessToken, authResponse.refreshToken);
    await saveUserData(authResponse.usuario.toJson());
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    final userData = await getUserData();
    return token != null && userData != null;
  }

  Future<void> clearAuth() async {
    await deleteTokens();
    await deleteUserData();
  }

  // ========== ONBOARDING ==========
  
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // ========== THEME MODE ==========
  
  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, themeMode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  // ========== EMPRESA ID ==========
  
  Future<String?> getEmpresaId() async {
    final userData = await getUserData();
    return userData?['empresaId']?.toString();
  }

  // ========== REMEMBER ME ==========
  
  Future<void> saveRememberMe({
    required bool rememberMe,
    String? email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    
    if (rememberMe && email != null && password != null) {
      // Guardar credenciales encriptadas (base64 simple por ahora)
      await prefs.setString(_keySavedEmail, base64Encode(utf8.encode(email)));
      await prefs.setString(_keySavedPassword, base64Encode(utf8.encode(password)));
    } else if (!rememberMe) {
      // Borrar credenciales si desactiva remember me
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    
    if (!rememberMe) return null;
    
    final savedEmail = prefs.getString(_keySavedEmail);
    final savedPassword = prefs.getString(_keySavedPassword);
    
    if (savedEmail == null || savedPassword == null) return null;
    
    try {
      return {
        'email': utf8.decode(base64Decode(savedEmail)),
        'password': utf8.decode(base64Decode(savedPassword)),
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keySavedEmail);
    await prefs.remove(_keySavedPassword);
  }

  // ========== CLEAR ALL (for complete logout) ==========
  
  Future<void> clearAll() async {
    await clearAuth();
    await clearRememberMe();
  }
}
