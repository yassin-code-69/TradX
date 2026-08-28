import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/payment_method_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/payment_logos.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final AppState _appState = AppState();

  void _showAddEditMethodSheet({PaymentMethodModel? existingMethod}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddEditPaymentMethodSheet(
        existingMethod: existingMethod,
        onSave: (method) {
          if (existingMethod == null) {
            _appState.addSavedPaymentMethod(method);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method added successfully!')),
            );
          } else {
            _appState.updateSavedPaymentMethod(method);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method updated successfully!')),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(PaymentMethodModel method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Delete Payment Method',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${method.providerName} (${method.accountNumber})?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _appState.removeSavedPaymentMethod(method.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method deleted')),
              );
            },
            child: Text('DELETE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Methods',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _appState,
          builder: (context, _) {
            final savedMethods = _appState.savedPaymentMethods;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.goldPrimary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Saved withdrawal accounts are verified and protected with 256-bit bank-grade encryption.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Accounts (${savedMethods.length})',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.goldPrimary, size: 18),
                        label: Text(
                          'Add New',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        onPressed: () => _showAddEditMethodSheet(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (savedMethods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.credit_card_off_rounded, color: AppColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No Saved Payment Methods',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your bKash, Nagad, Rocket, or Bank account for 1-tap instant withdrawals.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            TradexButton(
                              text: 'ADD PAYMENT METHOD',
                              width: 220,
                              onPressed: () => _showAddEditMethodSheet(),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...savedMethods.map((method) => _buildMethodCard(method)),

                  const SizedBox(height: 24),

                  // Big Add Method Button
                  TradexButton(
                    text: 'ADD NEW PAYMENT METHOD',
                    icon: Icons.add_circle_outline_rounded,
                    width: double.infinity,
                    variant: TradexButtonVariant.outline,
                    onPressed: () => _showAddEditMethodSheet(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isDefault ? AppColors.goldPrimary : AppColors.cardBorder,
          width: method.isDefault ? 1.3 : 1.0,
        ),
        boxShadow: method.isDefault
            ? [
                BoxShadow(
                  color: AppColors.goldPrimary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider Badge / Logo
                _buildProviderBadge(method.provider),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.providerName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.accountNumber,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${method.accountHolderName} • ${method.accountType}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (method.bankName != null && method.bankName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${method.bankName} (${method.branchName ?? "Main Branch"})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!method.isDefault)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.goldPrimary),
                    label: Text(
                      'Set as Default',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldPrimary),
                    ),
                    onPressed: () {
                      _appState.setDefaultPaymentMethod(method.id);
                      HapticFeedback.lightImpact();
                    },
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Default Payout Method',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greenAccent),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Edit',
                      onPressed: () => _showAddEditMethodSheet(existingMethod: method),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.redAccent),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(method),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBadge(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.bkash:
        return const SizedBox(width: 48, height: 48, child: Center(child: BKashBadgeIcon(size: 36)));
      case PaymentProvider.nagad:
        return const SizedBox(width: 48, height: 48, child: Center(child: NagadBadgeIcon(size: 36)));
      case PaymentProvider.rocket:
        return const SizedBox(width: 48, height: 48, child: Center(child: RocketBadgeIcon(size: 36)));
      case PaymentProvider.bank:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cyanAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Icon(Icons.account_balance_rounded, color: AppColors.cyanAccent, size: 24),
          ),
        );
    }
  }
}

class _AddEditPaymentMethodSheet extends StatefulWidget {
  final PaymentMethodModel? existingMethod;
  final Function(PaymentMethodModel method) onSave;

  const _AddEditPaymentMethodSheet({
    this.existingMethod,
    required this.onSave,
  });

  @override
  State<_AddEditPaymentMethodSheet> createState() => _AddEditPaymentMethodSheetState();
}

class _AddEditPaymentMethodSheetState extends State<_AddEditPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  PaymentProvider _selectedProvider = PaymentProvider.nagad;
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();
  String _accountType = 'Personal';
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMethod != null) {
      final m = widget.existingMethod!;
      _selectedProvider = m.provider;
      _accountNumberController.text = m.accountNumber;
      _holderNameController.text = m.accountHolderName;
      _accountType = m.accountType;
      _bankNameController.text = m.bankName ?? '';
      _branchNameController.text = m.branchName ?? '';
      _routingNumberController.text = m.routingNumber ?? '';
      _isDefault = m.isDefault;
    } else {
      _holderNameController.text = AppState().currentUser.fullName;
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _holderNameController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final String providerName = _getProviderTitle(_selectedProvider);

    final method = PaymentMethodModel(
      id: widget.existingMethod?.id ?? 'method_${DateTime.now().millisecondsSinceEpoch}',
      provider: _selectedProvider,
      providerName: providerName,
      accountNumber: _accountNumberController.text.trim(),
      accountHolderName: _holderNameController.text.trim(),
      accountType: _accountType,
      bankName: _selectedProvider == PaymentProvider.bank ? _bankNameController.text.trim() : null,
      branchName: _selectedProvider == PaymentProvider.bank ? _branchNameController.text.trim() : null,
      routingNumber: _selectedProvider == PaymentProvider.bank ? _routingNumberController.text.trim() : null,
      isDefault: _isDefault,
    );

    widget.onSave(method);
    Navigator.pop(context);
  }

  String _getProviderTitle(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.bkash:
        return 'bKash';
      case PaymentProvider.nagad:
        return 'Nagad';
      case PaymentProvider.rocket:
        return 'Rocket';
      case PaymentProvider.bank:
        return 'Bank Account';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBank = _selectedProvider == PaymentProvider.bank;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existingMethod == null ? 'Add Payment Method' : 'Edit Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for instant draw prize withdrawals and payouts.',
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Provider Selector
              Text(
                'Select Provider',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProviderChip(PaymentProvider.nagad, 'নগদ'),
                  const SizedBox(width: 8),
                  _buildProviderChip(PaymentProvider.bkash, 'বিকাশ'),
                  const SizedBox(width: 8),
                  _buildProviderChip(PaymentProvider.rocket, 'Rocket'),
                  const SizedBox(width: 8),
                  _buildProviderChip(PaymentProvider.bank, 'Bank'),
                ],
              ),
              const SizedBox(height: 16),

              // Account Holder Name
              TradexTextField(
                controller: _holderNameController,
                label: 'Account Holder Name',
                hint: 'e.g. Shek Ahmmed',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account holder name' : null,
              ),
              const SizedBox(height: 14),

              // Account Number
              TradexTextField(
                controller: _accountNumberController,
                label: isBank ? 'Bank Account Number' : 'Mobile Number',
                hint: isBank ? 'e.g. 1102938475001' : 'e.g. 01712-345678',
                prefixIcon: isBank ? Icons.pin_outlined : Icons.phone_android_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter account number';
                  if (!isBank && v.replaceAll(RegExp(r'[^0-9]'), '').length < 11) {
                    return 'Please enter valid 11-digit Bangladeshi mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Account Type Selector
              Text(
                'Account Type',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['Personal', 'Agent', 'Corporate', 'Savings'].map((type) {
                  final isSelected = _accountType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _accountType = type),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Bank Specific Fields
              if (isBank) ...[
                TradexTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'e.g. City Bank / Dutch-Bangla / BRAC',
                  prefixIcon: Icons.account_balance_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter bank name' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TradexTextField(
                        controller: _branchNameController,
                        label: 'Branch Name',
                        hint: 'e.g. Gulshan',
                        prefixIcon: Icons.location_city_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter branch' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TradexTextField(
                        controller: _routingNumberController,
                        label: 'Routing Number',
                        hint: 'e.g. 225271829',
                        prefixIcon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Set as default switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Set as Default Payout Method',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                subtitle: Text(
                  'Withdrawals will automatically be sent to this account',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                value: _isDefault,
                activeThumbColor: AppColors.goldPrimary,
                onChanged: (val) => setState(() => _isDefault = val),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              TradexButton(
                text: widget.existingMethod == null ? 'SAVE PAYMENT METHOD' : 'UPDATE METHOD',
                width: double.infinity,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderChip(PaymentProvider provider, String label) {
    final isSelected = _selectedProvider == provider;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedProvider = provider),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.goldLight : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
