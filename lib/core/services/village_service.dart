import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../config/env.dart';
import 'auth_service.dart';
import '../utils/url_builder.dart';

class VillageService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  /// Fetch nearby village using the project API.
  /// Returns the parsed response map or null on failure.
  Future<Map<String, dynamic>?> fetchNearbyByLatLng(double lat, double lon) async {
    try {
      final bearerToken = await _authService.getToken();
      final headers = <String, dynamic>{
        'accept': '*/*',
      };
      if (bearerToken != null && bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }
      final res = await _dio.get(
        UrlBuilder.build('village-survey/village/near-by-village'),
        queryParameters: {'lat': lat, 'lon': lon},
        options: Options(headers: headers),
      );
      if (res.statusCode == 200) return res.data as Map<String, dynamic>?;
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Uploads a document/image for the village survey.
  Future<String?> uploadDocument(Uint8List bytes, String filePath) async {
    try {
      String fileName = p.basename(filePath);
      if (!fileName.toLowerCase().endsWith('.jpg') &&
          !fileName.toLowerCase().endsWith('.jpeg') &&
          !fileName.toLowerCase().endsWith('.png')) {
        fileName = '$fileName.jpg';
      }
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final bearerToken = await _authService.getToken();
      final headers = <String, dynamic>{'accept': '*/*'};
      if (bearerToken != null && bearerToken.isNotEmpty) headers['Authorization'] = 'Bearer $bearerToken';

      final res = await _dio.post(
        UrlBuilder.build('village-survey/upload-document'),
        data: formData,
        options: Options(headers: headers),
      );

      if (res.statusCode == 201 && res.data != null) {
        return res.data['file_name'] as String?;
      }
    } catch (e) {
      print('Error uploading document: $e');
    }
    return null;
  }

  /// Update existing survey by id using application/json as the API expects.
  Future<bool> updateSurvey(int id, Map<String, dynamic> payload, String? imagePath, {String? bearerToken}) async {
    try {
      final map = <String, dynamic>{};

      // Helper to convert various "truthy" values to a boolean.
      bool toBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is num) return value > 0;
        final str = value.toString().toLowerCase();
        if (str == 'true' || str == '1') return true;
        return false;
      }

      // Direct mappings
      final directMappings = {
        // 'villageName': 'village_name',
        'status': 'status',
        'gramPanchayat': 'gram_panchayat_office',
        'totalPopulation': 'total_population',
        'agriLand': 'agricultural_land_area',
        'irrigatedLand': 'irrigated_land_area',
        'unirrigatedLand': 'unirrigated_land_area',
        'residentialLand': 'residential_land_area',
        'waterArea': 'water_area',
        'stonyArea': 'stony_soil_area',
        'totalArea': 'total_area',
        'generalFamilies': 'general_families',
        'obcFamilies': 'obc_families',
        'scFamilies': 'scheduled_caste_families',
        'stFamilies': 'scheduled_tribe_families',
        'farmingFamilies': 'farming_families',
        'farmLabourFamilies': 'farm_labour_families',
        'govtJobFamilies': 'govt_job_families',
        'nonGovtJobFamilies': 'non_govt_job_families',
        'businessFamilies': 'private_business_families',
        'unemployedFamilies': 'unemployed_families',
        'nearestCity': 'nearest_city',
        'distanceToCity': 'distance_to_nearest_city',
        'talukaHeadquarters': 'taluka_headquarters',
        'distanceToHQ': 'distance_to_taluka_headquarters',
        'districtHeadquarters': 'district_headquarters',
        'distanceToDistrictHQ': 'distance_to_district_headquarters',
        'busStation': 'bus_station',
        'railwayStation': 'railway_station',
        'postOffice': 'post_office',
        'policeStation': 'police_station',
        'bank': 'bank',
        'primarySchoolCount': 'primary_school_count',
        'secondarySchoolCount': 'secondary_school_count',
        'higherSecondarySchoolCount': 'higher_secondary_school_count',
        'collegeCount': 'college_count',
        'universityCount': 'university_count',
        'anganwadiCount': 'anganwadi_count',
        'itcCount': 'industrial_training_centre_count',
        'dispensaryCount': 'dispensary_count',
        'phcCount': 'primary_health_centre_count',
        'govHospitalCount': 'government_hospital_count',
        'privateHospitalCount': 'private_hospital_count',
        'drugStoreCount': 'drug_store_count',
        'animalHospitalCount': 'animal_hospital_count',
        'communityHallCount': 'community_hall_count',
        'fairPriceShopCount': 'fair_price_shop_count',
        'groceryMarketCount': 'grocery_market_count',
        'vegetableMarketCount': 'vegetable_market_count',
        'grindingMillCount': 'grain_grinding_mill_count',
        'restaurantCount': 'restaurant_hotel_count',
        'publicTransportCount': 'public_transport_system_count',
        'cooperativeCount': 'cooperative_society_count',
        'publicGardenCount': 'public_garden_park_count',
        'cinemaCount': 'cinema_theatre_count',
        'coldStorageCount': 'cold_storage_count',
        'sportsGroundCount': 'sports_ground_count',
        'templeCount': 'temple_count',
        'mosqueCount': 'mosque_count',
        'otherReligiousCount': 'other_religious_place_count',
        'cremationCount': 'cremation_count',
        'cemeteryCount': 'cemetery_count',
        'asphaltRoadCount': 'approach_asphalt_road_count',
        'rawRoadCount': 'approach_raw_road_count',
        'waterSystemCount': 'water_system_count',
        'drainageSystemCount': 'drainage_system_count',
        'electricitySystemCount': 'electricity_system_count',
        'wasteDisposalCount': 'public_waste_disposal_count',
        'waterStorageCount': 'water_storage_arrangement_count',
        'publicWellCount': 'public_well_count',
        'publicPondCount': 'public_pond_count',
        'waterForCattleCount': 'water_for_cattle_count',
      };
      
      final floatFields = {
        'totalArea',
        'agriLand',
        'irrigatedLand',
        'unirrigatedLand',
        'residentialLand',
        'waterArea',
        'stonyArea',
        'distanceToCity',
        'distanceToHQ',
        'distanceToDistrictHQ',
      };

      directMappings.forEach((payloadKey, apiKey) {
        if (payload.containsKey(payloadKey)) {
          // Pass the value directly. If it's null from the form, it will be null here.
          // The _collectPayload method now handles parsing, so we don't need to default here.
          map[apiKey] = payload[payloadKey];
        }
      });

      // Handle totalFamily specifically, defaulting to 0 for count fields
      if (payload.containsKey('totalFamily')) {
        final totalFamilyValue = payload['totalFamily'];
        map['total_family'] = totalFamilyValue;
        map['number_of_families'] = totalFamilyValue;
      }

      // Boolean / Count to 1/0 mappings
      final booleanMappings = {
        'hasAsphaltRoad': 'approach_asphalt_road',
        'hasRawRoad': 'approach_raw_road',
        'hasWaterSystem': 'water_system',
        'hasDrainage': 'drainage_system',
        'hasElectricity': 'electricity_system',
        'hasWasteDisposal': 'public_waste_disposal',
        'hasWaterStorage': 'water_storage_arrangement',
        'hasPublicWell': 'public_well',
        'hasPublicPond': 'public_pond',
        'hasWaterForCattle': 'water_for_cattle',
        'hasPrimarySchool': 'primary_school',
        'hasSecondarySchool': 'secondary_school',
        'hasHigherSecondary': 'higher_secondary_school',
        'hasCollege': 'college',
        'hasUniversity': 'university',
        'hasAnganwadi': 'anganwadi',
        'hasItc': 'industrial_training_centre',
        'hasDispensary': 'dispensary',
        'hasPhc': 'primary_health_centre',
        'hasGovHospital': 'government_hospital',
        'hasPrivateHospital': 'private_hospital',
        'hasDrugStore': 'drug_store',
        'hasAnimalHospital': 'animal_hospital',
        'hasCommunityHall': 'community_hall',
        'hasFairPriceShop': 'fair_price_shop',
        'hasGroceryMarket': 'grocery_market',
        'hasVegetableMarket': 'vegetable_market',
        'hasGrindingMill': 'grain_grinding_mill',
        'hasRestaurant': 'restaurant_hotel',
        'hasPublicTransport': 'public_transport_system',
        'hasCooperative': 'cooperative_society',
        'hasPublicGarden': 'public_garden_park',
        'hasCinema': 'cinema_theatre',
        'hasColdStorage': 'cold_storage',
        'hasSportsGround': 'sports_ground',
        'hasTemple': 'temple',
        'hasMosque': 'mosque',
        'hasOtherReligious': 'other_religious_place',
        'hasCremation': 'cremation',
        'hasCemetery': 'cemetery',
      };

      booleanMappings.forEach((payloadKey, apiKey) {
        if (payload[payloadKey] != null) {
          map[apiKey] = toBool(payload[payloadKey]);
        }
      });

      if (payload['totalPopulation'] != null) map['total_population'] = payload['totalPopulation'];
      // attachments & gps
      if (payload['gps'] != null) {
        final gps = payload['gps'].toString().split(',');
        if (gps.length >= 2) {
          map['lat'] = double.tryParse(gps[0]);
          map['lon'] = double.tryParse(gps[1]);
        }
      }

      if (payload['file_types'] != null) {
        map['file_types'] = payload['file_types'];
      }

      // Attachments & image file field (base64 encoded for JSON)
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          map['files'] = base64Encode(bytes);
        }
      }

      final headers = <String, dynamic>{'accept': 'application/json', 'Content-Type': 'application/json'};
      if (bearerToken != null && bearerToken.isNotEmpty) headers['Authorization'] = 'Bearer $bearerToken';

      final res = await _dio.put(
        '${AppConfig.baseUrl}/village-survey/$id',
        data: map,
        options: Options(headers: headers),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print( 'Error updating survey: $e');
      return false;
    }
  }

  /// Fetch a survey by its id and return the parsed response map or null on failure.
  Future<Map<String, dynamic>?> fetchSurveyById(int id, {String? bearerToken}) async {
    try {
      final headers = <String, dynamic>{'accept': '*/*'};
      if (bearerToken != null && bearerToken.isNotEmpty) headers['Authorization'] = 'Bearer $bearerToken';
  final res = await _dio.get(UrlBuilder.build('village-survey/$id'), options: Options(headers: headers));
      if (res.statusCode == 200) return res.data as Map<String, dynamic>?;
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Check whether a remote URL responds successfully (fast HEAD request).
  Future<bool> checkUrlExists(String url) async {
    try {
      final res = await _dio.head(url, options: Options(followRedirects: true, validateStatus: (_) => true));
      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 400;
    } catch (_) {
      return false;
    }
  }

  /// Submits the village survey data.
  Future<Map<String, dynamic>> submitSurvey(Map<String, dynamic> payload) async {
    try {
      final bearerToken = await _authService.getToken();
      final headers = <String, dynamic>{
        'accept': '*/*',
        'Content-Type': 'application/json',
      };
      if (bearerToken != null && bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final id = payload['id'] ?? payload['village']?['id'];
      Response response;

      if (id != null && id is int && id > 0) {
        response = await _dio.put(
          UrlBuilder.build('village-survey/$id'),
          data: payload,
          options: Options(headers: headers),
        );
      } else {
        response = await _dio.post(
          UrlBuilder.build('village-survey'),
          data: payload,
          options: Options(headers: headers),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('Error submitting village survey: $e');
    }
    return {'success': false};
  }
}
