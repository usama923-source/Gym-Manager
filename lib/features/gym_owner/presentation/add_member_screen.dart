import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym/core/widgets/custom_text_field.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:intl/intl.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _profilePhotoUrlController = TextEditingController();
  final _phoneController = TextEditingController();
  final _monthlyPlanAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _admissionFeeController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender;
  String? _selectedPaymentMethod;
  DateTime? _joinDate;
  DateTime? _paymentDate;
  DateTime? _dob;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _paymentMethods = ['Cash', 'EasyPaisa', 'Jazz Cash', 'Bank Transfer'];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _profilePhotoUrlController.dispose();
    _phoneController.dispose();
    _monthlyPlanAmountController.dispose();
    _paidAmountController.dispose();
    _admissionFeeController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime> onDateSelected) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null || user.gymId == null) throw 'Gym not found';

      final gymId = user.gymId!;
      final generatedMemberId = 'MEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final member = MemberModel(
        id: 'temp', // Replaced by Firestore document ID in repository, but gymOwnerRepository.addMember sets docRef.id if we use doc().id. Wait, `addMember` currently does `docRef.set(member.toMap())`. `MemberModel` has `id: documentId` in `fromMap`, but `toMap` doesn't include `id`. So 'temp' is fine.
        gymId: gymId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        profilePhotoUrl: _profilePhotoUrlController.text.trim().isEmpty ? null : _profilePhotoUrlController.text.trim(),
        gender: _selectedGender,
        memberId: generatedMemberId,
        monthlyPlanAmount: double.tryParse(_monthlyPlanAmountController.text.trim()),
        startDate: _joinDate,
        paymentDate: _paymentDate,
        paidAmount: double.tryParse(_paidAmountController.text.trim()),
        paymentMethod: _selectedPaymentMethod,
        admissionFee: double.tryParse(_admissionFeeController.text.trim()),
        dateOfBirth: _dob,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await ref.read(gymOwnerRepositoryProvider).addMember(member);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Name *',
                hintText: 'Enter member name',
                prefixIcon: Icons.person,
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _profilePhotoUrlController,
                labelText: 'Profile Photo URL (Optional)',
                hintText: 'Enter image URL',
                prefixIcon: Icons.image,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender (Optional)',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedGender,
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Mobile Number (Optional)',
                hintText: 'Enter mobile number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _monthlyPlanAmountController,
                labelText: 'Monthly Plan Amount (Optional)',
                hintText: 'Enter amount',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Join Date (Optional)'),
                subtitle: Text(_joinDate != null ? DateFormat.yMMMd().format(_joinDate!) : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, _joinDate, (date) => setState(() => _joinDate = date)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Payment Date (Optional)'),
                subtitle: Text(_paymentDate != null ? DateFormat.yMMMd().format(_paymentDate!) : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, _paymentDate, (date) => setState(() => _paymentDate = date)),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _paidAmountController,
                labelText: 'Paid Amount (Optional)',
                hintText: 'Enter paid amount',
                prefixIcon: Icons.money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedPaymentMethod,
                items: _paymentMethods.map((pm) => DropdownMenuItem(value: pm, child: Text(pm))).toList(),
                onChanged: (val) => setState(() => _selectedPaymentMethod = val),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _admissionFeeController,
                labelText: 'Admission Fee (Optional)',
                hintText: 'Enter admission fee',
                prefixIcon: Icons.payments,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email (Optional)',
                hintText: 'Enter email address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date of Birth (Optional)'),
                subtitle: Text(_dob != null ? DateFormat.yMMMd().format(_dob!) : 'Not set'),
                trailing: const Icon(Icons.cake),
                onTap: () => _selectDate(context, _dob, (date) => setState(() => _dob = date)),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                labelText: 'Address (Optional)',
                hintText: 'Enter physical address',
                prefixIcon: Icons.home,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Add Member'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
