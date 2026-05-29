import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/payment_model.dart';

import 'package:gym/core/theme/app_theme.dart';

class RenewPlanDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const RenewPlanDialog({super.key, required this.member});

  @override
  ConsumerState<RenewPlanDialog> createState() => _RenewPlanDialogState();
}

class _RenewPlanDialogState extends ConsumerState<RenewPlanDialog> {
  String _paymentStatus = 'Pending';
  String _paymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'EasyPaisa', 'Jazz Cash', 'Bank Transfer'];
  bool _isLoading = false;
  late TextEditingController _amountController;
  late double planRate;
  late double previousDue;
  late double totalDueNow;

  @override
  void initState() {
    super.initState();
    planRate = widget.member.monthlyPlanAmount ?? 0.0;
    previousDue = planRate - (widget.member.paidAmount ?? 0.0);
    totalDueNow = planRate + previousDue;
    _amountController = TextEditingController(text: (totalDueNow > 0 ? totalDueNow : 0).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getFormTheme(context),
      child: AlertDialog(
        title: const Text('Renew Plan'),
        content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan Rate: \$${planRate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Previous Balance: \$${previousDue.abs().toStringAsFixed(2)} ${previousDue > 0 ? "(Pending)" : previousDue < 0 ? "(Advance)" : ""}',
              style: TextStyle(color: previousDue > 0 ? Colors.red : previousDue < 0 ? Colors.green : Colors.black),
            ),
            const Divider(),
            Text('Total Due Now: \$${totalDueNow.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Payment Status'),
              value: _paymentStatus,
              items: ['Pending', 'Received']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _paymentStatus = val);
              },
            ),
            if (_paymentStatus == 'Received') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount Received', prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Payment Method'),
                value: _paymentMethod,
                items: _paymentMethods
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Renew'),
        ),
      ],
    ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gymOwnerRepositoryProvider);
      final now = DateTime.now();
      
      // Calculate new expiry date (+30 days)
      DateTime newExpiry = widget.member.expiryDate ?? now;
      if (newExpiry.isBefore(now)) {
        newExpiry = now;
      }
      newExpiry = newExpiry.add(const Duration(days: 30));

      double amountReceived = 0.0;
      if (_paymentStatus == 'Received') {
        amountReceived = double.tryParse(_amountController.text) ?? 0.0;
      }

      final newDueAmount = totalDueNow - amountReceived;
      final newPaidAmount = planRate - newDueAmount;
      
      if (_paymentStatus == 'Received' && amountReceived > 0) {
        final payment = PaymentModel(
          id: 'temp',
          gymId: widget.member.gymId,
          memberId: widget.member.id,
          amount: amountReceived,
          paymentDate: now,
          paymentMethod: _paymentMethod,
          createdAt: now,
        );
        await repo.addPayment(payment);
      }

      final updatedMember = MemberModel(
        id: widget.member.id,
        gymId: widget.member.gymId,
        name: widget.member.name,
        phone: widget.member.phone,
        email: widget.member.email,
        membershipType: widget.member.membershipType,
        startDate: widget.member.startDate,
        expiryDate: newExpiry,
        trainerId: widget.member.trainerId,
        isActive: widget.member.isActive,
        createdAt: widget.member.createdAt,
        profilePhotoUrl: widget.member.profilePhotoUrl,
        gender: widget.member.gender,
        memberId: widget.member.memberId,
        monthlyPlanAmount: widget.member.monthlyPlanAmount,
        paymentDate: now,
        paidAmount: newPaidAmount,
        paymentMethod: _paymentStatus == 'Received' ? _paymentMethod : widget.member.paymentMethod,
        admissionFee: widget.member.admissionFee,
        dateOfBirth: widget.member.dateOfBirth,
        address: widget.member.address,
        isDeleted: widget.member.isDeleted,
        deletedAt: widget.member.deletedAt,
      );

      await repo.updateMember(updatedMember);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan renewed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
