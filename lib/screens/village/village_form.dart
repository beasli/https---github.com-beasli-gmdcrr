import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gmdcrr/core/config/env.dart';
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
  List<Map<String, dynamic>> _remoteMedia = [];

  // Location
  double? _lat, _lng;
  String _status = 'draft'; // Default status

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
        final tryAgain = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location not available'),
            content: const Text('Unable to obtain your location. Please enable location services or try again outdoors.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Retry')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Settings')),
            ],
          ),
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
        // Use nearby village API with stored access token (if available)
        final token = await AuthService().getToken();
  final nearby = await VillageService().fetchNearbyByLatLng(_lat!, _lng!, bearerToken: token);
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
                  _headquartersName.text = d['taluka_headquarters']?.toString() ?? _headquartersName.text;
                  _districtHeadquartersName.text = d['district_headquarters']?.toString() ?? _districtHeadquartersName.text;
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
                  _status = d['status']?.toString() ?? _status;
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
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Village not found'),
              content: const Text('Village not found near you'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
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
  // surveyor removed per request
    'status': _status,
    'villageName': _villageNameCtrl.text,
    'gramPanchayat': _gpCtrl.text, // gram_panchayat_office
    'totalPopulation': int.tryParse(_totalPopulationCtrl.text),
    'totalFamily': int.tryParse(_familiesSocialTotalCtrl.text),
    'agriLand': _agriLandCtrl.text,
    'irrigatedLand': _irrigatedCtrl.text,
    'unirrigatedLand': _unirrigatedCtrl.text,
    'residentialLand': _residentialCtrl.text,
    'waterArea': _waterCtrl.text,
    'stonyArea': _stonyCtrl.text,
    'totalArea': _totalAreaCtrl.text,
    'generalFamilies': int.tryParse(_familiesGeneralCtrl.text),
    'obcFamilies': int.tryParse(_familiesOBCCtrl.text),
    'scFamilies': int.tryParse(_familiesSCCtrl.text),
    'stFamilies': int.tryParse(_familiesSTCtrl.text),
    'farmingFamilies': int.tryParse(_familiesFarmingCtrl.text),
    'farmLabourFamilies': int.tryParse(_familiesLabourCtrl.text),
    'govtJobFamilies': int.tryParse(_familiesGovtCtrl.text),
    'nonGovtJobFamilies': int.tryParse(_familiesNonGovtCtrl.text),
    'businessFamilies': int.tryParse(_familiesBusinessCtrl.text),
    'unemployedFamilies': int.tryParse(_familiesUnemployedCtrl.text),
    'nearestCity': _nearestCity.text,
    'distanceToCity': int.tryParse(_distanceToCity.text),
    'talukaHeadquarters': _headquartersName.text,
    'distanceToHQ': int.tryParse(_distanceToHQ.text),
    'districtHeadquarters': _districtHeadquartersName.text,
    'distanceToDistrictHQ': int.tryParse(_distanceToDistrictHQ.text),
    'busStation': _busStationDetails.text,
    'railwayStation': _railwayStationDetails.text,
    'postOffice': _postOfficeDetails.text,
    'policeStation': _policeStationDetails.text,
    'bank': _bankDetails.text,
    'hasAsphaltRoad': hasAsphaltRoad ?? false,
    'asphaltRoadCount': int.tryParse(_asphaltRoadCount.text),
    'hasRawRoad': hasRawRoad ?? false,
    'rawRoadCount': int.tryParse(_rawRoadCount.text),
    'hasWaterSystem': hasWaterSystem ?? false,
    'waterSystemCount': int.tryParse(_waterSystemCount.text),
    'hasDrainage': hasDrainage ?? false,
    'drainageSystemCount': int.tryParse(_drainageSystemCount.text),
    'hasElectricity': hasElectricity ?? false,
    'electricitySystemCount': int.tryParse(_electricitySystemCount.text),
    'hasWasteDisposal': hasWasteDisposal ?? false,
    'wasteDisposalCount': int.tryParse(_wasteDisposalCount.text),
    'hasWaterStorage': hasWaterStorage ?? false,
    'waterStorageCount': int.tryParse(_waterStorageCount.text),
    'hasPublicWell': hasPublicWell ?? false,
    'publicWellCount': int.tryParse(_publicWellCount.text),
    'hasPublicPond': hasPublicPond ?? false,
    'publicPondCount': int.tryParse(_publicPondCount.text),
    'hasWaterForCattle': hasWaterForCattle ?? false,
    'waterForCattleCount': int.tryParse(_waterForCattleCount.text),
    'hasPrimarySchool': hasPrimarySchool ?? false,
    'primarySchoolCount': int.tryParse(_primarySchoolCount.text),
    'hasSecondarySchool': hasSecondarySchool ?? false,
    'secondarySchoolCount': int.tryParse(_secondarySchoolCount.text),
    'hasHigherSecondary': hasHigherSecondary ?? false,
    'higherSecondarySchoolCount': int.tryParse(_higherSecondaryCount.text),
    'hasCollege': hasCollege ?? false,
    'collegeCount': int.tryParse(_collegeCount.text),
    'hasUniversity': hasUniversity ?? false,
    'universityCount': int.tryParse(_universityCount.text),
    'hasAnganwadi': hasAnganwadi ?? false,
    'anganwadiCount': int.tryParse(_anganwadiCount.text),
    'hasItc': hasItc ?? false,
    'itcCount': int.tryParse(_itcCount.text),
    'hasDispensary': hasDispensary ?? false,
    'dispensaryCount': int.tryParse(_dispensaryCount.text),
    'hasPhc': hasPhc ?? false,
    'phcCount': int.tryParse(_phcCount.text),
    'hasGovHospital': hasGovHospital ?? false,
    'govHospitalCount': int.tryParse(_govHospitalCount.text),
    'hasPrivateHospital': hasPrivateHospital ?? false,
    'privateHospitalCount': int.tryParse(_privateHospitalCount.text),
    'hasDrugStore': hasDrugStore ?? false,
    'drugStoreCount': int.tryParse(_drugStoreCount.text),
    'hasAnimalHospital': hasAnimalHospital ?? false,
    'animalHospitalCount': int.tryParse(_animalHospitalCount.text),
    'hasCommunityHall': hasCommunityHall ?? false,
    'communityHallCount': int.tryParse(_communityHallCount.text),
    'hasFairPriceShop': hasFairPriceShop ?? false,
    'fairPriceShopCount': int.tryParse(_fairPriceShopCount.text),
    'hasGroceryMarket': hasGroceryMarket ?? false,
    'groceryMarketCount': int.tryParse(_groceryMarketCount.text),
    'hasVegetableMarket': hasVegetableMarket ?? false,
    'vegetableMarketCount': int.tryParse(_vegetableMarketCount.text),
    'hasGrindingMill': hasGrindingMill ?? false,
    'grindingMillCount': int.tryParse(_grindingMillCount.text),
    'hasRestaurant': hasRestaurant ?? false,
    'restaurantCount': int.tryParse(_restaurantCount.text),
    'hasPublicTransport': hasPublicTransport ?? false,
    'publicTransportCount': int.tryParse(_publicTransportCount.text),
    'hasCooperative': hasCooperative ?? false,
    'cooperativeCount': int.tryParse(_cooperativeCount.text),
    'hasPublicGarden': hasPublicGarden ?? false,
    'publicGardenCount': int.tryParse(_publicGardenCount.text),
    'hasCinema': hasCinema ?? false,
    'cinemaCount': int.tryParse(_cinemaCount.text),
    'hasColdStorage': hasColdStorage ?? false,
    'coldStorageCount': int.tryParse(_coldStorageCount.text),
    'hasSportsGround': hasSportsGround ?? false,
    'sportsGroundCount': int.tryParse(_sportsGroundCount.text),
    'hasTemple': hasTemple ?? false,
    'templeCount': int.tryParse(_templeCount.text),
    'hasMosque': hasMosque ?? false,
    'mosqueCount': int.tryParse(_mosqueCount.text),
    'hasOtherReligious': hasOtherReligious ?? false,
    'otherReligiousCount': int.tryParse(_otherReligiousCount.text),
    'hasCremation': hasCremation ?? false,
    'cremationCount': int.tryParse(_cremationGroundCount.text),
    'hasCemetery': hasCemetery ?? false,
    'cemeteryCount': int.tryParse(_cemeteryCount.text),
    'photo': _villagePhotoPath,
    'gps': _gpsLocation,
  };

  Future<void> _saveDraft() async {
    if (_draftId == null) return;
    final payload = _collectPayload();
    await LocalDb().updateEntry(_draftId!, {
      'payload': jsonEncode(payload),
      'imagePath': _villagePhotoPath,
      'lat': _lat,
      'lng': _lng,
      'status': 'draft',
      'remoteSurveyId': _remoteSurveyId,
    });
  }

  Future<void> _submit() async {
    // Validate mandatory radio buttons
    if (hasAsphaltRoad == null || hasRawRoad == null || hasWaterSystem == null || hasDrainage == null || hasElectricity == null || hasWasteDisposal == null || hasWaterStorage == null || hasPublicWell == null || hasPublicPond == null || hasWaterForCattle == null || hasPrimarySchool == null || hasSecondarySchool == null || hasHigherSecondary == null || hasCollege == null || hasUniversity == null || hasAnganwadi == null || hasItc == null || hasDispensary == null || hasPhc == null || hasGovHospital == null || hasPrivateHospital == null || hasDrugStore == null || hasAnimalHospital == null || hasCommunityHall == null || hasFairPriceShop == null || hasGroceryMarket == null || hasVegetableMarket == null || hasGrindingMill == null || hasRestaurant == null || hasPublicTransport == null || hasCooperative == null || hasPublicGarden == null || hasCinema == null || hasColdStorage == null || hasSportsGround == null || hasTemple == null || hasMosque == null || hasOtherReligious == null || hasCremation == null || hasCemetery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all mandatory (Yes/No) questions in the Infrastructure section.'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate to the infrastructure step
      setState(() => _currentStep = 4);
      return;
    }

    await _saveDraft();
    if (_draftId == null) return;

    // Attempt immediate remote update if we have a remote survey id
    final token = await AuthService().getToken();
    var uploaded = false;
    if (_remoteSurveyId != null) {
      final payload = _collectPayload();
      try {
        uploaded = await VillageService().updateSurvey(_remoteSurveyId!, payload, _villagePhotoPath, bearerToken: token);
      } catch (_) {
        uploaded = false;
      }
    }

    // Update local DB status according to result
    await LocalDb().updateEntry(_draftId!, {'status': uploaded ? 'uploaded' : 'pending'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploaded ? 'Uploaded successfully' : 'Saved and queued for upload')));
    Navigator.of(context).pop();
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
      await _saveDraft();
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
          TextFormField(controller: _villageNameCtrl, decoration: const InputDecoration(labelText: 'Village name'), readOnly: true),
          TextFormField(controller: _gpCtrl, decoration: const InputDecoration(labelText: 'Gram Panchayat'), readOnly: true),
          TextFormField(controller: _talukaCtrl, decoration: const InputDecoration(labelText: 'Taluka'), readOnly: true),
          TextFormField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District'), readOnly: true),
          TextFormField(controller: _totalPopulationCtrl, decoration: const InputDecoration(labelText: 'Population'), keyboardType: TextInputType.number),
        ]),
        isActive: _currentStep == 0,
      ),
      Step(
        title: const Text('Village Area Details'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // total area removed per request
          TextFormField(controller: _agriLandCtrl, decoration: const InputDecoration(labelText: 'Agricultural Land Area')),
          TextFormField(controller: _irrigatedCtrl, decoration: const InputDecoration(labelText: 'Irrigated Land Area')),
          TextFormField(controller: _unirrigatedCtrl, decoration: const InputDecoration(labelText: 'Unirrigated Land Area')),
          TextFormField(controller: _residentialCtrl, decoration: const InputDecoration(labelText: 'Residential Land Area')),
          TextFormField(controller: _waterCtrl, decoration: const InputDecoration(labelText: 'Area under Water')),
          TextFormField(controller: _stonyCtrl, decoration: const InputDecoration(labelText: 'Stony Soil Area')),
          const SizedBox(height: 8),
          TextFormField(controller: _totalAreaCtrl, decoration: const InputDecoration(labelText: 'Total Area'), readOnly: true),
        ]),
        isActive: _currentStep == 1,
      ),
      Step(
        title: const Text('Family Demographics'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => setState(() => _currentStep = 2), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('3.1. Families by Social Group', style: TextStyle(fontWeight: FontWeight.bold)))),
          // Families by social group
          Row(children: [
            Expanded(child: TextFormField(controller: _familiesGeneralCtrl, decoration: const InputDecoration(labelText: 'General'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _familiesOBCCtrl, decoration: const InputDecoration(labelText: 'OBC'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _familiesSCCtrl, decoration: const InputDecoration(labelText: 'SC'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _familiesSTCtrl, decoration: const InputDecoration(labelText: 'ST'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          TextFormField(controller: _familiesSocialTotalCtrl, decoration: const InputDecoration(labelText: 'Total (social groups)'), readOnly: true),
          const SizedBox(height: 12),
          InkWell(onTap: () => setState(() => _currentStep = 2), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('3.2. Families by Primary Occupation', style: TextStyle(fontWeight: FontWeight.bold)))),
          // Families by primary occupation
          TextFormField(controller: _familiesFarmingCtrl, decoration: const InputDecoration(labelText: 'Farming families'), keyboardType: TextInputType.number),
          TextFormField(controller: _familiesLabourCtrl, decoration: const InputDecoration(labelText: 'Farm labor families'), keyboardType: TextInputType.number),
          TextFormField(controller: _familiesGovtCtrl, decoration: const InputDecoration(labelText: 'Govt/Semi-Govt job families'), keyboardType: TextInputType.number),
          TextFormField(controller: _familiesNonGovtCtrl, decoration: const InputDecoration(labelText: 'Other Non-Govt job families'), keyboardType: TextInputType.number),
          TextFormField(controller: _familiesBusinessCtrl, decoration: const InputDecoration(labelText: 'Private business households'), keyboardType: TextInputType.number),
          TextFormField(controller: _familiesUnemployedCtrl, decoration: const InputDecoration(labelText: 'Unemployed families'), keyboardType: TextInputType.number),
        ]),
        isActive: _currentStep == 2,
      ),
      Step(
        title: const Text('Connectivity'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => setState(() => _currentStep = 3), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('4.1. Connectivity Distance (Detail & Distance in Km)', style: TextStyle(fontWeight: FontWeight.bold)))),
          TextFormField(controller: _nearestCity, decoration: const InputDecoration(labelText: 'Nearest City *', hintText: 'City Name')),
          TextFormField(controller: _distanceToCity, decoration: const InputDecoration(labelText: 'Distance to Nearest City (km) *', hintText: 'e.g., 10'), keyboardType: TextInputType.number),
          TextFormField(controller: _headquartersName, decoration: const InputDecoration(labelText: 'Taluka Headquarters *', hintText: 'Headquarters Name')),
          TextFormField(controller: _distanceToHQ, decoration: const InputDecoration(labelText: 'Distance to Taluka Headquarters (km) *', hintText: 'e.g., 25'), keyboardType: TextInputType.number),
          TextFormField(controller: _districtHeadquartersName, decoration: const InputDecoration(labelText: 'District Headquarters *', hintText: 'Headquarters Name')),
          TextFormField(controller: _distanceToDistrictHQ, decoration: const InputDecoration(labelText: 'Distance to District Headquarters (km) *', hintText: 'e.g., 50'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          InkWell(onTap: () => setState(() => _currentStep = 3), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('4.2. Facilities (Detail & Distance)', style: TextStyle(fontWeight: FontWeight.bold)))),
          TextFormField(controller: _busStationDetails, decoration: const InputDecoration(labelText: 'Bus Station Details *', hintText: 'e.g., Central Bus Stand, 2 km away')),
          TextFormField(controller: _railwayStationDetails, decoration: const InputDecoration(labelText: 'Railway Station Details *', hintText: 'e.g., City Railway Station, 15 km away')),
          TextFormField(controller: _postOfficeDetails, decoration: const InputDecoration(labelText: 'Post Office Details *', hintText: 'e.g., Main Post Office, 1 km away')),
          TextFormField(controller: _policeStationDetails, decoration: const InputDecoration(labelText: 'Police Station Details *', hintText: 'e.g., Taluka Police Station, 8 km away')),
          TextFormField(controller: _bankDetails, decoration: const InputDecoration(labelText: 'Bank Details *', hintText: 'e.g., State Bank, 5 km away')),
        ]),
        isActive: _currentStep == 3,
      ),
      Step(
        title: const Text('Infrastructure & Utilities'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 5.1 Roads, Water & Utilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.1. Roads, Water & Utilities (Enter length/coverage if Yes)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Approach Asphalt Road *', hasAsphaltRoad, (val) => setState(() => hasAsphaltRoad = val)),
          if (hasAsphaltRoad == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _asphaltRoadCount, decoration: const InputDecoration(labelText: 'Approach Asphalt Road (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Approach Raw Road *', hasRawRoad, (val) => setState(() => hasRawRoad = val)),
          if (hasRawRoad == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _rawRoadCount, decoration: const InputDecoration(labelText: 'Approach Raw Road (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Water system available *', hasWaterSystem, (val) => setState(() => hasWaterSystem = val)),
          if (hasWaterSystem == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterSystemCount, decoration: const InputDecoration(labelText: 'Water system (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Drainage system available *', hasDrainage, (val) => setState(() => hasDrainage = val)),
          if (hasDrainage == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _drainageSystemCount, decoration: const InputDecoration(labelText: 'Drainage system (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Electricity system available *', hasElectricity, (val) => setState(() => hasElectricity = val)),
          if (hasElectricity == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _electricitySystemCount, decoration: const InputDecoration(labelText: 'Electricity system (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Public system for waste disposal *', hasWasteDisposal, (val) => setState(() => hasWasteDisposal = val)),
          if (hasWasteDisposal == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _wasteDisposalCount, decoration: const InputDecoration(labelText: 'Public system for waste disposal (Detail/Count)', hintText: 'Enter Detail/Count if available'), keyboardType: TextInputType.number),
            ),

          const SizedBox(height: 12),
          // 5.2 Public Water Sources
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.2. Public Water Sources (Enter count if available)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Water Storage Arrangement *', hasWaterStorage, (val) => setState(() => hasWaterStorage = val)),
          if (hasWaterStorage == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterStorageCount, decoration: const InputDecoration(labelText: 'Water Storage Arrangement (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Public Well *', hasPublicWell, (val) => setState(() => hasPublicWell = val)),
          if (hasPublicWell == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _publicWellCount, decoration: const InputDecoration(labelText: 'Public Well (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Public Pond *', hasPublicPond, (val) => setState(() => hasPublicPond = val)),
          if (hasPublicPond == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _publicPondCount, decoration: const InputDecoration(labelText: 'Public Pond (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Water for Cattle *', hasWaterForCattle, (val) => setState(() => hasWaterForCattle = val)),
          if (hasWaterForCattle == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _waterForCattleCount, decoration: const InputDecoration(labelText: 'Water for Cattle (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),

          const SizedBox(height: 12),
          // 5.3 Education Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.3. Education Facilities (Enter count if available)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Primary school *', hasPrimarySchool, (val) => setState(() => hasPrimarySchool = val)),
          if (hasPrimarySchool == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _primarySchoolCount, decoration: const InputDecoration(labelText: 'Primary school (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Secondary school *', hasSecondarySchool, (val) => setState(() => hasSecondarySchool = val)),
          if (hasSecondarySchool == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _secondarySchoolCount, decoration: const InputDecoration(labelText: 'Secondary school (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Higher Secondary School *', hasHigherSecondary, (val) => setState(() => hasHigherSecondary = val)),
          if (hasHigherSecondary == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _higherSecondaryCount, decoration: const InputDecoration(labelText: 'Higher Secondary School (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('College *', hasCollege, (val) => setState(() => hasCollege = val)),
          if (hasCollege == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _collegeCount, decoration: const InputDecoration(labelText: 'College (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('University *', hasUniversity, (val) => setState(() => hasUniversity = val)),
          if (hasUniversity == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _universityCount, decoration: const InputDecoration(labelText: 'University (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Anganwadi *', hasAnganwadi, (val) => setState(() => hasAnganwadi = val)),
          if (hasAnganwadi == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _anganwadiCount, decoration: const InputDecoration(labelText: 'Anganwadi (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Industrial Training Centre *', hasItc, (val) => setState(() => hasItc = val)),
          if (hasItc == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _itcCount, decoration: const InputDecoration(labelText: 'Industrial Training Centre (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),

          const SizedBox(height: 12),
          // 5.4 Health Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.4. Health Facilities (Enter count if available)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Dispensary *', hasDispensary, (val) => setState(() => hasDispensary = val)),
          if (hasDispensary == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _dispensaryCount, decoration: const InputDecoration(labelText: 'Dispensary (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Primary Health Centre *', hasPhc, (val) => setState(() => hasPhc = val)),
          if (hasPhc == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _phcCount, decoration: const InputDecoration(labelText: 'Primary Health Centre (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Government Hospital *', hasGovHospital, (val) => setState(() => hasGovHospital = val)),
          if (hasGovHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _govHospitalCount, decoration: const InputDecoration(labelText: 'Government Hospital (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Private hospital *', hasPrivateHospital, (val) => setState(() => hasPrivateHospital = val)),
          if (hasPrivateHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _privateHospitalCount, decoration: const InputDecoration(labelText: 'Private hospital (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Drug store *', hasDrugStore, (val) => setState(() => hasDrugStore = val)),
          if (hasDrugStore == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _drugStoreCount, decoration: const InputDecoration(labelText: 'Drug store (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Animal Hospital *', hasAnimalHospital, (val) => setState(() => hasAnimalHospital = val)),
          if (hasAnimalHospital == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _animalHospitalCount, decoration: const InputDecoration(labelText: 'Animal Hospital (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),

          const SizedBox(height: 12),
          // 5.5 Markets, Community & Services
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.5. Markets, Community & Services (Enter count if available)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Community Hall *', hasCommunityHall, (val) => setState(() => hasCommunityHall = val)),
          if (hasCommunityHall == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _communityHallCount, decoration: const InputDecoration(labelText: 'Community Hall (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Fair price shop *', hasFairPriceShop, (val) => setState(() => hasFairPriceShop = val)),
          if (hasFairPriceShop == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _fairPriceShopCount, decoration: const InputDecoration(labelText: 'Fair price shop (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Grocery market *', hasGroceryMarket, (val) => setState(() => hasGroceryMarket = val)),
          if (hasGroceryMarket == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _groceryMarketCount, decoration: const InputDecoration(labelText: 'Grocery market (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Vegetable market *', hasVegetableMarket, (val) => setState(() => hasVegetableMarket = val)),
          if (hasVegetableMarket == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _vegetableMarketCount, decoration: const InputDecoration(labelText: 'Vegetable market (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Grain grinding mill *', hasGrindingMill, (val) => setState(() => hasGrindingMill = val)),
          if (hasGrindingMill == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _grindingMillCount, decoration: const InputDecoration(labelText: 'Grain grinding mill (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Restaurant/Hotel *', hasRestaurant, (val) => setState(() => hasRestaurant = val)),
          if (hasRestaurant == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _restaurantCount, decoration: const InputDecoration(labelText: 'Restaurant/Hotel (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Public Transport System *', hasPublicTransport, (val) => setState(() => hasPublicTransport = val)),
          if (hasPublicTransport == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _publicTransportCount, decoration: const InputDecoration(labelText: 'Public Transport System (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Cooperative Organization *', hasCooperative, (val) => setState(() => hasCooperative = val)),
          if (hasCooperative == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _cooperativeCount, decoration: const InputDecoration(labelText: 'Cooperative Organization (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Public Garden/Park *', hasPublicGarden, (val) => setState(() => hasPublicGarden = val)),
          if (hasPublicGarden == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _publicGardenCount, decoration: const InputDecoration(labelText: 'Public Garden/Park (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Cinema/Theatre *', hasCinema, (val) => setState(() => hasCinema = val)),
          if (hasCinema == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _cinemaCount, decoration: const InputDecoration(labelText: 'Cinema/Theatre (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Cold Storage *', hasColdStorage, (val) => setState(() => hasColdStorage = val)),
          if (hasColdStorage == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _coldStorageCount, decoration: const InputDecoration(labelText: 'Cold Storage (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),
          _buildRadioGroup('Sports Ground *', hasSportsGround, (val) => setState(() => hasSportsGround = val)),
          if (hasSportsGround == true)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextFormField(controller: _sportsGroundCount, decoration: const InputDecoration(labelText: 'Sports Ground (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number)),

          const SizedBox(height: 12),
          // 5.6 Religious/Mortality Facilities
          InkWell(onTap: () => setState(() => _currentStep = 4), child: const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('5.6. Religious/Mortality Facilities (Enter count if available)', style: TextStyle(fontWeight: FontWeight.bold)))),
          _buildRadioGroup('Temple *', hasTemple, (val) => setState(() => hasTemple = val)),
          if (hasTemple == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _templeCount, decoration: const InputDecoration(labelText: 'Temple (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Mosque *', hasMosque, (val) => setState(() => hasMosque = val)),
          if (hasMosque == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _mosqueCount, decoration: const InputDecoration(labelText: 'Mosque (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Other Religious Place *', hasOtherReligious, (val) => setState(() => hasOtherReligious = val)),
          if (hasOtherReligious == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _otherReligiousCount, decoration: const InputDecoration(labelText: 'Other Religious Place (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Cremation Ground *', hasCremation, (val) => setState(() => hasCremation = val)),
          if (hasCremation == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _cremationGroundCount, decoration: const InputDecoration(labelText: 'Cremation Ground (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
          _buildRadioGroup('Cemetery *', hasCemetery, (val) => setState(() => hasCemetery = val)),
          if (hasCemetery == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(controller: _cemeteryCount, decoration: const InputDecoration(labelText: 'Cemetery (count)', hintText: 'Enter count if available'), keyboardType: TextInputType.number),
            ),
        ]),
        isActive: _currentStep == 4,
      ),
      Step(
        title: const Text('Attachments & GPS'),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => Dialog(
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
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['draft', 'completed'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value[0].toUpperCase() + value.substring(1)),
              );
            }).toList(),
            onChanged: (String? newValue) => setState(() => _status = newValue ?? 'draft'),
          ),
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
          child: ElevatedButton(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String title, bool? groupValue, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
      ],
    );
  }
}
