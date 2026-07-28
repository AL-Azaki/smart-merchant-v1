import '../../../../app/config/api_client.dart';
import '../dto/auth_dtos.dart';

/// Remote data source implementing the actual Laravel Sanctum authentication
/// and session bootstrap API calls.
///
/// Routes:
/// - POST /auth/login
/// - POST /auth/logout
/// - GET  /session/bootstrap
/// - POST /devices/register
class AuthRemoteApiClient {
  final ApiClient _apiClient;

  const AuthRemoteApiClient(this._apiClient);

  /// POST /auth/login
  /// Returns [LoginResponseDto] with Sanctum plaintext token.
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: request.toJson(),
    );
    return LoginResponseDto.fromJson(response.json);
  }

  /// POST /auth/register
  /// Registers a new user and returns token.
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: request.toJson(),
    );
    return RegisterResponseDto.fromJson(response.json);
  }

  /// POST /auth/logout
  /// Deletes the current access token server-side.
  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  /// GET /session/bootstrap
  /// Establishes user/business/branch/role/permission/subscription/device context.
  Future<BootstrapResponseDto> bootstrap(BootstrapRequestDto request) async {
    final response = await _apiClient.get(
      '/session/bootstrap',
      queryParams: request.toQueryParams(),
    );
    return BootstrapResponseDto.fromJson(response.json);
  }

  /// POST /devices/register
  /// Registers or refreshes device binding for the authenticated user+business.
  Future<RegisterDeviceResponseDto> registerDevice(
    RegisterDeviceRequestDto request,
  ) async {
    final response = await _apiClient.post(
      '/devices/register',
      data: request.toJson(),
    );
    return RegisterDeviceResponseDto.fromJson(response.json);
  }
  /// POST /business/setup
  Future<void> setupBusiness(Map<String, dynamic> request) async {
    await _apiClient.post(
      '/business/setup',
      data: request,
    );
  }
}
