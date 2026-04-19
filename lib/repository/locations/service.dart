import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/locations/model.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class LocationsService {
  Future<ApiResponse<LocationsResponse>> getLocations() async {
    final token = await SharedPrefService.getAccessToken();
    final response = await ApiService().get(
      endpoint: AppEndpoints.locations,
      token: token,
    );

    if (response.success && response.data != null) {
      try {
        final parsed = LocationsResponse.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(parsed, response.statusCode ?? 200);
      } catch (e) {
        return ApiResponse.error('Failed to parse locations: $e', response.statusCode);
      }
    } else {
      return ApiResponse.error(
        response.message ?? 'Failed to fetch locations',
        response.statusCode,
      );
    }
  }
}
