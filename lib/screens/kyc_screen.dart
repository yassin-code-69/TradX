import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/kyc_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class KycScreen extends StatefulWidget {
  final bool forceStartVerification;

  const KycScreen({
    super.key,
    this.forceStartVerification = false,
  });

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final AppState _appState = AppState();

  // Multi-step index: 0 = Personal Info, 1 = Document Type, 2 = Photo Upload, 3 = Selfie Liveness, 4 = Review & Submit
  int _currentStep = 0;
  bool _isVerifyingMode = false;
  bool _isSubmitting = false;

  // Step 1: Personal Info form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedGender = 'Male';

  // Step 2: Document Type
  DocumentType _selectedDocType = DocumentType.nid;

  // Step 3: Photo Upload simulation
  bool _frontPhotoUploaded = false;
  bool _backPhotoUploaded = false;
  String _frontPhotoName = '';
  String _backPhotoName = '';

  // Step 4: Selfie Liveness simulation
  bool _selfieCaptured = false;
  bool _isCapturingSelfie = false;

  // Step 5: Agreement
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    final currentUser = _appState.currentUser;
    _fullNameController.text = currentUser.fullName;
    _dobController.text = '1995-04-12';
    _docNumberController.text = '19952837461928374';
    _addressController.text = 'House 14, Road 5, Dhanmondi, Dhaka';

    if (widget.forceStartVerification || _appState.kyc.isNotSubmitted) {
      _isVerifyingMode = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _docNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_frontPhotoUploaded || (!_backPhotoUploaded && _selectedDocType != DocumentType.passport)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redAccent,
            content: Text(
              _selectedDocType == DocumentType.passport
                  ? 'Please upload the main page photo of your Passport'
                  : 'Please upload both front and back photos of your ID document',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (!_selfieCaptured) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redAccent,
            content: Text(
              'Please complete the face liveness selfie capture',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitKycVerification() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text(
            'Please confirm that the provided information is authentic',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 1400));

    _appState.submitKyc(
      documentType: _selectedDocType,
      documentNumber: _docNumberController.text.trim(),
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      frontImageUrl: 'simulated_front_id.jpg',
      backImageUrl: 'simulated_back_id.jpg',
      selfieImageUrl: 'simulated_selfie.jpg',
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isVerifyingMode = false;
    });

    _showSubmissionSuccessDialog();
  }

  void _showSubmissionSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.goldPrimary, width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.goldPrimary, size: 54),
            ),
            const SizedBox(height: 18),
            Text(
              'KYC Submitted!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your identification documents have been received. Our compliance team will review them within 2 to 4 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TradexButton(
              text: 'VIEW STATUS',
              width: double.infinity,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
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
          'Identity Verification (KYC)',
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
            final kyc = _appState.kyc;

            if (!_isVerifyingMode && !kyc.isNotSubmitted) {
              return _buildKycStatusView(kyc);
            }

            return _buildVerificationWorkflow();
          },
        ),
      ),
    );
  }

  // --- KYC STATUS TRACKING VIEW ---
  Widget _buildKycStatusView(KycModel kyc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header Card
          _buildStatusBanner(kyc),

          const SizedBox(height: 20),

          // Identity Details Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, color: AppColors.goldPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Submitted Information',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 14),
                _buildInfoRow('Legal Name', kyc.fullName ?? _appState.currentUser.fullName),
                _buildInfoRow('Document Type', _formatDocType(kyc.documentType ?? DocumentType.nid)),
                _buildInfoRow('Document Number', kyc.documentNumber ?? 'NID-9482938472'),
                _buildInfoRow('Date of Birth', kyc.dateOfBirth ?? '1995-04-12'),
                _buildInfoRow('Country / Region', 'Bangladesh'),
                _buildInfoRow(
                  'Submitted Date',
                  kyc.submittedAt != null
                      ? '${kyc.submittedAt!.day}/${kyc.submittedAt!.month}/${kyc.submittedAt!.year}'
                      : '26 Aug 2026',
                ),
                if (kyc.isVerified)
                  _buildInfoRow('Verification Level', 'Tier 2 (Full Access & Unlimited Withdrawals)'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Benefits Card
          GlassCard(
            borderColor: AppColors.goldPrimary.withValues(alpha: 0.3),
            backgroundColor: AppColors.cardBgElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.greenAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Account Limits & Perks',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBenefitItem('Instant High-Speed Withdrawals (bKash, Nagad, Rocket, Bank)'),
                _buildBenefitItem('Unlimited Daily Winning Payouts up to ৳ 50,00,000'),
                _buildBenefitItem('Eligible for VIP Draws & Exclusive Mega Jackpots'),
                _buildBenefitItem('24/7 Priority VIP Concierge Support'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action button if rejected or wants to resubmit
          if (kyc.isRejected || kyc.isPending) ...[
            if (kyc.isRejected)
              TradexButton(
                text: 'RESUBMIT KYC DOCUMENTS',
                width: double.infinity,
                variant: TradexButtonVariant.primaryGold,
                onPressed: () {
                  setState(() {
                    _isVerifyingMode = true;
                    _currentStep = 0;
                  });
                },
              )
            else
              TradexButton(
                text: 'UPDATE DETAILS',
                width: double.infinity,
                variant: TradexButtonVariant.outline,
                onPressed: () {
                  setState(() {
                    _isVerifyingMode = true;
                    _currentStep = 0;
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(KycModel kyc) {
    Color bannerBg;
    Color borderColor;
    IconData icon;
    String title;
    String desc;

    if (kyc.isVerified) {
      bannerBg = AppColors.greenBg;
      borderColor = AppColors.greenAccent.withValues(alpha: 0.6);
      icon = Icons.check_circle_rounded;
      title = 'KYC VERIFIED';
      desc = 'Your identity is fully verified. You enjoy unlocked withdrawal limits and VIP draw access.';
    } else if (kyc.isPending) {
      bannerBg = const Color(0xFF2C220E);
      borderColor = AppColors.goldPrimary.withValues(alpha: 0.6);
      icon = Icons.hourglass_top_rounded;
      title = 'UNDER REVIEW';
      desc = 'Your documents are being reviewed by our verification team. Estimated wait: 2-4 Hours.';
    } else if (kyc.isRejected) {
      bannerBg = AppColors.redBg;
      borderColor = AppColors.redAccent.withValues(alpha: 0.6);
      icon = Icons.cancel_rounded;
      title = 'VERIFICATION REJECTED';
      desc = kyc.rejectionReason ?? 'Document photo was blurry or obscured. Please resubmit with clear photos.';
    } else {
      bannerBg = AppColors.cardBgElevated;
      borderColor = AppColors.cardBorder;
      icon = Icons.info_outline_rounded;
      title = 'NOT SUBMITTED';
      desc = 'Please complete KYC verification to unlock full withdrawals and VIP draws.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: borderColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MULTI-STEP VERIFICATION WORKFLOW ---
  Widget _buildVerificationWorkflow() {
    return Column(
      children: [
        // Progress Steps Indicator
        _buildStepsIndicator(),

        // Step Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildCurrentStepContent(),
          ),
        ),

        // Bottom Navigation Buttons
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildStepsIndicator() {
    final steps = ['Info', 'Doc Type', 'Upload', 'Liveness', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.greenAccent
                              : isCurrent
                                  ? AppColors.goldPrimary
                                  : AppColors.cardBorder,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.black, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? Colors.black : AppColors.textMuted,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.goldLight
                              : isCompleted
                                  ? AppColors.greenAccent
                                  : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    color: isCompleted ? AppColors.greenAccent : AppColors.divider,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2DocumentType();
      case 2:
        return _buildStep3DocumentUpload();
      case 3:
        return _buildStep4SelfieLiveness();
      case 4:
        return _buildStep5ReviewSubmit();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Personal Info
  Widget _buildStep1PersonalInfo() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Personal Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please ensure your name and details match your government-issued ID card.',
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Legal Name
          TradexTextField(
            controller: _fullNameController,
            label: 'Legal Full Name (as on ID)',
            hint: 'e.g. Shek Ahmmed',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your legal name' : null,
          ),
          const SizedBox(height: 14),

          // Date of Birth
          TradexTextField(
            controller: _dobController,
            label: 'Date of Birth (YYYY-MM-DD)',
            hint: '1995-04-12',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.datetime,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter date of birth' : null,
          ),
          const SizedBox(height: 14),

          // Gender Selector
          Text(
            'Gender',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Male', 'Female', 'Other'].map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGender = gender),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          gender,
                          style: GoogleFonts.inter(
                            fontSize: 13,
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

          // ID Number
          TradexTextField(
            controller: _docNumberController,
            label: 'National ID / Passport / DL Number',
            hint: 'e.g. 19952837461928374',
            prefixIcon: Icons.pin_outlined,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter ID number' : null,
          ),
          const SizedBox(height: 14),

          // Address
          TradexTextField(
            controller: _addressController,
            label: 'Residential Address',
            hint: 'House, Road, City, Division',
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your address' : null,
          ),
        ],
      ),
    );
  }

  // STEP 2: Document Type Selection
  Widget _buildStep2DocumentType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Choose Document Type',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the identification document you want to upload for verification.',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        _buildDocTypeOption(
          type: DocumentType.nid,
          title: 'National Identity Card (NID)',
          subtitle: 'Smart NID or Traditional laminated Bangladeshi NID card',
          icon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocTypeOption(
          type: DocumentType.passport,
          title: 'International Passport',
          subtitle: 'Valid machine-readable or e-Passport (Biodata page)',
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocTypeOption(
          type: DocumentType.drivingLicense,
          title: 'Driving License',
          subtitle: 'BRTA Smart Card Driving License (Front & Back)',
          icon: Icons.drive_eta_rounded,
        ),
      ],
    );
  }

  Widget _buildDocTypeOption({
    required DocumentType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedDocType == type;

    return GlassCard(
      onTap: () => setState(() => _selectedDocType = type),
      borderColor: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
      backgroundColor: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.08) : AppColors.cardBg,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.2) : AppColors.cardBgElevated,
            ),
            child: Icon(icon, color: isSelected ? AppColors.goldPrimary : AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.goldLight : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.goldPrimary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.goldPrimary : AppColors.cardBorderHighlight,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Color(0xFF0F111A))
                : null,
          ),
        ],
      ),
    );
  }

  // STEP 3: Document Photo Upload
  Widget _buildStep3DocumentUpload() {
    final isPassport = _selectedDocType == DocumentType.passport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Upload Document Photos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ensure the document is well lit, fully in frame, and all text is sharply readable.',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Front Photo Box
        _buildUploadBox(
          label: isPassport ? 'Passport Biodata Page' : 'Front Side of ID',
          isUploaded: _frontPhotoUploaded,
          fileName: _frontPhotoName,
          onTap: () {
            setState(() {
              _frontPhotoUploaded = true;
              _frontPhotoName = isPassport ? 'passport_bio_scan.jpg' : 'nid_front_photo.jpg';
            });
            HapticFeedback.lightImpact();
          },
          onRetake: () {
            setState(() {
              _frontPhotoUploaded = false;
              _frontPhotoName = '';
            });
          },
        ),

        const SizedBox(height: 16),

        // Back Photo Box (if not passport)
        if (!isPassport) ...[
          _buildUploadBox(
            label: 'Back Side of ID',
            isUploaded: _backPhotoUploaded,
            fileName: _backPhotoName,
            onTap: () {
              setState(() {
                _backPhotoUploaded = true;
                _backPhotoName = 'nid_back_photo.jpg';
              });
              HapticFeedback.lightImpact();
            },
            onRetake: () {
              setState(() {
                _backPhotoUploaded = false;
                _backPhotoName = '';
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Guidelines Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Requirements:',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 6),
              _buildGuidelineRow('Supported formats: JPG, PNG, WEBP (Max 5MB)'),
              _buildGuidelineRow('No glare, shadows or flash reflection on text'),
              _buildGuidelineRow('All 4 corners of document must be fully visible'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String label,
    required bool isUploaded,
    required String fileName,
    required VoidCallback onTap,
    required VoidCallback onRetake,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploaded ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.greenBg.withValues(alpha: 0.5) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUploaded ? AppColors.greenAccent : AppColors.cardBorderHighlight,
                width: 1.2,
              ),
            ),
            child: isUploaded
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.greenAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.greenAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Uploaded • 2.4 MB',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.greenLight),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                        tooltip: 'Retake',
                        onPressed: onRetake,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.goldPrimary, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to Capture / Choose Photo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Camera or Gallery',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: Selfie Liveness Simulation
  Widget _buildStep4SelfieLiveness() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Selfie Liveness Check',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Position your face inside the oval frame to verify you are the document holder.',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Simulated Camera Oval Frame
        Center(
          child: Container(
            width: 220,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(120),
              color: AppColors.cardBgElevated,
              border: Border.all(
                color: _selfieCaptured ? AppColors.greenAccent : AppColors.goldPrimary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_selfieCaptured ? AppColors.greenAccent : AppColors.goldPrimary).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCapturingSelfie) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                  ),
                ] else if (_selfieCaptured) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.face_retouching_natural_rounded, color: AppColors.greenAccent, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'Face Verified',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Liveness 100% Match',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.greenLight),
                      ),
                    ],
                  ),
                ] else ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.face_unlock_rounded, color: AppColors.goldPrimary, size: 68),
                      const SizedBox(height: 14),
                      Text(
                        'Center Your Face',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blink or Smile',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Capture / Retake Button
        Center(
          child: TradexButton(
            text: _selfieCaptured ? 'RETAKE SELFIE' : 'CAPTURE LIVE SELFIE',
            icon: Icons.camera_alt_rounded,
            variant: _selfieCaptured ? TradexButtonVariant.outline : TradexButtonVariant.primaryGold,
            width: 260,
            onPressed: () async {
              setState(() => _isCapturingSelfie = true);
              HapticFeedback.heavyImpact();
              await Future.delayed(const Duration(milliseconds: 900));
              if (!mounted) return;
              setState(() {
                _isCapturingSelfie = false;
                _selfieCaptured = true;
              });
            },
          ),
        ),

        const SizedBox(height: 20),

        // Tips
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.goldPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Make sure your face is in natural light and you are not wearing sunglasses or caps.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: Review & Submit
  Widget _buildStep5ReviewSubmit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5: Review & Submit',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please verify all details before submitting for official compliance review.',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Summary',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),
              _buildInfoRow('Legal Name', _fullNameController.text.trim()),
              _buildInfoRow('Date of Birth', _dobController.text.trim()),
              _buildInfoRow('Gender', _selectedGender),
              _buildInfoRow('Document Type', _formatDocType(_selectedDocType)),
              _buildInfoRow('Document ID', _docNumberController.text.trim()),
              _buildInfoRow('Address', _addressController.text.trim()),
              _buildInfoRow('ID Front Scan', _frontPhotoName.isNotEmpty ? _frontPhotoName : 'Uploaded ✓'),
              if (_selectedDocType != DocumentType.passport)
                _buildInfoRow('ID Back Scan', _backPhotoName.isNotEmpty ? _backPhotoName : 'Uploaded ✓'),
              _buildInfoRow('Liveness Selfie', 'Verified 100% ✓'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Terms Agreement Checkbox
        CheckboxListTile(
          value: _agreedToTerms,
          activeColor: AppColors.goldPrimary,
          checkColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I certify under penalty of perjury that the information and documents provided are authentic, true, and belong to me.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: TradexButton(
                text: 'BACK',
                variant: TradexButtonVariant.outline,
                onPressed: _prevStep,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: TradexButton(
              text: _currentStep == 4 ? 'SUBMIT KYC' : 'CONTINUE',
              isLoading: _isSubmitting,
              onPressed: _currentStep == 4 ? _submitKycVerification : _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDocType(DocumentType type) {
    switch (type) {
      case DocumentType.nid:
        return 'National ID (NID)';
      case DocumentType.passport:
        return 'International Passport';
      case DocumentType.drivingLicense:
        return 'Driving License';
    }
  }
}
