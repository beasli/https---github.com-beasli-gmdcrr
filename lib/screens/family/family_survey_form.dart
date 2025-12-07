import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'package:signature/signature.dart';

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
}

/// Data model for a single tree record.
class TreeRecord {
  final UniqueKey key = UniqueKey();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController countCtrl = TextEditingController();
  TextEditingController ageCtrl = TextEditingController();
  String? photoPath;
}

class FamilySurveyFormPage extends StatefulWidget {
  const FamilySurveyFormPage({super.key});

  @override
  State<FamilySurveyFormPage> createState() => _FamilySurveyFormPageState();
}

class _FamilySurveyFormPageState extends State<FamilySurveyFormPage> {
  int _currentStep = 0;
  bool _isProcessing = false;

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
  String? _photoPath;

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
  String? _housePhotoPath;

  // Step 3: Land & Tree Assets Controllers
  String? _landHolds;
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
  String? _assetTractor;
  String? _assetTwoWheeler;
  String? _assetMotorcar;
  String? _assetTempoTruck;
  String? _assetTv;
  String? _assetFridge;
  String? _assetAc;
  String? _assetFlourMill;
  final _assetOtherDetailsCtrl = TextEditingController();
  String? _assetsPhotoPath;

  // Livestock
  final _livestockCowCtrl = TextEditingController();
  final _livestockOxCtrl = TextEditingController();
  final _livestockBuffaloCtrl = TextEditingController();
  final _livestockSheepCtrl = TextEditingController();
  final _livestockGoatCtrl = TextEditingController();
  final _livestockPoultryCtrl = TextEditingController();
  final _livestockCamelCtrl = TextEditingController();
  String? _livestockCattlePaddyType;
  final _livestockOtherDetailsCtrl = TextEditingController();
  String? _livestockPhotoPath;

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

  void _calculateTotalIncome() {
    final total = (double.tryParse(_incomeFarmingCtrl.text) ?? 0) + (double.tryParse(_incomeJobCtrl.text) ?? 0) + (double.tryParse(_incomeBusinessCtrl.text) ?? 0) + (double.tryParse(_incomeLaborCtrl.text) ?? 0) + (double.tryParse(_incomeHouseworkCtrl.text) ?? 0) + (double.tryParse(_incomeOtherCtrl.text) ?? 0);
    _estimatedAnnualIncomeCtrl.text = total.toStringAsFixed(2);
  }


  @override
  void dispose() {
    // Dispose head-of-family specific controllers
    _familyNoCtrl.dispose();
    _villageNameCtrl.dispose();
    _laneCtrl.dispose();
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
    for (var tree in _treeRecords) {
      _disposeTreeRecordControllers(tree);
    }
    // Dispose Step 4 controllers
    _incomeFarmingCtrl.removeListener(_calculateTotalIncome);
    _incomeJobCtrl.removeListener(_calculateTotalIncome);
    _incomeBusinessCtrl.removeListener(_calculateTotalIncome);
    _incomeLaborCtrl.removeListener(_calculateTotalIncome);
    _incomeHouseworkCtrl.removeListener(_calculateTotalIncome);
    _incomeOtherCtrl.removeListener(_calculateTotalIncome);
    _incomeFarmingCtrl.dispose();
    _incomeJobCtrl.dispose();
    _incomeBusinessCtrl.dispose();
    _incomeLaborCtrl.dispose();
    _incomeHouseworkCtrl.dispose();
    _incomeOtherCtrl.dispose();
    _estimatedAnnualIncomeCtrl.dispose();
    _assetOtherDetailsCtrl.dispose();
    _livestockCowCtrl.dispose();
    _livestockOxCtrl.dispose();
    _livestockBuffaloCtrl.dispose();
    _livestockSheepCtrl.dispose();
    _livestockGoatCtrl.dispose();
    _livestockPoultryCtrl.dispose();
    _livestockCamelCtrl.dispose();
    _livestockOtherDetailsCtrl.dispose();
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
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _disposeMemberControllers(_familyMembers[index]);
      _familyMembers.removeAt(index);
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
    });
  }

  void _removeTreeRecord(int index) {
    setState(() {
      _disposeTreeRecordControllers(_treeRecords[index]);
      _treeRecords.removeAt(index);
    });
  }

  Future<void> _captureGpsLocation() async {
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

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _finalGpsLocation = '${position.latitude}, ${position.longitude}';
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
      _handleSubmit();
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

  Future<void> _handleSubmit() async {
    setState(() => _isProcessing = true);
    // TODO: Implement validation and submission logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate network request
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey submitted successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isProcessing = true);
    // TODO: Implement save draft logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate saving
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved!')),
      );
      Navigator.of(context).pop();
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
        TextFormField(controller: member.nameCtrl, decoration: InputDecoration(labelText: isHead ? 'Name of Head of Family' : 'Name'), validator: _validateRequired),
        TextFormField(controller: member.relationshipCtrl, decoration: const InputDecoration(labelText: 'Relationship with Head'), readOnly: isHead, validator: _validateRequired),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: member.gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['M', 'F'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) => setState(() => member.gender = val),
            validator: (v) => v == null ? 'Required' : null,
          )),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: member.ageCtrl, decoration: const InputDecoration(labelText: 'Age (years)'), keyboardType: TextInputType.number, validator: _validateRequired)),
        ]),
        DropdownButtonFormField<String>(
          value: member.maritalStatus,
          decoration: const InputDecoration(labelText: 'Marital Status'),
          items: ['Married', 'Unmarried', 'Widow/Widower'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => member.maritalStatus = val),
          validator: (v) => v == null ? 'Required' : null,
        ),
        TextFormField(controller: member.religionCtrl, decoration: const InputDecoration(labelText: 'Religion'), validator: _validateRequired),
        DropdownButtonFormField<String>(
          value: member.caste,
          decoration: const InputDecoration(labelText: 'Caste'),
          items: ['General', 'OBC', 'SC', 'ST'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => member.caste = val),
          validator: (v) => v == null ? 'Required' : null,
        ),
        DropdownButtonFormField<String>(
          value: member.handicapped,
          decoration: const InputDecoration(labelText: 'Handicapped'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => member.handicapped = val),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        if (isHead) Text('ID & Education Details', style: Theme.of(context).textTheme.titleLarge),
        TextFormField(controller: member.aadharCtrl, decoration: const InputDecoration(labelText: 'Aadhar Card No.'), keyboardType: TextInputType.number, validator: _validateRequired),
        TextFormField(controller: member.mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone, validator: _validateRequired),
        if (isHead) TextFormField(controller: member.bplCardCtrl, decoration: const InputDecoration(labelText: 'BPL Card No.')),
        TextFormField(controller: member.educationCtrl, decoration: const InputDecoration(labelText: 'Education Qualification'), validator: _validateRequired),
        DropdownButtonFormField<String>(
          value: member.studying,
          decoration: const InputDecoration(labelText: 'Studying in progress?'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => member.studying = val),
          validator: (v) => v == null ? 'Required' : null,
        ),
        TextFormField(controller: member.artisanSkillCtrl, decoration: const InputDecoration(labelText: 'Artisan/Skill Details')),
        DropdownButtonFormField<String>(
          value: member.skillTrainingInterest,
          decoration: const InputDecoration(labelText: 'Interested in Skill Training?'),
          items: ['Yes', 'No'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => member.skillTrainingInterest = val),
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
        TextFormField(controller: tree.nameCtrl, decoration: const InputDecoration(labelText: 'Name of Tree'), validator: _validateRequired),
        TextFormField(controller: tree.countCtrl, decoration: const InputDecoration(labelText: 'Number of trees'), keyboardType: TextInputType.number, validator: _validateRequired),
        TextFormField(controller: tree.ageCtrl, decoration: const InputDecoration(labelText: 'How old is the tree? (years)'), keyboardType: TextInputType.number, validator: _validateRequired),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.camera_alt),
          title: Text(tree.photoPath ?? 'Capture Tree Photo'),
          onTap: () {
            // TODO: Implement photo capture for this specific tree record
            // You would likely pass the index to the capture logic and update
            // setState(() => tree.photoPath = newPath);
          },
          trailing: tree.photoPath != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
        ),
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
            TextFormField(controller: _villageNameCtrl, decoration: const InputDecoration(labelText: 'Village Name'), validator: _validateRequired),
            TextFormField(controller: _laneCtrl, decoration: const InputDecoration(labelText: 'Name of the Lane'), validator: _validateRequired),
            TextFormField(controller: _houseNoCtrl, decoration: const InputDecoration(labelText: 'House No.'), validator: _validateRequired),
            const SizedBox(height: 16),
            _buildMemberForm(_familyMembers[0], 0), // Form for the Head of Family
            const SizedBox(height: 16),
            Text('Photo & Document Capture', style: Theme.of(context).textTheme.titleLarge),
            // TODO: Implement photo capture logic
            ListTile(leading: const Icon(Icons.camera_alt), title: Text(_photoPath ?? 'Capture photo of person'), onTap: () {}, trailing: _photoPath != null ? const Icon(Icons.check_circle, color: Colors.green) : null),
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
            TextFormField(controller: _residenceAgeCtrl, decoration: const InputDecoration(labelText: 'Residence Age (years)'), keyboardType: TextInputType.number, validator: _validateRequired),
            _buildDropdown('Is residence authorized?', _residenceAuthorized, ['Yes', 'No'], (val) => setState(() => _residenceAuthorized = val)),
            _buildDropdown('Owner or Tenant', _residenceOwnerTenant, ['Owner', 'Tenant'], (val) => setState(() => _residenceOwnerTenant = val)),
            TextFormField(controller: _residenceTotalRoomsCtrl, decoration: const InputDecoration(labelText: 'Total No. of rooms'), keyboardType: TextInputType.number, validator: _validateRequired),
            _buildDropdown('House Type', _residencePakkaKachha, ['Pakka', 'Kachha'], (val) => setState(() => _residencePakkaKachha = val)),
            _buildDropdown('Type of Roof', _residenceRoofType, ['RCC', 'Sheets', 'Tubes'], (val) => setState(() => _residenceRoofType = val)),
            TextFormField(controller: _residencePlotAreaCtrl, decoration: const InputDecoration(labelText: 'Land/Plot Area (Sq. Meters)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _residenceConstructionAreaCtrl, decoration: const InputDecoration(labelText: 'Total Construction Area (Sq. Meters)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            _buildDropdown('Interested in R&R Colony?', _residenceRrColonyInterest, ['Yes', 'No'], (val) => setState(() => _residenceRrColonyInterest = val)),
            _buildDropdown('Interested in living independently?', _residenceLiveOwnLifeInterest, ['Yes', 'No'], (val) => setState(() => _residenceLiveOwnLifeInterest = val)),
            const Divider(height: 32),

            Text('Residence Amenities', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Well/Borewell', _residenceWellBorewell, ['Yes', 'No'], (val) => setState(() => _residenceWellBorewell = val)),
            _buildDropdown('Toilet facilities', _residenceToiletFacilities, ['Yes', 'No'], (val) => setState(() => _residenceToiletFacilities = val)),
            _buildDropdown('Cesspool', _residenceCesspool, ['Yes', 'No'], (val) => setState(() => _residenceCesspool = val)),
            _buildDropdown('Drainage Facility', _residenceDrainageFacility, ['Underground', 'Open', 'None'], (val) => setState(() => _residenceDrainageFacility = val)),
            _buildDropdown('Water Tap Facility', _residenceWaterTap, ['Yes', 'No'], (val) => setState(() => _residenceWaterTap = val)),
            _buildDropdown('Electricity facility', _residenceElectricity, ['Yes', 'No'], (val) => setState(() => _residenceElectricity = val)),
            _buildDropdown('Fuel Facility', _residenceFuelFacility, ['Wood', 'Coal', 'Kerosene', 'Gas'], (val) => setState(() => _residenceFuelFacility = val)),
            _buildDropdown('Solar Energy Facility', _residenceSolarEnergy, ['Yes', 'No'], (val) => setState(() => _residenceSolarEnergy = val)),
            const Divider(height: 32),

            Text('Residence Document Capture', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Is there documentary evidence?', _residenceDocumentaryEvidence, ['Yes', 'No'], (val) => setState(() => _residenceDocumentaryEvidence = val)),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_housePhotoPath ?? 'Capture House/Document Photo'),
              onTap: () { /* TODO: Implement photo capture */ },
              trailing: _housePhotoPath != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
            _buildDropdown('Does the family hold any land?', _landHolds, ['Yes', 'No'], (val) => setState(() => _landHolds = val)),
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
            TextFormField(controller: _incomeFarmingCtrl, decoration: const InputDecoration(labelText: 'Farming'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeJobCtrl, decoration: const InputDecoration(labelText: 'Job (Govt/Semi-Govt/Other)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeBusinessCtrl, decoration: const InputDecoration(labelText: 'Business'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeLaborCtrl, decoration: const InputDecoration(labelText: 'Labor (Agricultural/Other)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeHouseworkCtrl, decoration: const InputDecoration(labelText: 'Housework'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _incomeOtherCtrl, decoration: const InputDecoration(labelText: 'Other income'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateRequired),
            TextFormField(controller: _estimatedAnnualIncomeCtrl, decoration: const InputDecoration(labelText: 'Total Estimated Annual Income'), readOnly: true, validator: _validateRequired),
            const Divider(height: 32),

            Text('Other Assets', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Tractor', _assetTractor, ['Yes', 'No'], (val) => setState(() => _assetTractor = val)),
            _buildDropdown('Scooter/Motor Cycle/Auto Rickshaw', _assetTwoWheeler, ['Yes', 'No'], (val) => setState(() => _assetTwoWheeler = val)),
            _buildDropdown('Motorcar', _assetMotorcar, ['Yes', 'No'], (val) => setState(() => _assetMotorcar = val)),
            _buildDropdown('Tempo/Truck', _assetTempoTruck, ['Yes', 'No'], (val) => setState(() => _assetTempoTruck = val)),
            _buildDropdown('TV', _assetTv, ['Yes', 'No'], (val) => setState(() => _assetTv = val)),
            _buildDropdown('Fridge', _assetFridge, ['Yes', 'No'], (val) => setState(() => _assetFridge = val)),
            _buildDropdown('AC', _assetAc, ['Yes', 'No'], (val) => setState(() => _assetAc = val)),
            _buildDropdown('Flour Mill', _assetFlourMill, ['Yes', 'No'], (val) => setState(() => _assetFlourMill = val)),
            TextFormField(controller: _assetOtherDetailsCtrl, decoration: const InputDecoration(labelText: 'Other Assets Details')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt),
              title: Text(_assetsPhotoPath ?? 'Capture Other Assets Photo'),
              onTap: () { /* TODO: Implement photo capture */ },
              trailing: _assetsPhotoPath != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
            ),
            const Divider(height: 32),

            Text('Livestock Details', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(controller: _livestockCowCtrl, decoration: const InputDecoration(labelText: 'COW Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockOxCtrl, decoration: const InputDecoration(labelText: 'OX Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockBuffaloCtrl, decoration: const InputDecoration(labelText: 'Buffalo Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockSheepCtrl, decoration: const InputDecoration(labelText: 'Sheep Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockGoatCtrl, decoration: const InputDecoration(labelText: 'Goat Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockPoultryCtrl, decoration: const InputDecoration(labelText: 'Poultry Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _livestockCamelCtrl, decoration: const InputDecoration(labelText: 'Camel Count'), keyboardType: TextInputType.number, validator: _validateRequired),
            _buildDropdown('Cattle Paddy Type', _livestockCattlePaddyType, ['Raw', 'Ripe'], (val) => setState(() => _livestockCattlePaddyType = val)),
            TextFormField(controller: _livestockOtherDetailsCtrl, decoration: const InputDecoration(labelText: 'Other Livestock Details')),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.camera_alt), title: Text(_livestockPhotoPath ?? 'Capture Livestock Photo'), onTap: () { /* TODO: Implement photo capture */ }, trailing: _livestockPhotoPath != null ? const Icon(Icons.check_circle, color: Colors.green) : null),
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
            TextFormField(controller: _expenseAgricultureCtrl, decoration: const InputDecoration(labelText: 'Agriculture'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseHouseCtrl, decoration: const InputDecoration(labelText: 'House'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseFoodCtrl, decoration: const InputDecoration(labelText: 'Food'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseFuelCtrl, decoration: const InputDecoration(labelText: 'Fuel'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseElectricityCtrl, decoration: const InputDecoration(labelText: 'Electricity'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseClothsCtrl, decoration: const InputDecoration(labelText: 'Cloths'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseHealthCtrl, decoration: const InputDecoration(labelText: 'Health'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseEducationCtrl, decoration: const InputDecoration(labelText: 'Education'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseTransportationCtrl, decoration: const InputDecoration(labelText: 'Transportation'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseCommunicationCtrl, decoration: const InputDecoration(labelText: 'Communication'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseCinemaHotelCtrl, decoration: const InputDecoration(labelText: 'Cinema/Hotel'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseTaxesCtrl, decoration: const InputDecoration(labelText: 'Taxes'), keyboardType: TextInputType.number, validator: _validateRequired),
            TextFormField(controller: _expenseOthersCtrl, decoration: const InputDecoration(labelText: 'Others'), keyboardType: TextInputType.number, validator: _validateRequired),
            const Divider(height: 32),

            Text('Loans and Debts', style: Theme.of(context).textTheme.titleLarge),
            _buildDropdown('Have taken any loan?', _loanTaken, ['Yes', 'No'], (val) => setState(() => _loanTaken = val)),
            if (_loanTaken == 'Yes') ...[
              TextFormField(controller: _loanAmountCtrl, decoration: const InputDecoration(labelText: 'Loan Amount (Rs.)'), keyboardType: TextInputType.number, validator: _validateRequired),
              TextFormField(controller: _loanTenureYearsCtrl, decoration: const InputDecoration(labelText: 'Loan Tenure (Years)'), keyboardType: TextInputType.number, validator: _validateRequired),
              TextFormField(controller: _loanObtainedFromCtrl, decoration: const InputDecoration(labelText: 'Where is the loan obtained from?'), validator: _validateRequired),
              TextFormField(controller: _loanPurposeCtrl, decoration: const InputDecoration(labelText: 'Purpose of getting loan'), validator: _validateRequired),
            ],
            const Divider(height: 32),

            Text('Final Verification', style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.gps_fixed, color: _finalGpsLocation != null ? Colors.green : null),
              title: Text(_finalGpsLocation ?? 'GPS Location Status: Pending'),
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
            _buildReviewRow('Fuel Facility', _residenceFuelFacility),

            // Step 3 Review
            _buildReviewSectionTitle('3. Land & Tree Assets'),
            _buildReviewRow('Holds Land?', _landHolds),
            _buildReviewRow('Tree Records', _treeRecords.isNotEmpty ? '${_treeRecords.length} record(s)' : 'None'),

            // Step 4 Review
            _buildReviewSectionTitle('4. Income & Other Assets'),
            _buildReviewRow('Total Annual Income', _estimatedAnnualIncomeCtrl.text),
            _buildReviewRow('Has Tractor?', _assetTractor),
            _buildReviewRow('Has Two-Wheeler?', _assetTwoWheeler),
            _buildReviewRow('Has Motorcar?', _assetMotorcar),
            _buildReviewRow('Cow Count', _livestockCowCtrl.text),
            _buildReviewRow('Buffalo Count', _livestockBuffaloCtrl.text),
            _buildReviewRow('Goat Count', _livestockGoatCtrl.text),

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
                          color: Colors.black,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Family Survey')),
      body: SingleChildScrollView(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          steps: _getSteps(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _isProcessing ? null : _handleSaveDraft, child: const Text('Save Draft'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: _isProcessing ? null : _handleSubmit, child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Text('Submit Survey'))),
            ],
          ),
        ),
      ),
    );
  }
}