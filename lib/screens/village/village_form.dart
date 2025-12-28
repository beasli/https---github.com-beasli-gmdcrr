import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gmdcrr/core/config/env.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';

import '../../core/services/local_db.dart';
import '../../core/services/village_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/open_url.dart' if (dart.library.html) '../../core/utils/open_url_web.dart';
import 'camera_capture.dart';

class VillageFormPage extends StatefulWidget {
  const VillageFormPage({super.key});

  @override
  State<VillageFormPage> createState() => _VillageFormPageState();
}

class _VillageFormPageState extends State<VillageFormPage> {
  int _currentStep = 0;
  int? _draftId;
  int? _remoteSurveyId;
  bool _isInitializing = true;
  String? _processingAction; // null, 'draft', or 'submit'
  List<Map<String, dynamic>> _remoteMedia = [];

  // Validation
  final Map<String, String?> _errors = {};

  // Location
  double? _lat, _lng;

  // Step fields - General
  final _villageNameCtrl = TextEditingController();
  final _gpCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _totalPopulationCtrl = TextEditingController();
  final _totalFamilyCtrl = TextEditingController();

  // Area
  final _agriLandCtrl = TextEditingController();
  final _irrigatedCtrl = TextEditingController();
  final _unirrigatedCtrl = TextEditingController();
  final _residentialCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _stonyCtrl = TextEditingController();
  // read-only total for area (computed)
  final _totalAreaCtrl = TextEditingController();

  // Families by social group
  final _familiesGeneralCtrl = TextEditingController();
  final _familiesOBCCtrl = TextEditingController();
  final _familiesSCCtrl = TextEditingController();
  final _familiesSTCtrl = TextEditingController();
  // read-only total for social groups (computed)
  final _familiesSocialTotalCtrl = TextEditingController();

  // Families by primary occupation
  final _familiesFarmingCtrl = TextEditingController();
  final _familiesLabourCtrl = TextEditingController();
  final _familiesGovtCtrl = TextEditingController();
  final _familiesNonGovtCtrl = TextEditingController();
  final _familiesBusinessCtrl = TextEditingController();
  final _familiesUnemployedCtrl = TextEditingController();

  // Connectivity
  final _nearestCity = TextEditingController();
  final _distanceToCity = TextEditingController();
  final _headquartersName = TextEditingController();
  final _distanceToHQ = TextEditingController();
  // District headquarters
  final _districtHeadquartersName = TextEditingController();
  final _distanceToDistrictHQ = TextEditingController();

  // Facilities (detail & distance)
  final _busStationDetails = TextEditingController();
  final _railwayStationDetails = TextEditingController();
  final _postOfficeDetails = TextEditingController();
  final _policeStationDetails = TextEditingController();
  final _bankDetails = TextEditingController();

  // Infrastructure
  // 5.1 Roads, Water & Utilities
  bool? hasAsphaltRoad;
  bool? hasRawRoad;
  bool? hasWaterSystem;
  bool? hasDrainage;
  bool? hasElectricity;
  bool? hasWasteDisposal;
  final _asphaltRoadCount = TextEditingController();
  final _rawRoadCount = TextEditingController();
  final _waterSystemCount = TextEditingController();
  final _drainageSystemCount = TextEditingController();
  final _electricitySystemCount = TextEditingController();
  final _wasteDisposalCount = TextEditingController();
  
  // 5.2 Public Water Sources (counts)
  bool? hasWaterStorage;
  bool? hasPublicWell;
  bool? hasPublicPond;
  bool? hasWaterForCattle;
  final _waterStorageCount = TextEditingController();
  final _publicWellCount = TextEditingController();
  final _publicPondCount = TextEditingController();
  final _waterForCattleCount = TextEditingController();
  
  // 5.3 Education Facilities (counts)
  bool? hasPrimarySchool;
  bool? hasSecondarySchool;
  bool? hasHigherSecondary;
  bool? hasCollege;
  bool? hasUniversity;
  bool? hasAnganwadi;
  bool? hasItc;
  final _primarySchoolCount = TextEditingController();
  final _secondarySchoolCount = TextEditingController();
  final _higherSecondaryCount = TextEditingController();
  final _collegeCount = TextEditingController();
  final _universityCount = TextEditingController();
  final _anganwadiCount = TextEditingController();
  final _itcCount = TextEditingController();
  
  // 5.4 Health Facilities (counts)
  bool? hasDispensary;
  bool? hasPhc;
  bool? hasGovHospital;
  bool? hasPrivateHospital;
  bool? hasDrugStore;
  bool? hasAnimalHospital;
  final _dispensaryCount = TextEditingController();
  final _phcCount = TextEditingController();
  final _govHospitalCount = TextEditingController();
  final _privateHospitalCount = TextEditingController();
  final _drugStoreCount = TextEditingController();
  final _animalHospitalCount = TextEditingController();
  
  // 5.5 Markets, Community & Services
  bool? hasCommunityHall;
  bool? hasFairPriceShop;
  bool? hasGroceryMarket;
  bool? hasVegetableMarket;
  bool? hasGrindingMill;
  bool? hasRestaurant;
  bool? hasPublicTransport;
  bool? hasCooperative;
  bool? hasPublicGarden;
  bool? hasCinema;
  bool? hasColdStorage;
  bool? hasSportsGround;
  final _communityHallCount = TextEditingController();
  final _fairPriceShopCount = TextEditingController();
  final _groceryMarketCount = TextEditingController();
  final _vegetableMarketCount = TextEditingController();
  final _grindingMillCount = TextEditingController();
  final _restaurantCount = TextEditingController();
  final _publicTransportCount = TextEditingController();
  final _cooperativeCount = TextEditingController();
  final _publicGardenCount = TextEditingController();
  final _cinemaCount = TextEditingController();
  final _coldStorageCount = TextEditingController();
  final _sportsGroundCount = TextEditingController();
  
  // 5.6 Religious/Mortality Facilities
  bool? hasTemple;
  bool? hasMosque;
  bool? hasOtherReligious;
  bool? hasCremation;
  bool? hasCemetery;
  final _templeCount = TextEditingController();
  final _mosqueCount = TextEditingController();
  final _otherReligiousCount = TextEditingController();
  final _cremationGroundCount = TextEditingController();
  final _cemeteryCount = TextEditingController();

  // Attachments & GPS
  String? _gpsLocation;
  String? _villagePhotoPath;

  @override
  void initState() {
    super.initState();
    _initLocationAndDraft();
    // compute social total when any social input changes
    _familiesGeneralCtrl.addListener(_computeSocialTotal);
    _familiesOBCCtrl.addListener(_computeSocialTotal);
    _familiesSCCtrl.addListener(_computeSocialTotal);
    _familiesSTCtrl.addListener(_computeSocialTotal);

    // compute total area when any area input changes
    _agriLandCtrl.addListener(_computeTotalArea);
    _irrigatedCtrl.addListener(_computeTotalArea);
    _unirrigatedCtrl.addListener(_computeTotalArea);
    _residentialCtrl.addListener(_computeTotalArea);
    _waterCtrl.addListener(_computeTotalArea);
    _stonyCtrl.addListener(_computeTotalArea);
  }

  @override
  void dispose() {
    _familiesGeneralCtrl.removeListener(_computeSocialTotal);
    _familiesOBCCtrl.removeListener(_computeSocialTotal);
    _familiesSCCtrl.removeListener(_computeSocialTotal);
    _familiesSTCtrl.removeListener(_computeSocialTotal);

    _agriLandCtrl.removeListener(_computeTotalArea);
    _irrigatedCtrl.removeListener(_computeTotalArea);
    _unirrigatedCtrl.removeListener(_computeTotalArea);
    _residentialCtrl.removeListener(_computeTotalArea);
    _waterCtrl.removeListener(_computeTotalArea);
    _stonyCtrl.removeListener(_computeTotalArea);
    _totalAreaCtrl.dispose();
    _familiesSocialTotalCtrl.dispose();
    _familiesGeneralCtrl.dispose();
    _familiesOBCCtrl.dispose();
    _familiesSCCtrl.dispose();
    _familiesSTCtrl.dispose();
    _familiesFarmingCtrl.dispose();
    _familiesLabourCtrl.dispose();
    _familiesGovtCtrl.dispose();
    _familiesNonGovtCtrl.dispose();
    _familiesBusinessCtrl.dispose();
    _familiesUnemployedCtrl.dispose();
  // dispose connectivity & facilities controllers
  _nearestCity.dispose();
  _distanceToCity.dispose();
  _headquartersName.dispose();
  _distanceToHQ.dispose();
  _districtHeadquartersName.dispose();
  _distanceToDistrictHQ.dispose();
  _busStationDetails.dispose();
  _railwayStationDetails.dispose();
  _asphaltRoadCount.dispose();
  _rawRoadCount.dispose();
  _waterSystemCount.dispose();
  _drainageSystemCount.dispose();
  _electricitySystemCount.dispose();
  _wasteDisposalCount.dispose();
  _postOfficeDetails.dispose();
  _policeStationDetails.dispose();
  _bankDetails.dispose();
  _primarySchoolCount.dispose();
  _waterStorageCount.dispose();
  _publicWellCount.dispose();
  _publicPondCount.dispose();
  _waterForCattleCount.dispose();
  _secondarySchoolCount.dispose();
  _higherSecondaryCount.dispose();
  _collegeCount.dispose();
  _universityCount.dispose();
  _anganwadiCount.dispose();
  _itcCount.dispose();
  _dispensaryCount.dispose();
  _phcCount.dispose();
  _govHospitalCount.dispose();
  _privateHospitalCount.dispose();
  _drugStoreCount.dispose();
  _animalHospitalCount.dispose();
  _communityHallCount.dispose();
  _fairPriceShopCount.dispose();
  _groceryMarketCount.dispose();
  _vegetableMarketCount.dispose();
  _grindingMillCount.dispose();
  _restaurantCount.dispose();
  _publicTransportCount.dispose();
  _cooperativeCount.dispose();
  _publicGardenCount.dispose();
  _cinemaCount.dispose();
  _coldStorageCount.dispose();
  _sportsGroundCount.dispose();
  _templeCount.dispose();
  _mosqueCount.dispose();
  _otherReligiousCount.dispose();
  _cremationGroundCount.dispose();
  _cemeteryCount.dispose();
    super.dispose();
  }

  void _computeSocialTotal() {
    final g = int.tryParse(_familiesGeneralCtrl.text) ?? 0;
    final o = int.tryParse(_familiesOBCCtrl.text) ?? 0;
    final s = int.tryParse(_familiesSCCtrl.text) ?? 0;
    final t = int.tryParse(_familiesSTCtrl.text) ?? 0;
    final total = g + o + s + t;
    _familiesSocialTotalCtrl.text = total.toString();
  }

  void _computeTotalArea() {
    final a = double.tryParse(_agriLandCtrl.text) ?? 0;
    final i = double.tryParse(_irrigatedCtrl.text) ?? 0;
    final u = double.tryParse(_unirrigatedCtrl.text) ?? 0;
    final r = double.tryParse(_residentialCtrl.text) ?? 0;
    final w = double.tryParse(_waterCtrl.text) ?? 0;
    final s = double.tryParse(_stonyCtrl.text) ?? 0;
    final total = a + i + u + r + w + s;
    _totalAreaCtrl.text = total.toStringAsFixed(2);
  }

  Future<void> _initLocationAndDraft() async {
    // Ensure we have a location. If not, ask the user to allow access.
    try {
      // In debug/testing mode use fixed test coordinates
      Position? pos;
      // Use mock location for development or staging environments
      if (AppConfig.currentEnvironment != Environment.production) {
        _lat = 21.6701;
        _lng = 72.2319;
        _gpsLocation = '$_lat,$_lng';
        pos = Position(
          latitude: _lat!,
          longitude: _lng!,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      } else {
        // Try to get a reliable location with fallback
        pos = await LocationService.getPositionWithFallback();
      }
  if (pos == null) {
        if (!mounted) return;
        final tryAgain = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (ctx, animation, secondaryAnimation) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              title: const Text('Location not available'),
              content: const Text('Unable to obtain your location. Please enable location services or try again outdoors.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Retry')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Settings')),
              ],
            ),
          ),
          transitionBuilder: (ctx, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
        if (tryAgain == true) {
          // Retry once
          final retry = await LocationService.getPositionWithFallback();
          if (retry != null) {
            setState(() { _lat = retry.latitude; _lng = retry.longitude; _gpsLocation = '$_lat,$_lng'; });
          } else {
            return; // still no location
          }
        } else if (tryAgain == null) {
          // Open device settings - best-effort (not implemented) and return
          return;
        } else {
          return; // user cancelled
        }
      } else {
  final Position p = pos;
  setState(() { _lat = p.latitude; _lng = p.longitude; _gpsLocation = '$_lat,$_lng'; });
        // Use nearby village API. The service now handles auth internally.
        final nearby = await VillageService().fetchNearbyByLatLng(_lat!, _lng!);
        if (nearby != null && nearby['data'] != null && nearby['data']['village'] != null) {
          final v = nearby['data']['village'];
          // capture remote survey id if present so we can update on submit
          try {
            final sid = v['survey_id'] ?? v['surveyId'] ?? nearby['data']?['id'];
            if (sid != null) {
              _remoteSurveyId = int.tryParse(sid.toString());
            }
          } catch (_) {}

          // If we have a survey id, fetch the full survey and map fields into the form
          if (_remoteSurveyId != null) {
            _isInitializing = true;
            if (mounted) setState(() {});
            try {
              final token2 = await AuthService().getToken();
              final full = await VillageService().fetchSurveyById(_remoteSurveyId!, bearerToken: token2);
              if (full != null && full['data'] != null) {
                final d = full['data'] as Map<String, dynamic>;
                // store media array if present, but filter out unreachable urls to avoid image 404 exceptions
                if (d['media'] is List) {
                  final raw = List<Map<String, dynamic>>.from(d['media'] as List);
                  final available = <Map<String, dynamic>>[];
                  for (final m in raw) {
                    final url = m['url']?.toString();
                    if (url == null) continue;
                    try {
                      final ok = await VillageService().checkUrlExists(url);
                      if (ok) available.add(m);
                    } catch (_) {}
                  }
                  _remoteMedia = available;
                }
                if (mounted) {
                  _villageNameCtrl.text = d['village_name']?.toString() ?? _villageNameCtrl.text;
                  _gpCtrl.text = d['gram_panchayat_office']?.toString() ?? _gpCtrl.text;
                  _totalPopulationCtrl.text = d['total_population']?.toString() ?? _totalPopulationCtrl.text;
                  _talukaCtrl.text = d['taluka_name']?.toString() ?? _talukaCtrl.text;
                  _totalFamilyCtrl.text = d['total_family']?.toString() ?? d['number_of_families']?.toString() ?? _totalFamilyCtrl.text;
                  _districtCtrl.text = d['district_name']?.toString() ?? _districtCtrl.text;

                  // area
                  _agriLandCtrl.text = d['agricultural_land_area']?.toString() ?? _agriLandCtrl.text;
                  _irrigatedCtrl.text = d['irrigated_land_area']?.toString() ?? _irrigatedCtrl.text;
                  _unirrigatedCtrl.text = d['unirrigated_land_area']?.toString() ?? _unirrigatedCtrl.text;
                  _residentialCtrl.text = d['residential_land_area']?.toString() ?? _residentialCtrl.text;
                  _waterCtrl.text = d['water_area']?.toString() ?? _waterCtrl.text;
                  _stonyCtrl.text = d['stony_soil_area']?.toString() ?? _stonyCtrl.text;

                  // families
                  _familiesGeneralCtrl.text = d['general_families']?.toString() ?? _familiesGeneralCtrl.text;
                  _familiesOBCCtrl.text = d['obc_families']?.toString() ?? _familiesOBCCtrl.text;
                  _familiesSCCtrl.text = d['scheduled_caste_families']?.toString() ?? _familiesSCCtrl.text;
                  _familiesSTCtrl.text = d['scheduled_tribe_families']?.toString() ?? _familiesSTCtrl.text;
                  _familiesSocialTotalCtrl.text = d['total_family']?.toString() ?? _familiesSocialTotalCtrl.text;
                  _familiesFarmingCtrl.text = d['farming_families']?.toString() ?? _familiesFarmingCtrl.text;
                  _familiesLabourCtrl.text = d['farm_labour_families']?.toString() ?? _familiesLabourCtrl.text;
                  _familiesGovtCtrl.text = d['govt_job_families']?.toString() ?? _familiesGovtCtrl.text;
                  _familiesNonGovtCtrl.text = d['non_govt_job_families']?.toString() ?? _familiesNonGovtCtrl.text;
                  _familiesBusinessCtrl.text = d['private_business_families']?.toString() ?? _familiesBusinessCtrl.text;
                  _familiesUnemployedCtrl.text = d['unemployed_families']?.toString() ?? _familiesUnemployedCtrl.text;

                  // connectivity & facilities
                  _nearestCity.text = d['nearest_city']?.toString() ?? _nearestCity.text;
                  _distanceToCity.text = d['distance_to_nearest_city']?.toString() ?? _distanceToCity.text;
                  _headquartersName.text = d['taluka_headquarters']?.toString() ?? _headquartersName.text;
                  _distanceToHQ.text = d['distance_to_taluka_headquarters']?.toString() ?? _distanceToHQ.text;
                  _districtHeadquartersName.text = d['district_headquarters']?.toString() ?? _districtHeadquartersName.text;
                  _distanceToDistrictHQ.text = d['distance_to_district_headquarters']?.toString() ?? _distanceToDistrictHQ.text;
                  _busStationDetails.text = d['bus_station']?.toString() ?? _busStationDetails.text;
                  _railwayStationDetails.text = d['railway_station']?.toString() ?? _railwayStationDetails.text;
                  _postOfficeDetails.text = d['post_office']?.toString() ?? _postOfficeDetails.text;
                  _policeStationDetails.text = d['police_station']?.toString() ?? _policeStationDetails.text;
                  _bankDetails.text = d['bank']?.toString() ?? _bankDetails.text;

                  // infrastructure booleans and counts
                  hasAsphaltRoad = d['approach_asphalt_road'] == true || (d['approach_asphalt_road_count'] is num && d['approach_asphalt_road_count'] > 0);
                  _asphaltRoadCount.text = d['approach_asphalt_road_count']?.toString() ?? _asphaltRoadCount.text;
                  hasRawRoad = d['approach_raw_road'] == true || (d['approach_raw_road_count'] is num && d['approach_raw_road_count'] > 0);
                  _rawRoadCount.text = d['approach_raw_road_count']?.toString() ?? _rawRoadCount.text;
                  hasWaterSystem = d['water_system'] == true || (d['water_system_count'] is num && d['water_system_count'] > 0);
                  _waterSystemCount.text = d['water_system_count']?.toString() ?? _waterSystemCount.text;
                  hasDrainage = d['drainage_system'] == true || (d['drainage_system_count'] is num && d['drainage_system_count'] > 0);
                  _drainageSystemCount.text = d['drainage_system_count']?.toString() ?? _drainageSystemCount.text;
                  hasElectricity = d['electricity_system'] == true || (d['electricity_system_count'] is num && d['electricity_system_count'] > 0);
                  _electricitySystemCount.text = d['electricity_system_count']?.toString() ?? _electricitySystemCount.text;
                  hasWasteDisposal = d['public_waste_disposal'] == true || (d['public_waste_disposal_count'] is num && d['public_waste_disposal_count'] > 0);
                  _wasteDisposalCount.text = d['public_waste_disposal_count']?.toString() ?? _wasteDisposalCount.text;

                  hasWaterStorage = d['water_storage_arrangement'] == true || (d['water_storage_arrangement_count'] is num && d['water_storage_arrangement_count'] > 0);
                  _waterStorageCount.text = d['water_storage_arrangement_count']?.toString() ?? _waterStorageCount.text;
                  hasPublicWell = d['public_well'] == true || (d['public_well_count'] is num && d['public_well_count'] > 0);
                  _publicWellCount.text = d['public_well_count']?.toString() ?? _publicWellCount.text;
                  hasPublicPond = d['public_pond'] == true || (d['public_pond_count'] is num && d['public_pond_count'] > 0);
                  _publicPondCount.text = d['public_pond_count']?.toString() ?? _publicPondCount.text;
                  hasWaterForCattle = d['water_for_cattle'] == true || (d['water_for_cattle_count'] is num && d['water_for_cattle_count'] > 0);
                  _waterForCattleCount.text = d['water_for_cattle_count']?.toString() ?? _waterForCattleCount.text;

                  hasPrimarySchool = d['primary_school'] == true || (d['primary_school_count'] is num && d['primary_school_count'] > 0);
                  _primarySchoolCount.text = d['primary_school_count']?.toString() ?? _primarySchoolCount.text;
                  hasSecondarySchool = d['secondary_school'] == true || (d['secondary_school_count'] is num && d['secondary_school_count'] > 0);
                  _secondarySchoolCount.text = d['secondary_school_count']?.toString() ?? _secondarySchoolCount.text;
                  hasHigherSecondary = d['higher_secondary_school'] == true || (d['higher_secondary_school_count'] is num && d['higher_secondary_school_count'] > 0);
                  _higherSecondaryCount.text = d['higher_secondary_school_count']?.toString() ?? _higherSecondaryCount.text;
                  hasCollege = d['college'] == true || (d['college_count'] is num && d['college_count'] > 0);
                  _collegeCount.text = d['college_count']?.toString() ?? _collegeCount.text;
                  hasUniversity = d['university'] == true || (d['university_count'] is num && d['university_count'] > 0);
                  _universityCount.text = d['university_count']?.toString() ?? _universityCount.text;
                  hasAnganwadi = d['anganwadi'] == true || (d['anganwadi_count'] is num && d['anganwadi_count'] > 0);
                  _anganwadiCount.text = d['anganwadi_count']?.toString() ?? _anganwadiCount.text;
                  hasItc = d['industrial_training_centre'] == true || (d['industrial_training_centre_count'] is num && d['industrial_training_centre_count'] > 0);
                  _itcCount.text = d['industrial_training_centre_count']?.toString() ?? _itcCount.text;

                  hasDispensary = d['dispensary'] == true || (d['dispensary_count'] is num && d['dispensary_count'] > 0);
                  _dispensaryCount.text = d['dispensary_count']?.toString() ?? _dispensaryCount.text;
                  hasPhc = d['primary_health_centre'] == true || (d['primary_health_centre_count'] is num && d['primary_health_centre_count'] > 0);
                  _phcCount.text = d['primary_health_centre_count']?.toString() ?? _phcCount.text;
                  hasGovHospital = d['government_hospital'] == true || (d['government_hospital_count'] is num && d['government_hospital_count'] > 0);
                  _govHospitalCount.text = d['government_hospital_count']?.toString() ?? _govHospitalCount.text;
                  hasPrivateHospital = d['private_hospital'] == true || (d['private_hospital_count'] is num && d['private_hospital_count'] > 0);
                  _privateHospitalCount.text = d['private_hospital_count']?.toString() ?? _privateHospitalCount.text;
                  hasDrugStore = d['drug_store'] == true || (d['drug_store_count'] is num && d['drug_store_count'] > 0);
                  _drugStoreCount.text = d['drug_store_count']?.toString() ?? _drugStoreCount.text;
                  hasAnimalHospital = d['animal_hospital'] == true || (d['animal_hospital_count'] is num && d['animal_hospital_count'] > 0);
                  _animalHospitalCount.text = d['animal_hospital_count']?.toString() ?? _animalHospitalCount.text;

                  hasCommunityHall = d['community_hall'] == true || (d['community_hall_count'] is num && d['community_hall_count'] > 0);
                  _communityHallCount.text = d['community_hall_count']?.toString() ?? _communityHallCount.text;
                  hasFairPriceShop = d['fair_price_shop'] == true || (d['fair_price_shop_count'] is num && d['fair_price_shop_count'] > 0);
                  _fairPriceShopCount.text = d['fair_price_shop_count']?.toString() ?? _fairPriceShopCount.text;
                  hasGroceryMarket = d['grocery_market'] == true || (d['grocery_market_count'] is num && d['grocery_market_count'] > 0);
                  _groceryMarketCount.text = d['grocery_market_count']?.toString() ?? _groceryMarketCount.text;
                  hasVegetableMarket = d['vegetable_market'] == true || (d['vegetable_market_count'] is num && d['vegetable_market_count'] > 0);
                  _vegetableMarketCount.text = d['vegetable_market_count']?.toString() ?? _vegetableMarketCount.text;
                  hasGrindingMill = d['grain_grinding_mill'] == true || (d['grain_grinding_mill_count'] is num && d['grain_grinding_mill_count'] > 0);
                  _grindingMillCount.text = d['grain_grinding_mill_count']?.toString() ?? _grindingMillCount.text;
                  hasRestaurant = d['restaurant_hotel'] == true || (d['restaurant_hotel_count'] is num && d['restaurant_hotel_count'] > 0);
                  _restaurantCount.text = d['restaurant_hotel_count']?.toString() ?? _restaurantCount.text;
                  hasPublicTransport = d['public_transport_system'] == true || (d['public_transport_system_count'] is num && d['public_transport_system_count'] > 0);
                  _publicTransportCount.text = d['public_transport_system_count']?.toString() ?? _publicTransportCount.text;
                  hasCooperative = d['cooperative_society'] == true || (d['cooperative_society_count'] is num && d['cooperative_society_count'] > 0);
                  _cooperativeCount.text = d['cooperative_society_count']?.toString() ?? _cooperativeCount.text;
                  hasPublicGarden = d['public_garden_park'] == true || (d['public_garden_park_count'] is num && d['public_garden_park_count'] > 0);
                  _publicGardenCount.text = d['public_garden_park_count']?.toString() ?? _publicGardenCount.text;
                  hasCinema = d['cinema_theatre'] == true || (d['cinema_theatre_count'] is num && d['cinema_theatre_count'] > 0);
                  _cinemaCount.text = d['cinema_theatre_count']?.toString() ?? _cinemaCount.text;
                  hasColdStorage = d['cold_storage'] == true || (d['cold_storage_count'] is num && d['cold_storage_count'] > 0);
                  _coldStorageCount.text = d['cold_storage_count']?.toString() ?? _coldStorageCount.text;
                  hasSportsGround = d['sports_ground'] == true || (d['sports_ground_count'] is num && d['sports_ground_count'] > 0);
                  _sportsGroundCount.text = d['sports_ground_count']?.toString() ?? _sportsGroundCount.text;

                  hasTemple = d['temple'] == true || (d['temple_count'] is num && d['temple_count'] > 0);
                  _templeCount.text = d['temple_count']?.toString() ?? _templeCount.text;
                  hasMosque = d['mosque'] == true || (d['mosque_count'] is num && d['mosque_count'] > 0);
                  _mosqueCount.text = d['mosque_count']?.toString() ?? _mosqueCount.text;
                  hasOtherReligious = d['other_religious_place'] == true || (d['other_religious_place_count'] is num && d['other_religious_place_count'] > 0);
                  _otherReligiousCount.text = d['other_religious_place_count']?.toString() ?? _otherReligiousCount.text;
                  hasCremation = d['cremation'] == true || (d['cremation_count'] is num && d['cremation_count'] > 0);
                  _cremationGroundCount.text = d['cremation_count']?.toString() ?? _cremationGroundCount.text;
                  hasCemetery = d['cemetery'] == true || (d['cemetery_count'] is num && d['cemetery_count'] > 0);
                  _cemeteryCount.text = d['cemetery_count']?.toString() ?? _cemeteryCount.text;

                  // attachments: lat/lon
                  if (d['lat'] != null && d['lon'] != null) {
                    _lat = double.tryParse(d['lat'].toString());
                    _lng = double.tryParse(d['lon'].toString());
                    _gpsLocation = '${_lat ?? ''},${_lng ?? ''}';
                  }
                }
              }
            } catch (_) {}
            _isInitializing = false;
            if (mounted) setState(() {});
          } else {
            if (mounted) {
              _villageNameCtrl.text = v['name']?.toString() ?? '';
              _talukaCtrl.text = v['taluka']?.toString() ?? '';
              _districtCtrl.text = v['district']?.toString() ?? '';
            }
            _isInitializing = false;
            if (mounted) setState(() {});
          }
        } else {
          if (!mounted) return;
          await showGeneralDialog<void>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (ctx, animation, secondaryAnimation) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                title: const Text('Village not found'),
                content: const Text('Village not found near you'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                ],
              ),
            ),
            transitionBuilder: (ctx, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
          if (!mounted) return;
          // Return to app root (avoid importing HomeScreen to prevent circular imports)
          Navigator.of(context).popUntil((route) => route.isFirst);
          _isInitializing = false;
          if (mounted) setState(() {});
          return;
        }
      }
    } catch (_) {
      // Any error during initialization should stop the loading indicator.
    } catch (_) {}

    final id = await LocalDb().insertEntry({
      'payload': jsonEncode({}),
      'imagePath': null,
      'lat': _lat,
      'lng': _lng,
      'status': 'draft',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'remoteSurveyId': _remoteSurveyId,
    });
    if (mounted) {
      setState(() {
        _draftId = id;
        if (_isInitializing) _isInitializing = false;
      });
    }
  }

  Map<String, dynamic> _collectPayload() => {
    'villageName': _villageNameCtrl.text,
    'gramPanchayat': _gpCtrl.text, // gram_panchayat_office
    'totalPopulation': int.tryParse(_totalPopulationCtrl.text.trim()),
    'totalFamily': int.tryParse(_familiesSocialTotalCtrl.text.trim()),
    'agriLand': double.tryParse(_agriLandCtrl.text.trim()),
    'irrigatedLand': double.tryParse(_irrigatedCtrl.text.trim()),
    'unirrigatedLand': double.tryParse(_unirrigatedCtrl.text.trim()),
    'residentialLand': double.tryParse(_residentialCtrl.text.trim()),
    'waterArea': double.tryParse(_waterCtrl.text.trim()),
    'stonyArea': double.tryParse(_stonyCtrl.text.trim()),
    'totalArea': double.tryParse(_totalAreaCtrl.text.trim()),
    'generalFamilies': int.tryParse(_familiesGeneralCtrl.text.trim()),
    'obcFamilies': int.tryParse(_familiesOBCCtrl.text.trim()),
    'scFamilies': int.tryParse(_familiesSCCtrl.text.trim()),
    'stFamilies': int.tryParse(_familiesSTCtrl.text.trim()),
    'farmingFamilies': int.tryParse(_familiesFarmingCtrl.text.trim()),
    'farmLabourFamilies': int.tryParse(_familiesLabourCtrl.text.trim()),
    'govtJobFamilies': int.tryParse(_familiesGovtCtrl.text.trim()),
    'nonGovtJobFamilies': int.tryParse(_familiesNonGovtCtrl.text.trim()),
    'businessFamilies': int.tryParse(_familiesBusinessCtrl.text.trim()),
    'unemployedFamilies': int.tryParse(_familiesUnemployedCtrl.text.trim()),
    'nearestCity': _nearestCity.text,
    'distanceToCity': double.tryParse(_distanceToCity.text.trim()),
    'talukaHeadquarters': _headquartersName.text,
    'distanceToHQ': double.tryParse(_distanceToHQ.text.trim()),
    'districtHeadquarters': _districtHeadquartersName.text,
    'distanceToDistrictHQ': double.tryParse(_distanceToDistrictHQ.text.trim()),
    'busStation': _busStationDetails.text,
    'railwayStation': _railwayStationDetails.text,
    'postOffice': _postOfficeDetails.text,
    'policeStation': _policeStationDetails.text,
    'bank': _bankDetails.text,
    'hasAsphaltRoad': hasAsphaltRoad ?? false,
    'asphaltRoadCount': int.tryParse(_asphaltRoadCount.text.trim()),
    'hasRawRoad': hasRawRoad ?? false,
    'rawRoadCount': int.tryParse(_rawRoadCount.text.trim()),
    'hasWaterSystem': hasWaterSystem ?? false,
    'waterSystemCount': int.tryParse(_waterSystemCount.text.trim()),
    'hasDrainage': hasDrainage ?? false,
    'drainageSystemCount': int.tryParse(_drainageSystemCount.text.trim()),
    'hasElectricity': hasElectricity ?? false,
    'electricitySystemCount': int.tryParse(_electricitySystemCount.text.trim()),
    'hasWasteDisposal': hasWasteDisposal ?? false,
    'wasteDisposalCount': int.tryParse(_wasteDisposalCount.text.trim()),
    'hasWaterStorage': hasWaterStorage ?? false,
    'waterStorageCount': int.tryParse(_waterStorageCount.text.trim()),
    'hasPublicWell': hasPublicWell ?? false,
    'publicWellCount': int.tryParse(_publicWellCount.text.trim()),
    'hasPublicPond': hasPublicPond ?? false,
    'publicPondCount': int.tryParse(_publicPondCount.text.trim()),
    'hasWaterForCattle': hasWaterForCattle ?? false,
    'waterForCattleCount': int.tryParse(_waterForCattleCount.text.trim()),
    'hasPrimarySchool': hasPrimarySchool ?? false,
    'primarySchoolCount': int.tryParse(_primarySchoolCount.text.trim()),
    'hasSecondarySchool': hasSecondarySchool ?? false,
    'secondarySchoolCount': int.tryParse(_secondarySchoolCount.text.trim()),
    'hasHigherSecondary': hasHigherSecondary ?? false,
    'higherSecondarySchoolCount': int.tryParse(_higherSecondaryCount.text.trim()),
    'hasCollege': hasCollege ?? false,
    'collegeCount': int.tryParse(_collegeCount.text.trim()),
    'hasUniversity': hasUniversity ?? false,
    'universityCount': int.tryParse(_universityCount.text.trim()),
    'hasAnganwadi': hasAnganwadi ?? false,
    'anganwadiCount': int.tryParse(_anganwadiCount.text.trim()),
    'hasItc': hasItc ?? false,
    'itcCount': int.tryParse(_itcCount.text.trim()),
    'hasDispensary': hasDispensary ?? false,
    'dispensaryCount': int.tryParse(_dispensaryCount.text.trim()),
    'hasPhc': hasPhc ?? false,
    'phcCount': int.tryParse(_phcCount.text.trim()),
    'hasGovHospital': hasGovHospital ?? false,
    'govHospitalCount': int.tryParse(_govHospitalCount.text.trim()),
    'hasPrivateHospital': hasPrivateHospital ?? false,
    'privateHospitalCount': int.tryParse(_privateHospitalCount.text.trim()),
    'hasDrugStore': hasDrugStore ?? false,
    'drugStoreCount': int.tryParse(_drugStoreCount.text.trim()),
    'hasAnimalHospital': hasAnimalHospital ?? false,
    'animalHospitalCount': int.tryParse(_animalHospitalCount.text.trim()),
    'hasCommunityHall': hasCommunityHall ?? false,
    'communityHallCount': int.tryParse(_communityHallCount.text.trim()),
    'hasFairPriceShop': hasFairPriceShop ?? false,
    'fairPriceShopCount': int.tryParse(_fairPriceShopCount.text.trim()),
    'hasGroceryMarket': hasGroceryMarket ?? false,
    'groceryMarketCount': int.tryParse(_groceryMarketCount.text.trim()),
    'hasVegetableMarket': hasVegetableMarket ?? false,
    'vegetableMarketCount': int.tryParse(_vegetableMarketCount.text.trim()),
    'hasGrindingMill': hasGrindingMill ?? false,
    'grindingMillCount': int.tryParse(_grindingMillCount.text.trim()),
    'hasRestaurant': hasRestaurant ?? false,
    'restaurantCount': int.tryParse(_restaurantCount.text.trim()),
    'hasPublicTransport': hasPublicTransport ?? false,
    'publicTransportCount': int.tryParse(_publicTransportCount.text.trim()),
    'hasCooperative': hasCooperative ?? false,
    'cooperativeCount': int.tryParse(_cooperativeCount.text.trim()),
    'hasPublicGarden': hasPublicGarden ?? false,
    'publicGardenCount': int.tryParse(_publicGardenCount.text.trim()),
    'hasCinema': hasCinema ?? false,
    'cinemaCount': int.tryParse(_cinemaCount.text.trim()),
    'hasColdStorage': hasColdStorage ?? false,
    'coldStorageCount': int.tryParse(_coldStorageCount.text.trim()),
    'hasSportsGround': hasSportsGround ?? false,
    'sportsGroundCount': int.tryParse(_sportsGroundCount.text.trim()),
    'hasTemple': hasTemple ?? false,
    'templeCount': int.tryParse(_templeCount.text.trim()),
    'hasMosque': hasMosque ?? false,
    'mosqueCount': int.tryParse(_mosqueCount.text.trim()),
    'hasOtherReligious': hasOtherReligious ?? false,
    'otherReligiousCount': int.tryParse(_otherReligiousCount.text.trim()),
    'hasCremation': hasCremation ?? false,
    'cremationCount': int.tryParse(_cremationGroundCount.text.trim()),
    'hasCemetery': hasCemetery ?? false,
    'cemeteryCount': int.tryParse(_cemeteryCount.text.trim()),
    'photo': _villagePhotoPath,
    'gps': _gpsLocation,
  };

  Future<void> _saveToLocalDb({required String surveyStatus, required String localDbStatus}) async {
    if (_draftId == null) return;
    final payload = _collectPayload()..['status'] = surveyStatus;
    await LocalDb().updateEntry(_draftId!, {
      'payload': jsonEncode(payload),
      'imagePath': _villagePhotoPath,
      'lat': _lat,
      'lng': _lng,
      'status': localDbStatus, // 'draft' or 'pending'
      'remoteSurveyId': _remoteSurveyId,
    });
  }

  Future<void> _processSubmission({required String surveyStatus}) async {
    if (!mounted) return;
    setState(() => _processingAction = surveyStatus == 'completed' ? 'submit' : 'draft');
    // Save draft first to ensure data is not lost.
    // The local DB status will be updated to 'pending' if upload fails.
    await _saveToLocalDb(surveyStatus: surveyStatus, localDbStatus: 'draft');
    if (_draftId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Could not save draft locally.')));
      return;
    }

    // Now, attempt to upload to the server immediately.
    final token = await AuthService().getToken();
    var uploaded = false;
    if (_remoteSurveyId != null && token != null) {
      final payload = _collectPayload()..['status'] = surveyStatus;
      try {
        uploaded = await VillageService().updateSurvey(_remoteSurveyId!, payload, _villagePhotoPath, bearerToken: token);
      } catch (_) {
        uploaded = false;
      }
    }
    
    String message;
    if (uploaded) {
      // If upload was successful, we can remove the entry from the local DB queue.
      await LocalDb().deleteEntry(_draftId!);
      message = surveyStatus == 'draft' ? 'Draft saved to server successfully' : 'Survey submitted successfully';
    } else {
      // If upload failed, it remains in the local DB to be synced later.
      // Update the local status to 'pending' so it shows up on the LocalEntriesPage.
      await _saveToLocalDb(surveyStatus: surveyStatus, localDbStatus: 'pending');
      message = 'Saved locally. Will sync with server later.';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _processingAction = null);
    Navigator.of(context).pop();
  }

  bool _validateForm() {
    final newErrors = <String, String?>{};
    bool isValid = true;

    void check(TextEditingController ctrl, String key, [int? step]) {
      if (ctrl.text.trim().isEmpty) {
        newErrors[key] = 'This field is mandatory';
        isValid = false;
        if (step != null && _currentStep != step) {
          setState(() => _currentStep = step);
        }
      }
    }

    void checkBool(bool? val, String key, [int? step]) {
      if (val == null) {
        newErrors[key] = 'Please select Yes or No';
        isValid = false;
        if (step != null && _currentStep != step) {
          setState(() => _currentStep = step);
        }
      }
    }

    // Step 0
    check(_totalPopulationCtrl, 'totalPopulation', 0);

    // Step 1
    check(_agriLandCtrl, 'agriLand', 1);
    check(_irrigatedCtrl, 'irrigatedLand', 1);
    check(_unirrigatedCtrl, 'unirrigatedLand', 1);
    check(_residentialCtrl, 'residentialLand', 1);
    check(_waterCtrl, 'waterArea', 1);
    check(_stonyCtrl, 'stonyArea', 1);

    // Step 2
    check(_familiesGeneralCtrl, 'generalFamilies', 2);
    check(_familiesOBCCtrl, 'obcFamilies', 2);
    check(_familiesSCCtrl, 'scFamilies', 2);
    check(_familiesSTCtrl, 'stFamilies', 2);
    check(_familiesFarmingCtrl, 'farmingFamilies', 2);
    check(_familiesLabourCtrl, 'farmLabourFamilies', 2);
    check(_familiesGovtCtrl, 'govtJobFamilies', 2);
    check(_familiesNonGovtCtrl, 'nonGovtJobFamilies', 2);
    check(_familiesBusinessCtrl, 'businessFamilies', 2);
    check(_familiesUnemployedCtrl, 'unemployedFamilies', 2);

    // Step 3
    check(_nearestCity, 'nearestCity', 3);
    check(_distanceToCity, 'distanceToCity', 3);
    check(_headquartersName, 'talukaHeadquarters', 3);
    check(_distanceToHQ, 'distanceToHQ', 3);
    check(_districtHeadquartersName, 'districtHeadquarters', 3);
    check(_distanceToDistrictHQ, 'distanceToDistrictHQ', 3);
    check(_busStationDetails, 'busStation', 3);
    check(_railwayStationDetails, 'railwayStation', 3);
    check(_postOfficeDetails, 'postOffice', 3);
    check(_policeStationDetails, 'policeStation', 3);
    check(_bankDetails, 'bank', 3);

    // Step 4 - Infrastructure
    final infraChecks = {
      'hasAsphaltRoad': {'bool': hasAsphaltRoad, 'ctrl': _asphaltRoadCount}, 'hasRawRoad': {'bool': hasRawRoad, 'ctrl': _rawRoadCount},
      'hasWaterSystem': {'bool': hasWaterSystem, 'ctrl': _waterSystemCount}, 'hasDrainage': {'bool': hasDrainage, 'ctrl': _drainageSystemCount},
      'hasElectricity': {'bool': hasElectricity, 'ctrl': _electricitySystemCount}, 'hasWasteDisposal': {'bool': hasWasteDisposal, 'ctrl': _wasteDisposalCount},
      'hasWaterStorage': {'bool': hasWaterStorage, 'ctrl': _waterStorageCount}, 'hasPublicWell': {'bool': hasPublicWell, 'ctrl': _publicWellCount},
      'hasPublicPond': {'bool': hasPublicPond, 'ctrl': _publicPondCount}, 'hasWaterForCattle': {'bool': hasWaterForCattle, 'ctrl': _waterForCattleCount},
      'hasPrimarySchool': {'bool': hasPrimarySchool, 'ctrl': _primarySchoolCount}, 'hasSecondarySchool': {'bool': hasSecondarySchool, 'ctrl': _secondarySchoolCount},
      'hasHigherSecondary': {'bool': hasHigherSecondary, 'ctrl': _higherSecondaryCount}, 'hasCollege': {'bool': hasCollege, 'ctrl': _collegeCount},
      'hasUniversity': {'bool': hasUniversity, 'ctrl': _universityCount}, 'hasAnganwadi': {'bool': hasAnganwadi, 'ctrl': _anganwadiCount}, 'hasItc': {'bool': hasItc, 'ctrl': _itcCount},
      'hasDispensary': {'bool': hasDispensary, 'ctrl': _dispensaryCount}, 'hasPhc': {'bool': hasPhc, 'ctrl': _phcCount}, 'hasGovHospital': {'bool': hasGovHospital, 'ctrl': _govHospitalCount},
      'hasPrivateHospital': {'bool': hasPrivateHospital, 'ctrl': _privateHospitalCount}, 'hasDrugStore': {'bool': hasDrugStore, 'ctrl': _drugStoreCount},
      'hasAnimalHospital': {'bool': hasAnimalHospital, 'ctrl': _animalHospitalCount}, 'hasCommunityHall': {'bool': hasCommunityHall, 'ctrl': _communityHallCount},
      'hasFairPriceShop': {'bool': hasFairPriceShop, 'ctrl': _fairPriceShopCount}, 'hasGroceryMarket': {'bool': hasGroceryMarket, 'ctrl': _groceryMarketCount},
      'hasVegetableMarket': {'bool': hasVegetableMarket, 'ctrl': _vegetableMarketCount}, 'hasGrindingMill': {'bool': hasGrindingMill, 'ctrl': _grindingMillCount},
      'hasRestaurant': {'bool': hasRestaurant, 'ctrl': _restaurantCount}, 'hasPublicTransport': {'bool': hasPublicTransport, 'ctrl': _publicTransportCount},
      'hasCooperative': {'bool': hasCooperative, 'ctrl': _cooperativeCount}, 'hasPublicGarden': {'bool': hasPublicGarden, 'ctrl': _publicGardenCount},
      'hasCinema': {'bool': hasCinema, 'ctrl': _cinemaCount}, 'hasColdStorage': {'bool': hasColdStorage, 'ctrl': _coldStorageCount},
      'hasSportsGround': {'bool': hasSportsGround, 'ctrl': _sportsGroundCount}, 'hasTemple': {'bool': hasTemple, 'ctrl': _templeCount}, 'hasMosque': {'bool': hasMosque, 'ctrl': _mosqueCount},
      'hasOtherReligious': {'bool': hasOtherReligious, 'ctrl': _otherReligiousCount}, 'hasCremation': {'bool': hasCremation, 'ctrl': _cremationGroundCount},
      'hasCemetery': {'bool': hasCemetery, 'ctrl': _cemeteryCount},
    };
    infraChecks.forEach((key, value) {
      checkBool(value['bool'] as bool?, key, 4);
      if (value['bool'] == true) {
        check(value['ctrl'] as TextEditingController, '${key}Count', 4);
      }
    });

    setState(() => _errors.addAll(newErrors));
    return isValid;
  }

  Future<void> _handleSubmit() async {
    setState(() => _errors.clear());
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all mandatory fields.'), backgroundColor: Colors.red));
      return;
    }
    await _processSubmission(surveyStatus: 'completed');
  }

  Future<void> _handleSaveDraft() async {
    await _processSubmission(surveyStatus: 'draft');
  }

  Future<void> _capturePhotoAndTag() async {
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraCapturePage()));
    if (res != null && mounted) {
      _villagePhotoPath = res['path'] as String?;
      final lat = res['lat'];
      final lng = res['lng'];
      if (lat != null && lng != null) {
        _lat = lat as double?;
        _lng = lng as double?;
        _gpsLocation = '$_lat,$_lng';
      }
      await _saveToLocalDb(surveyStatus: 'draft', localDbStatus: 'draft'); // Save draft after taking photo
      setState(() {});
    }
  }

  Future<Position?> getPositionWithFallback({Duration timeout = const Duration(seconds:10)}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      // show user dialog asking to enable location
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // show rationale / settings prompt
      return null;
    }

    try {
      // let the platform have a bit more time to acquire a fix
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: timeout,
      );
    } catch (e) {
      // timeout or transient failure (e.g., kCLErrorLocationUnknown) — fallback
      final last = await Geolocator.getLastKnownPosition();
      return last;
    }
  } catch (e) {
    // last-resort fallback
    return await Geolocator.getLastKnownPosition();
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Village Survey')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: 20),
              Text('Loading village details...'),
            ],
          ),
        ),
      );
    }

    final steps = <Step>[
      Step(
        title: const Text('General Identification'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          TextFormField(controller: _villageNameCtrl, decoration: const InputDecoration(labelText: 'Village name'), readOnly: true),
          const SizedBox(height: 12),
          TextFormField(controller: _gpCtrl, decoration: InputDecoration(labelText: 'Gram Panchayat', errorText: _errors['gramPanchayat']), readOnly: true),
          const SizedBox(height: 12),
          TextFormField(controller: _talukaCtrl, decoration: const InputDecoration(labelText: 'Taluka'), readOnly: true),
          const SizedBox(height: 12),
          TextFormField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District'), readOnly: true),
          const SizedBox(height: 12),
          TextFormField(controller: _totalPopulationCtrl, decoration: InputDecoration(labelText: 'Population', errorText: _errors['totalPopulation']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ]),
        isActive: _currentStep == 0,
      ),
      Step(
        title: const Text('Village Area Details'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          TextFormField(controller: _agriLandCtrl, decoration: InputDecoration(labelText: 'Agricultural Land Area', errorText: _errors['agriLand']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _irrigatedCtrl, decoration: InputDecoration(labelText: 'Irrigated Land Area', errorText: _errors['irrigatedLand']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _unirrigatedCtrl, decoration: InputDecoration(labelText: 'Unirrigated Land Area', errorText: _errors['unirrigatedLand']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _residentialCtrl, decoration: InputDecoration(labelText: 'Residential Land Area', errorText: _errors['residentialLand']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _waterCtrl, decoration: InputDecoration(labelText: 'Area under Water', errorText: _errors['waterArea']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _stonyCtrl, decoration: InputDecoration(labelText: 'Stony Soil Area', errorText: _errors['stonyArea']), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _totalAreaCtrl, decoration: const InputDecoration(labelText: 'Total Area'), readOnly: true),
        ]),
        isActive: _currentStep == 1,
      ),
      Step(
        title: const Text('Family Demographics'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => setState(() => _currentStep = 2), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('3.1. Families by Social Group', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          // Families by social group
          Row(children: [
            Expanded(child: TextFormField(controller: _familiesGeneralCtrl, decoration: InputDecoration(labelText: 'General', errorText: _errors['generalFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _familiesOBCCtrl, decoration: InputDecoration(labelText: 'OBC', errorText: _errors['obcFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _familiesSCCtrl, decoration: InputDecoration(labelText: 'SC', errorText: _errors['scFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _familiesSTCtrl, decoration: InputDecoration(labelText: 'ST', errorText: _errors['stFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesSocialTotalCtrl, decoration: const InputDecoration(labelText: 'Total (social groups)'), readOnly: true),
          const SizedBox(height: 24),
          InkWell(onTap: () => setState(() => _currentStep = 2), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('3.2. Families by Primary Occupation', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          // Families by primary occupation
          TextFormField(controller: _familiesFarmingCtrl, decoration: InputDecoration(labelText: 'Farming families', errorText: _errors['farmingFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesLabourCtrl, decoration: InputDecoration(labelText: 'Farm labor families', errorText: _errors['farmLabourFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesGovtCtrl, decoration: InputDecoration(labelText: 'Govt/Semi-Govt job families', errorText: _errors['govtJobFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesNonGovtCtrl, decoration: InputDecoration(labelText: 'Other Non-Govt job families', errorText: _errors['nonGovtJobFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesBusinessCtrl, decoration: InputDecoration(labelText: 'Private business households', errorText: _errors['businessFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          TextFormField(controller: _familiesUnemployedCtrl, decoration: InputDecoration(labelText: 'Unemployed families', errorText: _errors['unemployedFamilies']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ]),
        isActive: _currentStep == 2,
      ),
      Step(
        title: const Text('Connectivity'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => setState(() => _currentStep = 3), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('4.1. Connectivity Distance (Detail & Distance in Km)', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          TextFormField(controller: _nearestCity, decoration: InputDecoration(labelText: 'Nearest City *', hintText: 'City Name', errorText: _errors['nearestCity'])),
          const SizedBox(height: 12),
          TextFormField(controller: _distanceToCity, decoration: InputDecoration(labelText: 'Distance to Nearest City (km) *', hintText: 'e.g., 10.5', errorText: _errors['distanceToCity']), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
          const SizedBox(height: 12),
          TextFormField(controller: _headquartersName, decoration: InputDecoration(labelText: 'Taluka Headquarters *', hintText: 'Headquarters Name', errorText: _errors['talukaHeadquarters'])),
          const SizedBox(height: 12),
          TextFormField(controller: _distanceToHQ, decoration: InputDecoration(labelText: 'Distance to Taluka Headquarters (km) *', hintText: 'e.g., 25.5', errorText: _errors['distanceToHQ']), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
          const SizedBox(height: 12),
          TextFormField(controller: _districtHeadquartersName, decoration: InputDecoration(labelText: 'District Headquarters *', hintText: 'Headquarters Name', errorText: _errors['districtHeadquarters'])),
          const SizedBox(height: 12),
          TextFormField(controller: _distanceToDistrictHQ, decoration: InputDecoration(labelText: 'Distance to District Headquarters (km) *', hintText: 'e.g., 50.2', errorText: _errors['distanceToDistrictHQ']), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
          const SizedBox(height: 24),
          InkWell(onTap: () => setState(() => _currentStep = 3), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('4.2. Facilities (Detail & Distance)', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          TextFormField(controller: _busStationDetails, decoration: InputDecoration(labelText: 'Bus Station Details *', hintText: 'e.g., Central Bus Stand, 2 km away', errorText: _errors['busStation'])),
          const SizedBox(height: 12),
          TextFormField(controller: _railwayStationDetails, decoration: InputDecoration(labelText: 'Railway Station Details *', hintText: 'e.g., City Railway Station, 15 km away', errorText: _errors['railwayStation'])),
          const SizedBox(height: 12),
          TextFormField(controller: _postOfficeDetails, decoration: InputDecoration(labelText: 'Post Office Details *', hintText: 'e.g., Main Post Office, 1 km away', errorText: _errors['postOffice'])),
          const SizedBox(height: 12),
          TextFormField(controller: _policeStationDetails, decoration: InputDecoration(labelText: 'Police Station Details *', hintText: 'e.g., Taluka Police Station, 8 km away', errorText: _errors['policeStation'])),
          const SizedBox(height: 12),
          TextFormField(controller: _bankDetails, decoration: InputDecoration(labelText: 'Bank Details *', hintText: 'e.g., State Bank, 5 km away', errorText: _errors['bank'])),
        ]),
        isActive: _currentStep == 3,
      ),
      Step(
        title: const Text('Infrastructure & Utilities'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 5.1 Roads, Water & Utilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.1. Roads, Water & Utilities (Enter length/coverage if Yes)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasAsphaltRoad'] != null || _errors['hasRawRoad'] != null || _errors['hasWaterSystem'] != null || _errors['hasDrainage'] != null || _errors['hasElectricity'] != null || _errors['hasWasteDisposal'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Approach Asphalt Road *', hasAsphaltRoad, (val) => setState(() => hasAsphaltRoad = val), errorText: _errors['hasAsphaltRoad']),
          if (hasAsphaltRoad == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _asphaltRoadCount, decoration: InputDecoration(labelText: 'Approach Asphalt Road (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasAsphaltRoadCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Approach Raw Road *', hasRawRoad, (val) => setState(() => hasRawRoad = val), errorText: _errors['hasRawRoad']),
          if (hasRawRoad == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _rawRoadCount, decoration: InputDecoration(labelText: 'Approach Raw Road (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasRawRoadCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Water system available *', hasWaterSystem, (val) => setState(() => hasWaterSystem = val), errorText: _errors['hasWaterSystem']),
          if (hasWaterSystem == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterSystemCount, decoration: InputDecoration(labelText: 'Water system (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasWaterSystemCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Drainage system available *', hasDrainage, (val) => setState(() => hasDrainage = val), errorText: _errors['hasDrainage']),
          if (hasDrainage == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _drainageSystemCount, decoration: InputDecoration(labelText: 'Drainage system (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasDrainageCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Electricity system available *', hasElectricity, (val) => setState(() => hasElectricity = val), errorText: _errors['hasElectricity']),
          if (hasElectricity == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _electricitySystemCount, decoration: InputDecoration(labelText: 'Electricity system (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasElectricityCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Public system for waste disposal *', hasWasteDisposal, (val) => setState(() => hasWasteDisposal = val), errorText: _errors['hasWasteDisposal']),
          if (hasWasteDisposal == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _wasteDisposalCount, decoration: InputDecoration(labelText: 'Public system for waste disposal (Detail/Count)', hintText: 'Enter Detail/Count if available', errorText: _errors['hasWasteDisposalCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),

          const SizedBox(height: 12),
          // 5.2 Public Water Sources
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.2. Public Water Sources (Enter count if available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasWaterStorage'] != null || _errors['hasPublicWell'] != null || _errors['hasPublicPond'] != null || _errors['hasWaterForCattle'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Water Storage Arrangement *', hasWaterStorage, (val) => setState(() => hasWaterStorage = val), errorText: _errors['hasWaterStorage']),
          if (hasWaterStorage == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterStorageCount, decoration: InputDecoration(labelText: 'Water Storage Arrangement (count)', hintText: 'Enter count if available', errorText: _errors['hasWaterStorageCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Public Well *', hasPublicWell, (val) => setState(() => hasPublicWell = val), errorText: _errors['hasPublicWell']),
          if (hasPublicWell == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _publicWellCount, decoration: InputDecoration(labelText: 'Public Well (count)', hintText: 'Enter count if available', errorText: _errors['hasPublicWellCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Public Pond *', hasPublicPond, (val) => setState(() => hasPublicPond = val), errorText: _errors['hasPublicPond']),
          if (hasPublicPond == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _publicPondCount, decoration: InputDecoration(labelText: 'Public Pond (count)', hintText: 'Enter count if available', errorText: _errors['hasPublicPondCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Water for Cattle *', hasWaterForCattle, (val) => setState(() => hasWaterForCattle = val), errorText: _errors['hasWaterForCattle']),
          if (hasWaterForCattle == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterForCattleCount, decoration: InputDecoration(labelText: 'Water for Cattle (count)', hintText: 'Enter count if available', errorText: _errors['hasWaterForCattleCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),

          const SizedBox(height: 12),
          // 5.3 Education Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.3. Education Facilities (Enter count if available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasPrimarySchool'] != null || _errors['hasSecondarySchool'] != null || _errors['hasHigherSecondary'] != null || _errors['hasCollege'] != null || _errors['hasUniversity'] != null || _errors['hasAnganwadi'] != null || _errors['hasItc'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Primary school *', hasPrimarySchool, (val) => setState(() => hasPrimarySchool = val), errorText: _errors['hasPrimarySchool']),
          if (hasPrimarySchool == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _primarySchoolCount, decoration: InputDecoration(labelText: 'Primary school (count)', hintText: 'Enter count if available', errorText: _errors['hasPrimarySchoolCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Secondary school *', hasSecondarySchool, (val) => setState(() => hasSecondarySchool = val), errorText: _errors['hasSecondarySchool']),
          if (hasSecondarySchool == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _secondarySchoolCount, decoration: InputDecoration(labelText: 'Secondary school (count)', hintText: 'Enter count if available', errorText: _errors['hasSecondarySchoolCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Higher Secondary School *', hasHigherSecondary, (val) => setState(() => hasHigherSecondary = val), errorText: _errors['hasHigherSecondary']),
          if (hasHigherSecondary == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _higherSecondaryCount, decoration: InputDecoration(labelText: 'Higher Secondary School (count)', hintText: 'Enter count if available', errorText: _errors['hasHigherSecondaryCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('College *', hasCollege, (val) => setState(() => hasCollege = val), errorText: _errors['hasCollege']),
          if (hasCollege == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _collegeCount, decoration: InputDecoration(labelText: 'College (count)', hintText: 'Enter count if available', errorText: _errors['hasCollegeCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('University *', hasUniversity, (val) => setState(() => hasUniversity = val), errorText: _errors['hasUniversity']),
          if (hasUniversity == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _universityCount, decoration: InputDecoration(labelText: 'University (count)', hintText: 'Enter count if available', errorText: _errors['hasUniversityCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Anganwadi *', hasAnganwadi, (val) => setState(() => hasAnganwadi = val), errorText: _errors['hasAnganwadi']),
          if (hasAnganwadi == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _anganwadiCount, decoration: InputDecoration(labelText: 'Anganwadi (count)', hintText: 'Enter count if available', errorText: _errors['hasAnganwadiCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Industrial Training Centre *', hasItc, (val) => setState(() => hasItc = val), errorText: _errors['hasItc']),
          if (hasItc == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _itcCount, decoration: InputDecoration(labelText: 'Industrial Training Centre (count)', hintText: 'Enter count if available', errorText: _errors['hasItcCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),

          const SizedBox(height: 12),
          // 5.4 Health Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.4. Health Facilities (Enter count if available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasDispensary'] != null || _errors['hasPhc'] != null || _errors['hasGovHospital'] != null || _errors['hasPrivateHospital'] != null || _errors['hasDrugStore'] != null || _errors['hasAnimalHospital'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Dispensary *', hasDispensary, (val) => setState(() => hasDispensary = val), errorText: _errors['hasDispensary']),
          if (hasDispensary == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _dispensaryCount, decoration: InputDecoration(labelText: 'Dispensary (count)', hintText: 'Enter count if available', errorText: _errors['hasDispensaryCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Primary Health Centre *', hasPhc, (val) => setState(() => hasPhc = val), errorText: _errors['hasPhc']),
          if (hasPhc == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _phcCount, decoration: InputDecoration(labelText: 'Primary Health Centre (count)', hintText: 'Enter count if available', errorText: _errors['hasPhcCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Government Hospital *', hasGovHospital, (val) => setState(() => hasGovHospital = val), errorText: _errors['hasGovHospital']),
          if (hasGovHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _govHospitalCount, decoration: InputDecoration(labelText: 'Government Hospital (count)', hintText: 'Enter count if available', errorText: _errors['hasGovHospitalCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Private hospital *', hasPrivateHospital, (val) => setState(() => hasPrivateHospital = val), errorText: _errors['hasPrivateHospital']),
          if (hasPrivateHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _privateHospitalCount, decoration: InputDecoration(labelText: 'Private hospital (count)', hintText: 'Enter count if available', errorText: _errors['hasPrivateHospitalCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Drug store *', hasDrugStore, (val) => setState(() => hasDrugStore = val), errorText: _errors['hasDrugStore']),
          if (hasDrugStore == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _drugStoreCount, decoration: InputDecoration(labelText: 'Drug store (count)', hintText: 'Enter count if available', errorText: _errors['hasDrugStoreCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Animal Hospital *', hasAnimalHospital, (val) => setState(() => hasAnimalHospital = val), errorText: _errors['hasAnimalHospital']),
          if (hasAnimalHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _animalHospitalCount, decoration: InputDecoration(labelText: 'Animal Hospital (count)', hintText: 'Enter count if available', errorText: _errors['hasAnimalHospitalCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),

          const SizedBox(height: 12),
          // 5.5 Markets, Community & Services
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.5. Markets, Community & Services (Enter count if available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasCommunityHall'] != null || _errors['hasFairPriceShop'] != null || _errors['hasGroceryMarket'] != null || _errors['hasVegetableMarket'] != null || _errors['hasGrindingMill'] != null || _errors['hasRestaurant'] != null || _errors['hasPublicTransport'] != null || _errors['hasCooperative'] != null || _errors['hasPublicGarden'] != null || _errors['hasCinema'] != null || _errors['hasColdStorage'] != null || _errors['hasSportsGround'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Community Hall *', hasCommunityHall, (val) => setState(() => hasCommunityHall = val), errorText: _errors['hasCommunityHall']),
          if (hasCommunityHall == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _communityHallCount, decoration: InputDecoration(labelText: 'Community Hall (count)', hintText: 'Enter count if available', errorText: _errors['hasCommunityHallCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Fair price shop *', hasFairPriceShop, (val) => setState(() => hasFairPriceShop = val), errorText: _errors['hasFairPriceShop']),
          if (hasFairPriceShop == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _fairPriceShopCount, decoration: InputDecoration(labelText: 'Fair price shop (count)', hintText: 'Enter count if available', errorText: _errors['hasFairPriceShopCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Grocery market *', hasGroceryMarket, (val) => setState(() => hasGroceryMarket = val), errorText: _errors['hasGroceryMarket']),
          if (hasGroceryMarket == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _groceryMarketCount, decoration: InputDecoration(labelText: 'Grocery market (count)', hintText: 'Enter count if available', errorText: _errors['hasGroceryMarketCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Vegetable market *', hasVegetableMarket, (val) => setState(() => hasVegetableMarket = val), errorText: _errors['hasVegetableMarket']),
          if (hasVegetableMarket == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _vegetableMarketCount, decoration: InputDecoration(labelText: 'Vegetable market (count)', hintText: 'Enter count if available', errorText: _errors['hasVegetableMarketCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Grain grinding mill *', hasGrindingMill, (val) => setState(() => hasGrindingMill = val), errorText: _errors['hasGrindingMill']),
          if (hasGrindingMill == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _grindingMillCount, decoration: InputDecoration(labelText: 'Grain grinding mill (count)', hintText: 'Enter count if available', errorText: _errors['hasGrindingMillCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Restaurant/Hotel *', hasRestaurant, (val) => setState(() => hasRestaurant = val), errorText: _errors['hasRestaurant']),
          if (hasRestaurant == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _restaurantCount, decoration: InputDecoration(labelText: 'Restaurant/Hotel (count)', hintText: 'Enter count if available', errorText: _errors['hasRestaurantCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Public Transport System *', hasPublicTransport, (val) => setState(() => hasPublicTransport = val), errorText: _errors['hasPublicTransport']),
          if (hasPublicTransport == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _publicTransportCount, decoration: InputDecoration(labelText: 'Public Transport System (count)', hintText: 'Enter count if available', errorText: _errors['hasPublicTransportCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Cooperative Organization *', hasCooperative, (val) => setState(() => hasCooperative = val), errorText: _errors['hasCooperative']),
          if (hasCooperative == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _cooperativeCount, decoration: InputDecoration(labelText: 'Cooperative Organization (count)', hintText: 'Enter count if available', errorText: _errors['hasCooperativeCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Public Garden/Park *', hasPublicGarden, (val) => setState(() => hasPublicGarden = val), errorText: _errors['hasPublicGarden']),
          if (hasPublicGarden == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _publicGardenCount, decoration: InputDecoration(labelText: 'Public Garden/Park (count)', hintText: 'Enter count if available', errorText: _errors['hasPublicGardenCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Cinema/Theatre *', hasCinema, (val) => setState(() => hasCinema = val), errorText: _errors['hasCinema']),
          if (hasCinema == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _cinemaCount, decoration: InputDecoration(labelText: 'Cinema/Theatre (count)', hintText: 'Enter count if available', errorText: _errors['hasCinemaCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Cold Storage *', hasColdStorage, (val) => setState(() => hasColdStorage = val), errorText: _errors['hasColdStorage']),
          if (hasColdStorage == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _coldStorageCount, decoration: InputDecoration(labelText: 'Cold Storage (count)', hintText: 'Enter count if available', errorText: _errors['hasColdStorageCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          _buildRadioGroup('Sports Ground *', hasSportsGround, (val) => setState(() => hasSportsGround = val), errorText: _errors['hasSportsGround']),
          if (hasSportsGround == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _sportsGroundCount, decoration: InputDecoration(labelText: 'Sports Ground (count)', hintText: 'Enter count if available', errorText: _errors['hasSportsGroundCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),

          const SizedBox(height: 12),
          // 5.6 Religious/Mortality Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('5.6. Religious/Mortality Facilities (Enter count if available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (_errors['hasTemple'] != null || _errors['hasMosque'] != null || _errors['hasOtherReligious'] != null || _errors['hasCremation'] != null || _errors['hasCemetery'] != null) ? Colors.red : null)))),
          _buildRadioGroup('Temple *', hasTemple, (val) => setState(() => hasTemple = val), errorText: _errors['hasTemple']),
          if (hasTemple == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _templeCount, decoration: InputDecoration(labelText: 'Temple (count)', hintText: 'Enter count if available', errorText: _errors['hasTempleCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Mosque *', hasMosque, (val) => setState(() => hasMosque = val), errorText: _errors['hasMosque']),
          if (hasMosque == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _mosqueCount, decoration: InputDecoration(labelText: 'Mosque (count)', hintText: 'Enter count if available', errorText: _errors['hasMosqueCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Other Religious Place *', hasOtherReligious, (val) => setState(() => hasOtherReligious = val), errorText: _errors['hasOtherReligious']),
          if (hasOtherReligious == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _otherReligiousCount, decoration: InputDecoration(labelText: 'Other Religious Place (count)', hintText: 'Enter count if available', errorText: _errors['hasOtherReligiousCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Cremation Ground *', hasCremation, (val) => setState(() => hasCremation = val), errorText: _errors['hasCremation']),
          if (hasCremation == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _cremationGroundCount, decoration: InputDecoration(labelText: 'Cremation Ground (count)', hintText: 'Enter count if available', errorText: _errors['hasCremationCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          _buildRadioGroup('Cemetery *', hasCemetery, (val) => setState(() => hasCemetery = val), errorText: _errors['hasCemetery']),
          if (hasCemetery == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _cemeteryCount, decoration: InputDecoration(labelText: 'Cemetery (count)', hintText: 'Enter count if available', errorText: _errors['hasCemeteryCount']), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
        ]),
        isActive: _currentStep == 4,
      ),
      Step(
        title: const Text('Attachments & GPS'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          TextFormField(decoration: const InputDecoration(labelText: 'GPS Location'), readOnly: true, initialValue: _gpsLocation ?? ''),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _capturePhotoAndTag, icon: const Icon(Icons.camera_alt), label: const Text('Capture Photo (camera only)')),
          const SizedBox(height: 8),
          if (_remoteMedia.isNotEmpty) ...[
            const Divider(),
            const Text('Remote attachments', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _remoteMedia.length,
                itemBuilder: (ctx, i) {
                  final m = _remoteMedia[i];
                  final url = m['url']?.toString();
                  final type = m['type']?.toString();
                  final name = (m['name'] ?? m['caption'] ?? m['title'])?.toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () async {
                        if (url == null) return;
                        // For images show full-screen preview, otherwise open URL (web or mobile)
                        final isImage = url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.contains('image');
                        if (isImage) {
                          if (!mounted) return;
                          showGeneralDialog<void>(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            transitionDuration: const Duration(milliseconds: 250),
                            pageBuilder: (ctx, animation, secondaryAnimation) => BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Dialog(
                                insetPadding: const EdgeInsets.all(8),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Stack(children: [
                                    SizedBox(height: 48, child: Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()))),
                                  ]),
                                  Expanded(
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 48)),
                                      ),
                                    ),
                                  ),
                                  if (name != null) Padding(padding: const EdgeInsets.all(8.0), child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 2)),
                                  Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(type ?? 'image', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                ]),
                              ),
                            ),
                            transitionBuilder: (ctx, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          );
                        } else {
                          await openUrl(url);
                        }
                      },
                      child: Container(
                        width: 160,
                        color: Colors.grey[200],
                        child: Column(children: [
                          Expanded(child: url != null && (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png')) ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.broken_image)),
                          ) : const Icon(Icons.insert_drive_file, size: 64)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), child: Column(children: [
                            if (name != null) Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                            const SizedBox(height: 2),
                            Text(type ?? 'file', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ])),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ]),
        isActive: _currentStep == 5,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Village Survey (Stepper)')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: null,
        onStepCancel: null,
        onStepTapped: (i) { setState(() => _currentStep = i); },
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: steps,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _processingAction != null ? null : _handleSaveDraft,
                  child: _processingAction == 'draft'
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processingAction != null ? null : _handleSubmit,
                  child: _processingAction == 'submit'
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String title, bool? groupValue, ValueChanged<bool?> onChanged, {String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: errorText != null ? Theme.of(context).colorScheme.error : null,
            )),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes'),
                value: true,
                groupValue: groupValue,
                onChanged: onChanged,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(title: const Text('No'), value: false, groupValue: groupValue, onChanged: onChanged),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Text(errorText, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
