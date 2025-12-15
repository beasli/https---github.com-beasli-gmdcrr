import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import './family_survey_service.dart';
import '../village/camera_capture.dart';
import '../../core/services/village_service.dart';
import '../../core/config/api.dart';
import '../../core/services/local_db.dart';
import 'package:signature/signature.dart';
import '../../core/config/env.dart';

/// Data model for a single family member.
class FamilyMember {
  // Using unique keys for each member's form to handle state correctly in a list.
  final UniqueKey key = UniqueKey();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController relationshipCtrl = TextEditingController();
  String? gender;
  TextEditingController ageCtrl = TextEditingController();
  String? caste;
  String? studying;
  TextEditingController educationCtrl = TextEditingController();
  String? maritalStatus;
  TextEditingController religionCtrl = TextEditingController();
  TextEditingController bplCardCtrl = TextEditingController();
  TextEditingController aadharCtrl = TextEditingController();
  TextEditingController mobileCtrl = TextEditingController();
  TextEditingController artisanSkillCtrl = TextEditingController();
  String? skillTrainingInterest;
  String? handicapped;
  String? photoUrl; // Changed from photoPath to store remote URL
}

/// Data model for a single tree record.
class TreeRecord {
  final UniqueKey key = UniqueKey();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController countCtrl = TextEditingController();
  TextEditingController ageCtrl = TextEditingController();
  String? photoUrl;
}

/// Data model for a single land record.
class LandRecord {
  final UniqueKey key = UniqueKey();
  TextEditingController khataNoCtrl = TextEditingController();
  String? landType;
  TextEditingController totalAreaCtrl = TextEditingController();
  TextEditingController acquiredAreaCtrl = TextEditingController();
  TextEditingController remainingAreaCtrl = TextEditingController();
  String? hasDocumentaryEvidence;
  String? isLandMortgaged;
  TextEditingController landMortgagedToCtrl = TextEditingController();
  TextEditingController landMortgagedDetailsCtrl = TextEditingController();
}

/// Data model for a single asset record.
class AssetRecord {
  final UniqueKey key = UniqueKey();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController countCtrl = TextEditingController();
  String? photoUrl;
}

/// Data model for a single livestock record.
class LivestockRecord {
  final UniqueKey key = UniqueKey();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController countCtrl = TextEditingController();
  String? cattlePaddyType;
  String? photoUrl;
}


class FamilySurveyFormPage extends StatefulWidget {
  final int? familySurveyId;
  const FamilySurveyFormPage({super.key, this.familySurveyId});

  @override
  State<FamilySurveyFormPage> createState() => _FamilySurveyFormPageState();
}

class _FamilySurveyFormPageState extends State<FamilySurveyFormPage> {
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isUploading = false;
  bool _isLoadingSurvey = false;
  int? _localDbId; // Unique ID for the local draft instance

  final LocalDb _localDb = LocalDb();
  final FamilySurveyService _surveyService = FamilySurveyService();
  final VillageService _villageService = VillageService();

  // Form Keys for each step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();
  final _step5Key = GlobalKey<FormState>();

  // Step 1: Identity & Family
  // Head of Family has some unique fields
  final _familyNoCtrl = TextEditingController(text: 'Auto-generated');
  final _villageNameCtrl = TextEditingController();
  final _laneCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  int? _villageId;

  // Head of the family is the first member in our list.
  // Additional members will be added here.
  final List<FamilyMember> _familyMembers = [FamilyMember()];
  
  // Step 2: Residence & Amenities Controllers
  final _residenceAgeCtrl = TextEditingController();
  String? _residenceAuthorized;
  String? _residenceOwnerTenant;
  final _residenceTotalRoomsCtrl = TextEditingController();
  String? _residencePakkaKachha;
  String? _residenceRoofType;
  final _residencePlotAreaCtrl = TextEditingController();
  final _residenceConstructionAreaCtrl = TextEditingController();
  String? _residenceRrColonyInterest;
  String? _residenceLiveOwnLifeInterest;
  String? _residenceWellBorewell;
  String? _residenceToiletFacilities;
  String? _residenceCesspool;
  String? _residenceDrainageFacility;
  String? _residenceWaterTap;
  String? _residenceElectricity;
  String? _residenceFuelFacility;
  String? _residenceSolarEnergy;
  String? _residenceDocumentaryEvidence;
  String? _housePhotoUrl;

  // Step 3: Land & Tree Assets Controllers
  String? _landHolds;
  final List<LandRecord> _landRecords = [];
  final List<TreeRecord> _treeRecords = [];
  
  // Step 4: Income & Other Assets Controllers
  // Annual Income
  final _incomeFarmingCtrl = TextEditingController();
  final _incomeJobCtrl = TextEditingController();
  final _incomeBusinessCtrl = TextEditingController();
  final _incomeLaborCtrl = TextEditingController();
  final _incomeHouseworkCtrl = TextEditingController();
  final _incomeOtherCtrl = TextEditingController();
  final _estimatedAnnualIncomeCtrl = TextEditingController(); // read-only

  // Other Assets
  final List<AssetRecord> _assetRecords = [];
  // Livestock
  final List<LivestockRecord> _livestockRecords = [];

  // Step 5: Finance & Documents Controllers
  // Annual Expenses
  final _expenseAgricultureCtrl = TextEditingController();
  final _expenseHouseCtrl = TextEditingController();
  final _expenseFoodCtrl = TextEditingController();
  final _expenseFuelCtrl = TextEditingController();
  final _expenseElectricityCtrl = TextEditingController();
  final _expenseClothsCtrl = TextEditingController();
  final _expenseHealthCtrl = TextEditingController();
  final _expenseEducationCtrl = TextEditingController();
  final _expenseTransportationCtrl = TextEditingController();
  final _expenseCommunicationCtrl = TextEditingController();
  final _expenseCinemaHotelCtrl = TextEditingController();
  final _expenseTaxesCtrl = TextEditingController();
  final _expenseOthersCtrl = TextEditingController();

  // Loans and Debts
  String? _loanTaken;
  final _loanAmountCtrl = TextEditingController();
  final _loanTenureYearsCtrl = TextEditingController();
  final _loanObtainedFromCtrl = TextEditingController();
  final _loanPurposeCtrl = TextEditingController();

  // Final Verification
  String? _finalGpsLocation;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // A helper function for simple validation
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateAadhar(String? value) {
    String? required = _validateRequired(value);
    if (required != null) {
      return required;
    }
    if (value!.length != 12) {
      return 'Aadhar must be 12 digits';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    String? required = _validateRequired(value);
    if (required != null) {
      return required;
    }
    if (value!.length != 10) {
      return 'Mobile must be 10 digits';
    }
    return null;
  }

  Timer? _debounce;
  bool _isInitialDataLoaded = false;
  @override
  void initState() {
    super.initState();
    // Add listeners for income calculation
    _incomeFarmingCtrl.addListener(_calculateTotalIncome);
    _incomeJobCtrl.addListener(_calculateTotalIncome);
    _incomeBusinessCtrl.addListener(_calculateTotalIncome);
    _incomeLaborCtrl.addListener(_calculateTotalIncome);
    _incomeHouseworkCtrl.addListener(_calculateTotalIncome);
    _incomeOtherCtrl.addListener(_calculateTotalIncome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialDataLoaded) return;

    final initialData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Load initial survey data or capture GPS for a new survey.
    if (initialData != null) { // Editing a local draft, data is passed directly
      // The local ID is passed via widget.familySurveyId from the list page.
      // The server ID inside the payload might be null for new drafts.
      _localDbId = widget.familySurveyId;
      if (_localDbId != null) {
        _loadSurveyForEditing(_localDbId!, initialData: initialData);
      }
    } else if (widget.familySurveyId != null) { // Editing a server survey
      _localDbId = widget.familySurveyId;
      _loadSurveyForEditing(widget.familySurveyId!, initialData: initialData);
    } else {
      // This is a new survey. Create a unique temporary ID for local drafts.
      _localDbId = -DateTime.now().millisecondsSinceEpoch;
      _captureGpsLocation();
    }
    _isInitialDataLoaded = true;
  }

  void _calculateTotalIncome() {
    final total = (double.tryParse(_incomeFarmingCtrl.text) ?? 0) + (double.tryParse(_incomeJobCtrl.text) ?? 0) + (double.tryParse(_incomeBusinessCtrl.text) ?? 0) + (double.tryParse(_incomeLaborCtrl.text) ?? 0) + (double.tryParse(_incomeHouseworkCtrl.text) ?? 0) + (double.tryParse(_incomeOtherCtrl.text) ?? 0);
    _estimatedAnnualIncomeCtrl.text = total.toStringAsFixed(2);
  }

  /// Debounces the local save operation to avoid excessive DB writes.
  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _saveLocally();
    });
  }

  /// Gathers form data and saves it to the local SQLite database.
  Future<void> _saveLocally() async {
    // Don't save locally if we are still loading or processing.
    if (_isLoadingSurvey || _isProcessing) return;

    // Gather data without uploading signature (it's a draft).
    final surveyData = await _gatherSurveyData('draft', forLocalSave: true);
    if (surveyData != null) {
      final row = {
        'id': _localDbId, // Use the stable local ID
        'payload': jsonEncode(surveyData),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      print ('Saving survey locally with ID $_localDbId');
      await _localDb.insertOrUpdateFamilySurvey(row);
    }
  }


  @override
  void dispose() {
    // Dispose head-of-family specific controllers
    _familyNoCtrl.dispose();
    _villageNameCtrl.dispose();
    _laneCtrl.dispose();
    _debounce?.cancel();
    _houseNoCtrl.dispose();

    // Dispose controllers for all family members
    for (var member in _familyMembers) {
      _disposeMemberControllers(member);
    }
    _residenceAgeCtrl.dispose();
    _residenceTotalRoomsCtrl.dispose();
    _residencePlotAreaCtrl.dispose();
    _residenceConstructionAreaCtrl.dispose();

    // Dispose Step 3 controllers
    for (var land in _landRecords) {
      _disposeLandRecordControllers(land);
    }
    for (var tree in _treeRecords) {
      _disposeTreeRecordControllers(tree);
    }
    // Dispose Step 4 controllers
    _incomeFarmingCtrl.dispose();
    _incomeJobCtrl.dispose();
    _incomeBusinessCtrl.dispose();
    _incomeLaborCtrl.dispose();
    _incomeHouseworkCtrl.dispose();
    _incomeOtherCtrl.dispose();
    _incomeFarmingCtrl.removeListener(_calculateTotalIncome);
    _incomeJobCtrl.removeListener(_calculateTotalIncome);
    _incomeBusinessCtrl.removeListener(_calculateTotalIncome);
    _incomeLaborCtrl.removeListener(_calculateTotalIncome);
    _incomeHouseworkCtrl.removeListener(_calculateTotalIncome);
    _incomeOtherCtrl.removeListener(_calculateTotalIncome);
    _estimatedAnnualIncomeCtrl.dispose();
    for (var asset in _assetRecords) {
      _disposeAssetRecordControllers(asset);
    }
    for (var livestock in _livestockRecords) {
      _disposeLivestockRecordControllers(livestock);
    }
    // Dispose Step 5 controllers
    _expenseAgricultureCtrl.dispose();
    _expenseHouseCtrl.dispose();
    _expenseFoodCtrl.dispose();
    _expenseFuelCtrl.dispose();
    _expenseElectricityCtrl.dispose();
    _expenseClothsCtrl.dispose();
    _expenseHealthCtrl.dispose();
    _expenseEducationCtrl.dispose();
    _expenseTransportationCtrl.dispose();
    _expenseCommunicationCtrl.dispose();
    _expenseCinemaHotelCtrl.dispose();
    _expenseTaxesCtrl.dispose();
    _expenseOthersCtrl.dispose();
    _loanAmountCtrl.dispose();
    _loanTenureYearsCtrl.dispose();
    _loanObtainedFromCtrl.dispose();
    _loanPurposeCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _disposeMemberControllers(FamilyMember member) {
    // photoUrl is just a string, no controller
    member.nameCtrl.dispose();
    member.relationshipCtrl.dispose();
    member.ageCtrl.dispose();
    member.educationCtrl.dispose();
    member.religionCtrl.dispose();
    member.bplCardCtrl.dispose();
    member.aadharCtrl.dispose();
    member.mobileCtrl.dispose();
    member.artisanSkillCtrl.dispose();
  }


  void _addFamilyMember() {
    setState(() {
      _familyMembers.add(FamilyMember());
      _onFieldChanged();
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _disposeMemberControllers(_familyMembers[index]);
      _familyMembers.removeAt(index);
      _onFieldChanged();
    });
  }

  void _disposeLandRecordControllers(LandRecord land) {
    land.khataNoCtrl.dispose();
    land.totalAreaCtrl.dispose();
    land.acquiredAreaCtrl.dispose();
    land.remainingAreaCtrl.dispose();
    land.landMortgagedToCtrl.dispose();
    land.landMortgagedDetailsCtrl.dispose();
  }

  void _addLandRecord() {
    setState(() {
      _landRecords.add(LandRecord());
      _onFieldChanged();
    });
  }

  void _removeLandRecord(int index) {
    setState(() {
      _disposeLandRecordControllers(_landRecords[index]);
      _landRecords.removeAt(index);
      _onFieldChanged();
    });
  }

  void _disposeAssetRecordControllers(AssetRecord asset) {
    asset.nameCtrl.dispose();
    asset.countCtrl.dispose();
  }

  void _addAssetRecord() {
    setState(() {
      _assetRecords.add(AssetRecord());
      _onFieldChanged();
    });
  }

  void _removeAssetRecord(int index) {
    setState(() {
      _disposeAssetRecordControllers(_assetRecords[index]);
      _assetRecords.removeAt(index);
      _onFieldChanged();
    });
  }

  void _disposeLivestockRecordControllers(LivestockRecord livestock) {
    livestock.nameCtrl.dispose();
    livestock.countCtrl.dispose();
  }

  void _addLivestockRecord() {
    setState(() {
      _livestockRecords.add(LivestockRecord());
      _onFieldChanged();
    });
  }

  void _disposeTreeRecordControllers(TreeRecord tree) {
    tree.nameCtrl.dispose();
    tree.countCtrl.dispose();
    tree.ageCtrl.dispose();
  }

  void _addTreeRecord() {
    setState(() {
      _treeRecords.add(TreeRecord());
      _onFieldChanged();
    });
  }

  void _removeTreeRecord(int index) {
    setState(() {
      _disposeTreeRecordControllers(_treeRecords[index]);
      _treeRecords.removeAt(index);
      _onFieldChanged();
    });
  }

  void _removeLivestockRecord(int index) {
    setState(() {
      _disposeLivestockRecordControllers(_livestockRecords[index]);
      _livestockRecords.removeAt(index);
      _onFieldChanged();
    });
  }

  /// Generic photo capture and upload logic.
  /// [onUploadComplete] is a callback that receives the remote URL.
  Future<void> _captureAndUploadPhoto(Function(String) onUploadComplete) async {
    if (_isUploading) return;

    // Navigate to the custom camera capture page
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );

    // User may have cancelled
    if (result == null || result['path'] == null || result['bytes'] == null) return;

    final String photoPath = result['path'];
    final Uint8List photoBytes = result['bytes'];

    setState(() => _isUploading = true);

    // Show a snackbar to indicate upload is in progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo...'), duration: Duration(minutes: 2)), // Long duration
    );

    final remoteUrl = await _surveyService.uploadDocument(photoBytes, photoPath);

    // Hide the uploading snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() => _isUploading = false);

    if (remoteUrl != null) {
      onUploadComplete(remoteUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _captureGpsLocation() async {
    if (!mounted) return;

    double lat, lon;

    // For staging/dev, use a fixed location to simplify testing
    if (AppConfig.currentEnvironment != Environment.production) {
      lat = 21.6701;
      lon = 72.2319;
    } else {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          return;
        }
      }

      try {
        final position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        lon = position.longitude;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get location.')));
        return;
      }
    }

    setState(() {
      _finalGpsLocation = '$lat, $lon';
    });

    if (!mounted) return;

    // Now, fetch the nearby village using the obtained coordinates
    final villageData = await _villageService.fetchNearbyByLatLng(lat, lon);
    if (mounted && villageData != null && villageData['data'] != null) {
      setState(() {
        _villageId = villageData['data']['village']['id'];
        _villageNameCtrl.text = villageData['data']['village']['name'] ?? 'N/A';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Village found: ${_villageNameCtrl.text}'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a nearby village.'), backgroundColor: Colors.orange),
      );
    } else {
      // The widget was disposed during the async operation.
    }
  }

  /// Fetches survey data by ID and populates the form for editing.
  Future<void> _loadSurveyForEditing(int surveyId, {Map<String, dynamic>? initialData}) async {
    setState(() => _isLoadingSurvey = true);

    Map<String, dynamic>? surveyData = initialData;

    // If initialData is not provided (e.g., opening from a notification), fetch from server.
    if (surveyData == null) {
      surveyData = await _surveyService.fetchSurveyById(surveyId);
    }

    if (!mounted) return;

    if (surveyData != null) {
      _populateForm(surveyData);
      // Only show snackbar if it wasn't a local draft load
      if (initialData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey data loaded for editing.'), backgroundColor: Colors.green),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load survey data.'), backgroundColor: Colors.red),
      );
      // Pop the screen if data loading fails, as editing is not possible.
      Navigator.of(context).pop();
    }

    setState(() => _isLoadingSurvey = false);
  }

  /// Populates all form fields from a map of survey data.
  void _populateForm(Map<String, dynamic> data) {
    setState(() {
      // Step 1: Family Info
      // If we are loading a local draft, the data is already in the correct format.
      // If we are loading from the server, it's nested under 'family_survey'.
      final surveyRoot = data.containsKey('family') ? data : data['family_survey'];
      if (surveyRoot == null) return;

      // When loading from local DB, the payload is the root.
      // When loading from server, it's nested.
      final family = surveyRoot['family'] as Map<String, dynamic>?;

      if (family != null) {
        // If an ID exists (from server or local draft), display it.
        if (family['id'] != null) {
          _familyNoCtrl.text = family['id'].toString();
        }
        _villageId = family['village_id'] as int?;
        _villageNameCtrl.text = family['village']?['name']?.toString() ?? '';
        _laneCtrl.text = family['lane']?.toString() ?? '';
        _houseNoCtrl.text = family['house_no']?.toString() ?? '';
        if (family['lat'] != null && family['lon'] != null) {
          _finalGpsLocation = '${family['lat']}, ${family['lon']}';
        }
      }

      // Step 1: Family Members
      final members = surveyRoot['members'] as List<dynamic>?;
      if (members != null && members.isNotEmpty) {
        _familyMembers.clear(); // Clear the initial empty member
        for (var memberData in members) {
          final member = FamilyMember();
          member.nameCtrl.text = memberData['name']?.toString() ?? '';
          member.relationshipCtrl.text = memberData['relationship_with_head']?.toString() ?? '';
          // Map API gender ('Male'/'Female') to form value ('M'/'F')
          final apiGender = memberData['gender']?.toString();
          if (apiGender != null) {
            if (apiGender.toLowerCase() == 'male') member.gender = 'M';
            if (apiGender.toLowerCase() == 'female') member.gender = 'F';
          }
          member.ageCtrl.text = memberData['age']?.toString() ?? '';
          member.maritalStatus = memberData['marital_status']?.toString();
          member.religionCtrl.text = memberData['religion']?.toString() ?? '';
          member.caste = memberData['caste_category']?.toString();
          member.handicapped = (memberData['is_handicapped'] == true) ? 'Yes' : 'No';
          member.aadharCtrl.text = memberData['aadhar_no']?.toString() ?? '';
          member.mobileCtrl.text = memberData['mobile_no']?.toString() ?? '';
          member.educationCtrl.text = memberData['education_qualification']?.toString() ?? '';
          member.studying = (memberData['studying_in_progress'] == true) ? 'Yes' : 'No';
          member.artisanSkillCtrl.text = memberData['artisan_details']?.toString() ?? '';
          member.skillTrainingInterest = (memberData['interested_in_training'] == true) ? 'Yes' : 'No';
          member.photoUrl = memberData['photo_url'] as String?;
          member.bplCardCtrl.text = memberData['bpl_card_no']?.toString() ?? '';
          _familyMembers.add(member);
        }
      }

      // Step 2: Accommodation
      final accommodation = surveyRoot['accommodation'] as Map<String, dynamic>?;
      if (accommodation != null) {
        _residenceAgeCtrl.text = accommodation['residence_years']?.toString() ?? '';
        _residenceAuthorized = (accommodation['is_authorized'] == true) ? 'Yes' : 'No';
        _residenceOwnerTenant = accommodation['ownership']?.toString();
        _residenceTotalRoomsCtrl.text = accommodation['total_rooms']?.toString() ?? '';
        _residencePakkaKachha = accommodation['house_type']?.toString();
        _residenceRoofType = accommodation['roof_type']?.toString();
        _residencePlotAreaCtrl.text = accommodation['land_area']?.toString() ?? '';
        _residenceConstructionAreaCtrl.text = accommodation['total_construction_area']?.toString() ?? '';
        _residenceRrColonyInterest = (accommodation['interested_in_rr_colony'] == true) ? 'Yes' : 'No';
        _residenceLiveOwnLifeInterest = (accommodation['interested_in_own_life'] == true) ? 'Yes' : 'No';
        _residenceWellBorewell = (accommodation['has_well_or_borewell'] == true) ? 'Yes' : 'No';
        _residenceToiletFacilities = (accommodation['has_toilet_facility'] == true) ? 'Yes' : 'No';
        _residenceCesspool = (accommodation['has_cesspool'] == true) ? 'Yes' : 'No';
        _residenceDrainageFacility = accommodation['drainage_facility']?.toString();
        _residenceWaterTap = (accommodation['has_water_tap_facility'] == true) ? 'Yes' : 'No';
        _residenceElectricity = (accommodation['has_electricity_facility'] == true) ? 'Yes' : 'No';
        _residenceFuelFacility = accommodation['fuel_facility']?.toString();
        _residenceSolarEnergy = (accommodation['has_solar_energy_facility'] == true) ? 'Yes' : 'No';
        _residenceDocumentaryEvidence = (accommodation['has_documentary_evidence'] == true) ? 'Yes' : 'No';
        _housePhotoUrl = accommodation['photo_house_url'] as String?;
      }

      // Step 3: Land & Trees
      _landHolds = (surveyRoot['holds_land'] == true) ? 'Yes' : 'No';
      final lands = surveyRoot['lands'] as List<dynamic>?;
      if (lands != null) {
        _landRecords.clear();
        for (var landData in lands) {
          final record = LandRecord();
          record.khataNoCtrl.text = landData['khata_no']?.toString() ?? '';
          record.landType = landData['land_type']?.toString();
          record.totalAreaCtrl.text = landData['total_area']?.toString() ?? '';
          record.acquiredAreaCtrl.text = landData['acquired_area']?.toString() ?? '';
          record.remainingAreaCtrl.text = landData['remaining_area']?.toString() ?? '';
          record.hasDocumentaryEvidence = (landData['has_documentary_evidence'] == true) ? 'Yes' : 'No';
          record.isLandMortgaged = (landData['is_land_mortgaged'] == true) ? 'Yes' : 'No';
          record.landMortgagedToCtrl.text = landData['land_mortgaged_to']?.toString() ?? '';
          record.landMortgagedDetailsCtrl.text = landData['land_mortgaged_details']?.toString() ?? '';
          _landRecords.add(record);
        }
      }

      final trees = surveyRoot['trees'] as List<dynamic>?;
      if (trees != null) {
        _treeRecords.clear();
        for (var treeData in trees) {
          final record = TreeRecord();
          record.nameCtrl.text = treeData['name']?.toString() ?? '';
          record.countCtrl.text = treeData['number_of_trees']?.toString() ?? '';
          record.ageCtrl.text = treeData['age_of_tree']?.toString() ?? '';
          record.photoUrl = treeData['tree_photo'] as String?;
          _treeRecords.add(record);
        }
      }

      // TODO: Populate other steps (Income, Assets, Livestock, Expenses, Loans) in a similar fashion.
      // This part is left as an exercise but follows the same pattern as above.
    });
  }

  void _onStepContinue() {
    bool isStepValid = false;
    switch (_currentStep) {
      case 0:
        isStepValid = _step1Key.currentState?.validate() ?? false;
        break;
      case 1:
        isStepValid = _step2Key.currentState?.validate() ?? false;
        break;
      case 2:
        isStepValid = _step3Key.currentState?.validate() ?? false;
        break;
      case 3:
        isStepValid = _step4Key.currentState?.validate() ?? false;
        break;
      case 4:
        isStepValid = _step5Key.currentState?.validate() ?? false;
        break;
      case 5: // Review step
        isStepValid = true;
        break;
    }

    if (isStepValid) {
        if (_currentStep < _getSteps().length - 1) {
            setState(() {
                _currentStep++;
            });
        } else {
            // This case is now handled by the bottom navigation bar's submit button directly.
        }
    }
  }
  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Gathers all data from the form controllers and state into a JSON-compatible map.
  Future<Map<String, dynamic>?> _gatherSurveyData(String status, {bool forLocalSave = false}) async {
    // 1. Upload signature and get URL
    String? signatureUrl;
    if (_signatureController.isNotEmpty && !forLocalSave) {
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null) {
        // Create a unique filename for the signature
        final signaturePath = 'signatures/sig_${DateTime.now().millisecondsSinceEpoch}.png';
        signatureUrl = await _surveyService.uploadDocument(signatureBytes, signaturePath);
      }
    } else if (_signatureController.isNotEmpty && forLocalSave) {
      // For local saves, just note that a signature exists.
      signatureUrl = 'placeholder_signature';
    }

    if (_signatureController.isNotEmpty && signatureUrl == null) {
      // Failed to upload a required signature
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload signature. Please try again.'), backgroundColor: Colors.red),
      );
      return null;
    }

    // 2. Parse GPS coordinates
    double? lat, lon;
    if (_finalGpsLocation != null) {
      final parts = _finalGpsLocation!.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim());
        lon = double.tryParse(parts[1].trim());
      }
    }

    // 3. Assemble the payload
    final payload = {
      "family": {
        "id": widget.familySurveyId, // Important for local DB updates
        "village_id": _villageId,
        "signature_url": signatureUrl,
        "lat": lat,
        "lon": lon,
        "status": status, // 'submitted' or 'draft'
        "lane": _laneCtrl.text,
        "house_no": _houseNoCtrl.text,
      },
      "members": _familyMembers.map((m) => {
        "name": m.nameCtrl.text,
        "relationship_with_head": m.relationshipCtrl.text,
        // Map form value ('M'/'F') to API gender ('Male'/'Female')
        "gender": (m.gender == 'M') ? 'Male' : (m.gender == 'F' ? 'Female' : null),
        "age": int.tryParse(m.ageCtrl.text) ?? 0,
        "marital_status": m.maritalStatus,
        "religion": m.religionCtrl.text, // This was missing from the model
        "caste_category": m.caste,
        "handicapped": m.handicapped == 'Yes',
        "aadhar_no": m.aadharCtrl.text,
        "mobile_no": m.mobileCtrl.text,
        "education_qualification": m.educationCtrl.text,
        "studying_in_progress": m.studying == 'Yes',
        "artisan_details": m.artisanSkillCtrl.text,
        "interested_in_training": m.skillTrainingInterest == 'Yes',
        "photo_url": m.photoUrl,
        "bpl_card_no": m.bplCardCtrl.text,
      }).toList(),
      "accommodation": {
        "residence_years": int.tryParse(_residenceAgeCtrl.text) ?? 0,
        "authorized": _residenceAuthorized == 'Yes',
        "ownership": _residenceOwnerTenant,
        "total_rooms": int.tryParse(_residenceTotalRoomsCtrl.text) ?? 0,
        "house_type": _residencePakkaKachha,
        "roof_type": _residenceRoofType,
        "land_area": double.tryParse(_residencePlotAreaCtrl.text) ?? 0.0,
        "total_construction_area": double.tryParse(_residenceConstructionAreaCtrl.text) ?? 0.0,
        "interested_in_rr_colony": _residenceRrColonyInterest == 'Yes',
        "interested_in_own_life": _residenceLiveOwnLifeInterest == 'Yes',
        "has_well_or_borewell": _residenceWellBorewell == 'Yes',
        "has_toilet_facility": _residenceToiletFacilities == 'Yes',
        "has_cesspool": _residenceCesspool == 'Yes',
        "drainage_facility": _residenceDrainageFacility,
        "has_water_tap_facility": _residenceWaterTap == 'Yes',
        "has_electricity_facility": _residenceElectricity == 'Yes',
        "fuel_facility": _residenceFuelFacility,
        "has_solar_energy_facility": _residenceSolarEnergy == 'Yes',
        "documentary_evidence": _residenceDocumentaryEvidence == 'Yes',
        "photo_house_url": _housePhotoUrl,
      },
      "holds_land": _landHolds == 'Yes',
      "lands": _landRecords.map((l) => {
        "khata_no": l.khataNoCtrl.text,
        "land_type": l.landType,
        "total_area": double.tryParse(l.totalAreaCtrl.text) ?? 0,
        "acquired_area": double.tryParse(l.acquiredAreaCtrl.text) ?? 0,
        "remaining_area": double.tryParse(l.remainingAreaCtrl.text) ?? 0,
        "has_documentary_evidence": l.hasDocumentaryEvidence == 'Yes',
        "is_land_mortgaged": l.isLandMortgaged == 'Yes',
        "land_mortgaged_to": l.landMortgagedToCtrl.text,
        "land_mortgaged_details": l.landMortgagedDetailsCtrl.text,
      }).toList(),
      "trees": _treeRecords.map((t) => {
        "name": t.nameCtrl.text,
        "number_of_trees": int.tryParse(t.countCtrl.text) ?? 0,
        "age_of_tree": int.tryParse(t.ageCtrl.text) ?? 0,
        "tree_photo": t.photoUrl,
      }).toList(),
      "assets": _assetRecords.map((a) => {
        "name": a.nameCtrl.text,
        "count": int.tryParse(a.countCtrl.text) ?? 0,
        "asset_photo": a.photoUrl,
      }).toList(),
      "livestocks": _livestockRecords.map((l) => {
        "name": l.nameCtrl.text,
        "count": int.tryParse(l.countCtrl.text) ?? 0,
        "livestock_photo": l.photoUrl,
        "cattle_paddy_type": l.cattlePaddyType,
      }).toList(),
      // TODO: Add income, expense, and loan objects
    };
    return payload;
  }

  Future<void> _handleSubmit() async {
    setState(() => _isProcessing = true);

    final surveyData = await _gatherSurveyData('submitted');
    if (surveyData == null) {
      setState(() => _isProcessing = false);
      return; // Data gathering or signature upload failed
    }

    final result = await _surveyService.submitSurvey(surveyData, familySurveyId: widget.familySurveyId);

    setState(() => _isProcessing = false);
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey submitted successfully!'), backgroundColor: Colors.green),
        );
        // On success, delete the local draft from the device
        if (_localDbId != null) {
          await _localDb.deleteFamilySurvey(_localDbId!);
        }
        Navigator.of(context).pop(true); // Pop with a result to signal a refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit to server. Data is saved locally as a draft.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isProcessing = true);

    final surveyData = await _gatherSurveyData('draft');
    if (surveyData == null) {
      setState(() => _isProcessing = false);
      return; // Data gathering or signature upload failed
    }

    final result = await _surveyService.submitSurvey(surveyData, familySurveyId: widget.familySurveyId);

    setState(() => _isProcessing = false);
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully!'), backgroundColor: Colors.green),
        );
        // On success, delete the local draft from the device
        if (_localDbId != null) {
          await _localDb.deleteFamilySurvey(_localDbId!);
        }
        Navigator.of(context).pop(true); // Pop with a result to signal a refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save draft to server. Data is saved locally.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildMemberForm(FamilyMember member, int index) {
    // The first member is the Head of Family
    bool isHead = index == 0;
    if (isHead) {
      member.relationshipCtrl.text = 'Head';
    }

    return Column(
      key: member.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isHead)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Family Member ${index + 1}', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
                onPressed: () => _removeFamilyMember(index),
              ),
            ],
          ),
        TextFormField(controller: member.nameCtrl, onChanged: (_) => _onFieldChanged(), decoration: InputDecoration(labelText: isHead ? 'Name of Head of Family' : 'Name'), validator: _validateRequired),
        TextFormField(controller: member.relationshipCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Relationship with Head'), readOnly: isHead, validator: _validateRequired),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: member.gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['M', 'F'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) => setState(() { member.gender = val; _onFieldChanged(); }),
            validator: (v) => v == null ? 'Required' : null,
          )),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: member.ageCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Age (years)'), keyboardType: TextInputType.number, validator: _validateRequired)),
        ]),
        DropdownButtonFormField<String>(
          value: member.maritalStatus,
          decoration: const InputDecoration(labelText: 'Marital Status'),
          items: ['Married', 'Unmarried', 'Widow/Widower'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() { member.maritalStatus = val; _onFieldChanged(); }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        TextFormField(controller: member.religionCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Religion'), validator: _validateRequired),
        DropdownButtonFormField<String>(
          value: member.caste,
          decoration: const InputDecoration(labelText: 'Caste'),
          items: ['General', 'OBC', 'SC', 'ST'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() { member.caste = val; _onFieldChanged(); }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        DropdownButtonFormField<String>(
          value: member.handicapped,
          decoration: const InputDecoration(labelText: 'Handicapped'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() { member.handicapped = val; _onFieldChanged(); }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        if (isHead) Text('ID & Education Details', style: Theme.of(context).textTheme.titleLarge),
        TextFormField(controller: member.aadharCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Aadhar Card No.'), keyboardType: TextInputType.number, validator: _validateAadhar),
        TextFormField(controller: member.mobileCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone, validator: _validateMobile),
        if (isHead) TextFormField(controller: member.bplCardCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'BPL Card No.')),
        TextFormField(controller: member.educationCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Education Qualification'), validator: _validateRequired),
        DropdownButtonFormField<String>(
          value: member.studying,
          decoration: const InputDecoration(labelText: 'Studying in progress?'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() { member.studying = val; _onFieldChanged(); }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        TextFormField(controller: member.artisanSkillCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Artisan/Skill Details')),
        DropdownButtonFormField<String>(
          value: member.skillTrainingInterest,
          decoration: const InputDecoration(labelText: 'Interested in Skill Training?'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          // TODO: This should probably be a boolean in the model
          onChanged: (val) => setState(() { member.skillTrainingInterest = val; _onFieldChanged(); }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        if (!isHead) const Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildTreeRecordForm(TreeRecord tree, int index) {
    return Column(
      key: tree.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tree Record ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () => _removeTreeRecord(index),
            ),
          ],
        ),
        TextFormField(controller: tree.nameCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Name of Tree'), validator: _validateRequired),
        TextFormField(controller: tree.countCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Number of trees'), keyboardType: TextInputType.number, validator: _validateRequired),
        TextFormField(controller: tree.ageCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'How old is the tree? (years)'), keyboardType: TextInputType.number, validator: _validateRequired),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.camera_alt),
          title: Text(tree.photoUrl != null ? 'Photo Captured' : 'Capture Tree Photo'),
          onTap: () => _captureAndUploadPhoto((url) => setState(() => tree.photoUrl = url)),
          trailing: tree.photoUrl != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
        ),
        const Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildLandRecordForm(LandRecord land, int index) {
    return Column(
      key: land.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Land Record ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () => _removeLandRecord(index),
            ),
          ],
        ),
        TextFormField(controller: land.khataNoCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Khata No.'), validator: _validateRequired),
        _buildDropdown('Land Type', land.landType, ['Agricultural', 'Commercial', 'Residential'], (val) => setState(() { land.landType = val; _onFieldChanged(); })),
        TextFormField(controller: land.totalAreaCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Total Area (Sq. Meters)'), keyboardType: TextInputType.number, validator: _validateRequired),
        TextFormField(controller: land.acquiredAreaCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Acquired Area (Sq. Meters)'), keyboardType: TextInputType.number, validator: _validateRequired),
        TextFormField(controller: land.remainingAreaCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Remaining Area (Sq. Meters)'), keyboardType: TextInputType.number, validator: _validateRequired),
        _buildDropdown('Has Documentary Evidence?', land.hasDocumentaryEvidence, ['Yes', 'No'], (val) => setState(() { land.hasDocumentaryEvidence = val; _onFieldChanged(); })),
        _buildDropdown('Is Land Mortgaged?', land.isLandMortgaged, ['Yes', 'No'], (val) => setState(() { land.isLandMortgaged = val; _onFieldChanged(); })),
        if (land.isLandMortgaged == 'Yes') ...[
          TextFormField(controller: land.landMortgagedToCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Land Mortgaged To'), validator: _validateRequired),
          TextFormField(controller: land.landMortgagedDetailsCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Mortgage Details'), validator: _validateRequired),
        ],
        const Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildAssetRecordForm(AssetRecord asset, int index) {
    return Column(
      key: asset.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Asset Record ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () => _removeAssetRecord(index),
            ),
          ],
        ),
        TextFormField(controller: asset.nameCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Name of Asset (e.g., Tractor, TV)'), validator: _validateRequired),
        TextFormField(controller: asset.countCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Count'), keyboardType: TextInputType.number, validator: _validateRequired),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.camera_alt),
          title: Text(asset.photoUrl != null ? 'Photo Captured' : 'Capture Asset Photo'),
          onTap: () => _captureAndUploadPhoto((url) => setState(() => asset.photoUrl = url)),
          trailing: asset.photoUrl != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
        ),
        const Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildLivestockRecordForm(LivestockRecord livestock, int index) {
    return Column(
      key: livestock.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Livestock Record ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Remove', style: TextStyle(color: Colors.red)), onPressed: () => _removeLivestockRecord(index)),
          ],
        ),
        TextFormField(controller: livestock.nameCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Name of Livestock (e.g., Cow, Goat)'), validator: _validateRequired),
        TextFormField(controller: livestock.countCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Count'), keyboardType: TextInputType.number, validator: _validateRequired),
        _buildDropdown('Cattle Paddy Type', livestock.cattlePaddyType, ['Raw', 'Ripe', 'N/A'], (val) => setState(() { livestock.cattlePaddyType = val; _onFieldChanged(); })),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.camera_alt),
            title: Text(livestock.photoUrl != null ? 'Photo Captured' : 'Capture Livestock Photo'),
            onTap: () => _captureAndUploadPhoto((url) => setState(() => livestock.photoUrl = url)),
            trailing: livestock.photoUrl != null ? const Icon(Icons.check_circle, color: Colors.green) : null),
        const Divider(height: 32, thickness: 1),
      ],
    );
  }

  // Helper for review screen section titles
  Widget _buildReviewSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  // Helper for review screen rows
  Widget _buildReviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(flex: 3, child: Text(value ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }


  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('1. Identity & Family'),
        content: Form(
          key: _step1Key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Head of Family Details', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(controller: _familyNoCtrl, decoration: const InputDecoration(labelText: 'Family No.'), readOnly: true),
            TextFormField(controller: _villageNameCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Village Name'), readOnly: true, validator: _validateRequired),
            TextFormField(controller: _laneCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Name of the Lane'), validator: _validateRequired),
            TextFormField(controller: _houseNoCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'House No.'), validator: _validateRequired),
            const SizedBox(height: 16),
            _buildMemberForm(_familyMembers[0], 0), // Form for the Head of Family
            const SizedBox(height: 16),
            Text('Photo & Document Capture', style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_familyMembers[0].photoUrl != null ? 'Photo Captured' : 'Capture photo of person'),
              onTap: () => _captureAndUploadPhoto((url) => setState(() => _familyMembers[0].photoUrl = url)),
              trailing: _familyMembers[0].photoUrl != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
            ),
            const Divider(height: 32, thickness: 1),
            Text('Other Family Members', style: Theme.of(context).textTheme.titleLarge),
            ..._familyMembers.asMap().entries.where((entry) => entry.key > 0).map((entry) => _buildMemberForm(entry.value, entry.key)),
            Center(child: ElevatedButton.icon(onPressed: _addFamilyMember, icon: const Icon(Icons.add), label: const Text('Add New Family Member'))),
          ]),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('2. Residence & Amenities'),
        content: Form(
          key: _step2Key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Residence Details - Part 1', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(controller: _residenceAgeCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Residence Age (years)'), keyboardType: TextInputType.number, validator: _validateRequired),
            _buildDropdown('Is residence authorized?', _residenceAuthorized, ['Yes', 'No'], (val) => setState(() { _residenceAuthorized = val; _onFieldChanged(); })),
            _buildDropdown('Owner or Tenant', _residenceOwnerTenant, ['Owner', 'Tenant'], (val) => setState(() { _residenceOwnerTenant = val; _onFieldChanged(); })),
            TextFormField(controller: _residenceTotalRoomsCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Total No. of rooms'), keyboardType: TextInputType.number, validator: _validateRequired),
            _buildDropdown('House Type', _residencePakkaKachha, ['Pakka', 'Kachha'], (val) => setState(() { _residencePakkaKachha = val; _onFieldChanged(); })),
            _buildDropdown('Type of Roof', _residenceRoofType, ['RCC', 'Sheets', 'Tubes'], (val) => setState(() { _residenceRoofType = val; _onFieldChanged(); })),
            TextFormField(controller: _residencePlotAreaCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Land/Plot Area (Sq. Meters)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _residenceConstructionAreaCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Total Construction Area (Sq. Meters)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            _buildDropdown('Interested in R&R Colony?', _residenceRrColonyInterest, ['Yes', 'No'], (val) => setState(() { _residenceRrColonyInterest = val; _onFieldChanged(); })),
            _buildDropdown('Interested in living independently?', _residenceLiveOwnLifeInterest, ['Yes', 'No'], (val) => setState(() { _residenceLiveOwnLifeInterest = val; _onFieldChanged(); })),
            const Divider(height: 32),

            Text('Residence Amenities', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Well/Borewell', _residenceWellBorewell, ['Yes', 'No'], (val) => setState(() { _residenceWellBorewell = val; _onFieldChanged(); })),
            _buildDropdown('Toilet facilities', _residenceToiletFacilities, ['Yes', 'No'], (val) => setState(() { _residenceToiletFacilities = val; _onFieldChanged(); })),
            _buildDropdown('Cesspool', _residenceCesspool, ['Yes', 'No'], (val) => setState(() { _residenceCesspool = val; _onFieldChanged(); })),
            _buildDropdown('Drainage Facility', _residenceDrainageFacility, ['Underground', 'Open', 'None'], (val) => setState(() { _residenceDrainageFacility = val; _onFieldChanged(); })),
            _buildDropdown('Water Tap Facility', _residenceWaterTap, ['Yes', 'No'], (val) => setState(() { _residenceWaterTap = val; _onFieldChanged(); })),
            _buildDropdown('Electricity facility', _residenceElectricity, ['Yes', 'No'], (val) => setState(() { _residenceElectricity = val; _onFieldChanged(); })),
            _buildDropdown('Fuel Facility', _residenceFuelFacility, ['Wood', 'Coal', 'Kerosene', 'Gas'], (val) => setState(() { _residenceFuelFacility = val; _onFieldChanged(); })),
            _buildDropdown('Solar Energy Facility', _residenceSolarEnergy, ['Yes', 'No'], (val) => setState(() { _residenceSolarEnergy = val; _onFieldChanged(); })),
            const Divider(height: 32),

            Text('Residence Document Capture', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Is there documentary evidence?', _residenceDocumentaryEvidence, ['Yes', 'No'], (val) => setState(() { _residenceDocumentaryEvidence = val; _onFieldChanged(); })),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_housePhotoUrl != null ? 'Photo Captured' : 'Capture House/Document Photo'),
              onTap: () => _captureAndUploadPhoto((url) => setState(() => _housePhotoUrl = url)),
              trailing: _housePhotoUrl != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
            ),
          ]),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('3. Land & Tree Assets'),
        content: Form(
          key: _step3Key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Land Ownership Details', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Does the family hold any land?', _landHolds, ['Yes', 'No'], (val) => setState(() { _landHolds = val; _onFieldChanged(); })),
            if (_landHolds == 'Yes') ...[
              const SizedBox(height: 16),
              if (_landRecords.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('No land records added.'))),
              ..._landRecords.asMap().entries.map((entry) => _buildLandRecordForm(entry.value, entry.key)),
              Center(child: ElevatedButton.icon(onPressed: _addLandRecord, icon: const Icon(Icons.add), label: const Text('Add a land record'))),
            ],
            const Divider(height: 32),
            Text('Tree Details', style: Theme.of(context).textTheme.titleLarge),
            if (_treeRecords.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('No tree records added.'))),
            ..._treeRecords.asMap().entries.map((entry) => _buildTreeRecordForm(entry.value, entry.key)),
            Center(child: ElevatedButton.icon(onPressed: _addTreeRecord, icon: const Icon(Icons.add), label: const Text('Add a tree record'))),
          ]),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('4. Income & Other Assets'),
        content: Form(
          key: _step4Key, 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Annual Income Sources', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(controller: _incomeFarmingCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Farming'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeJobCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Job (Govt/Semi-Govt/Other)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeBusinessCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Business'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeLaborCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Labor (Agricultural/Other)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeHouseworkCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Housework'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeOtherCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Other income'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _estimatedAnnualIncomeCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Total Estimated Annual Income'), readOnly: true, validator: _validateRequired),
            const Divider(height: 32),

            Text('Other Assets', style: Theme.of(context).textTheme.titleLarge),
            if (_assetRecords.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('No asset records added.'))),
            ..._assetRecords.asMap().entries.map((entry) => _buildAssetRecordForm(entry.value, entry.key)),
            Center(child: ElevatedButton.icon(onPressed: _addAssetRecord, icon: const Icon(Icons.add), label: const Text('Add an asset record'))),
            const Divider(height: 32),

            Text('Livestock Details', style: Theme.of(context).textTheme.titleLarge),
            if (_livestockRecords.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('No livestock records added.'))),
            ..._livestockRecords.asMap().entries.map((entry) => _buildLivestockRecordForm(entry.value, entry.key)),
            Center(child: ElevatedButton.icon(onPressed: _addLivestockRecord, icon: const Icon(Icons.add), label: const Text('Add a livestock record'))),

          ]),
        ),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('5. Finance & Documents'),
        content: Form(
          key: _step5Key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Annual Expenses', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(controller: _expenseAgricultureCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Agriculture'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseHouseCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'House'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseFoodCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Food'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseFuelCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Fuel'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseElectricityCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Electricity'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseClothsCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Cloths'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseHealthCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Health'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseEducationCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Education'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseTransportationCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Transportation'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseCommunicationCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Communication'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseCinemaHotelCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Cinema/Hotel'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseTaxesCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Taxes'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseOthersCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Others'), keyboardType: TextInputType.number, validator: _validateRequired),
            const Divider(height: 32),

            Text('Loans and Debts', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Have taken any loan?', _loanTaken, ['Yes', 'No'], (val) => setState(() { _loanTaken = val; _onFieldChanged(); })),
            if (_loanTaken == 'Yes') ...[
              TextFormField(controller: _loanAmountCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Loan Amount (Rs.)'), keyboardType: TextInputType.number, validator: _validateRequired),
              TextFormField(controller: _loanTenureYearsCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Loan Tenure (Years)'), keyboardType: TextInputType.number, validator: _validateRequired),
              TextFormField(controller: _loanObtainedFromCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Where is the loan obtained from?'), validator: _validateRequired),
              TextFormField(controller: _loanPurposeCtrl, onChanged: (_) => _onFieldChanged(), decoration: const InputDecoration(labelText: 'Purpose of getting loan'), validator: _validateRequired),
            ],
            const Divider(height: 32),

            Text('Final Verification', style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.gps_fixed, color: _finalGpsLocation != null ? Colors.green : null),
              title: Text(_finalGpsLocation ?? 'Capturing GPS...'),
              subtitle: const Text('Capture GPS'),
              onTap: _captureGpsLocation,
            ),
            const SizedBox(height: 16),
            const Text('Digital Signature of Head of Family', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(controller: _signatureController, height: 150, backgroundColor: Colors.grey[200]!),
            ),
            TextButton(onPressed: () => _signatureController.clear(), child: const Text('Clear Signature')),
          ]),
        ),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('6. Review & Submit'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review Complete', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('All mandatory verification steps have been completed. Review the collected data below before final submission.'),
            const Divider(height: 32),

            // Step 1 Review
            _buildReviewSectionTitle('1. Identity & Family'),
            _buildReviewRow('Family No.', _familyNoCtrl.text),
            _buildReviewRow('Village Name', _villageNameCtrl.text),
            _buildReviewRow('Lane', _laneCtrl.text),
            _buildReviewRow('House No.', _houseNoCtrl.text),
            for (var i = 0; i < _familyMembers.length; i++)
              ExpansionTile(
                title: Text(i == 0 ? 'Head of Family' : 'Family Member ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  _buildReviewRow('Name', _familyMembers[i].nameCtrl.text),
                  _buildReviewRow('Relationship', _familyMembers[i].relationshipCtrl.text),
                  _buildReviewRow('Gender', _familyMembers[i].gender),
                  _buildReviewRow('Age', _familyMembers[i].ageCtrl.text),
                  _buildReviewRow('Marital Status', _familyMembers[i].maritalStatus),
                  _buildReviewRow('Photo', _familyMembers[i].photoUrl != null ? 'Captured' : 'Not Captured'),
                  _buildReviewRow('Aadhar No.', _familyMembers[i].aadharCtrl.text),
                  _buildReviewRow('Mobile No.', _familyMembers[i].mobileCtrl.text),
                ],
              ),

            // Step 2 Review
            _buildReviewSectionTitle('2. Residence & Amenities'),
            _buildReviewRow('Residence Age', '${_residenceAgeCtrl.text} years'),
            _buildReviewRow('Is Authorized?', _residenceAuthorized),
            _buildReviewRow('Ownership', _residenceOwnerTenant),
            _buildReviewRow('House Type', _residencePakkaKachha),
            _buildReviewRow('Toilet Facilities', _residenceToiletFacilities),
            _buildReviewRow('Electricity', _residenceElectricity),
            _buildReviewRow('House Photo', _housePhotoUrl != null ? 'Captured' : 'Not Captured'),
            _buildReviewRow('Fuel Facility', _residenceFuelFacility),

            // Step 3 Review
            _buildReviewSectionTitle('3. Land & Tree Assets'),
            _buildReviewRow('Holds Land?', _landHolds),
            if (_landHolds == 'Yes')
              _buildReviewRow('Land Records', _landRecords.isNotEmpty ? '${_landRecords.length} record(s)' : 'None'),
            _buildReviewRow('Tree Records', _treeRecords.isNotEmpty ? '${_treeRecords.length} record(s)' : 'None'),

            // Step 4 Review
            _buildReviewSectionTitle('4. Income & Other Assets'),
            _buildReviewRow('Total Annual Income', _estimatedAnnualIncomeCtrl.text),
            _buildReviewRow('Asset Records', _assetRecords.isNotEmpty ? '${_assetRecords.length} record(s)' : 'None'),
            for (var asset in _assetRecords)
              Padding(padding: const EdgeInsets.only(left: 16.0), child: _buildReviewRow(asset.nameCtrl.text, 'Count: ${asset.countCtrl.text}')),

            _buildReviewRow('Livestock Records', _livestockRecords.isNotEmpty ? '${_livestockRecords.length} record(s)' : 'None'),
            for (var livestock in _livestockRecords)
              Padding(padding: const EdgeInsets.only(left: 16.0), child: _buildReviewRow(livestock.nameCtrl.text, 'Count: ${livestock.countCtrl.text}')),


            // Step 5 Review
            _buildReviewSectionTitle('5. Finance & Verification'),
            _buildReviewRow('Total Annual Expense', '...'), // Placeholder for calculated total expense
            _buildReviewRow('Loan Taken?', _loanTaken),
            if (_loanTaken == 'Yes')
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildReviewRow('Loan Amount', _loanAmountCtrl.text),
              ),
            _buildReviewRow('GPS Location', _finalGpsLocation != null ? 'Captured' : 'Pending'),
            _buildReviewRow('Signature', _signatureController.isNotEmpty ? 'Signed' : 'Not Signed'),
            if (_signatureController.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: FutureBuilder<Uint8List?>(
                    future: _signatureController.toPngBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                        );
                      }
                      // Show a placeholder or loading indicator while waiting
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
          ],
        ),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  // Helper widget to build dropdowns consistently
  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'This field is required' : null,
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If processing, prevent user from leaving
        if (_isProcessing) return false;

        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Progress?'),
            content: const Text('Do you want to save your changes as a local draft before leaving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Don't save
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Save
                child: const Text('Save Draft'),
              ),
            ],
          ),
        );

        // If the dialog is dismissed (e.g., by tapping outside), do nothing.
        if (shouldSave == null) return false;

        if (shouldSave) {
          // User chose to save.
          await _saveLocally();
          // Pop screen and signal a refresh.
          Navigator.of(context).pop(true);
        } else {
          // User chose to discard. Delete the local draft if it's a new one.
          if (_localDbId != null && widget.familySurveyId == null) {
            await _localDb.deleteFamilySurvey(_localDbId!);
          }
          // Pop screen without signaling a refresh.
          Navigator.of(context).pop(false);
        }

        return false; // We've handled the navigation manually.
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Family Survey'),
        ),
        body: _isLoadingSurvey
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading survey data...'),
                  ],
                ),
              )
            : Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                onStepTapped: (step) => setState(() => _currentStep = step),
                steps: _getSteps(),
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  // This builder is intentionally left empty to hide the default
                  // "CONTINUE" and "CANCEL" buttons. We will use the
                  // bottomNavigationBar for navigation.
                  // The Stepper will still handle scrolling to the next step
                  // when _onStepContinue is called and validation passes.
                  return const SizedBox.shrink();
                },
              ),
        bottomNavigationBar: _isProcessing
            ? const LinearProgressIndicator()
            : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _isProcessing ? null : _handleSaveDraft, child: const Text('Save Draft'))),
                const SizedBox(width: 16), 
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isProcessing ? null : (_currentStep == _getSteps().length - 1 ? _handleSubmit : _onStepContinue),
                        child: _isProcessing
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Text(_currentStep == _getSteps().length - 1 ? 'Submit Survey' : 'Continue'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}