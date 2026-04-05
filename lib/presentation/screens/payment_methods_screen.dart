import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../logic/providers/language_provider.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _cards = [
    {
      'type': 'Visa',
      'number': '**** **** **** 4242',
      'expiry': '12/25',
      'holder': 'Mohamed Ahmed',
    },
    {
      'type': 'Mastercard',
      'number': '**** **** **** 5555',
      'expiry': '10/24',
      'holder': 'Mohamed Ahmed',
    },
  ];

  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _showAddCardSheet(BuildContext context, bool isArabic) {
    _holderController.clear();
    _numberController.clear();
    _expiryController.clear();
    _cvvController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'إضافة بطاقة جديدة' : 'Add New Card',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: isArabic ? 'اسم حامل البطاقة' : 'Card Holder Name',
                icon: Iconsax.user,
                isArabic: isArabic,
                controller: _holderController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: isArabic ? 'رقم البطاقة' : 'Card Number',
                icon: Iconsax.card,
                isArabic: isArabic,
                keyboardType: TextInputType.number,
                controller: _numberController,
                hint: '**** **** **** ****',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: isArabic ? 'تاريخ الانتهاء' : 'Expiry Date',
                      icon: Iconsax.calendar,
                      isArabic: isArabic,
                      hint: 'MM/YY',
                      controller: _expiryController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'CVV',
                      icon: Iconsax.lock,
                      isArabic: isArabic,
                      keyboardType: TextInputType.number,
                      controller: _cvvController,
                      hint: '***',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_holderController.text.isEmpty || 
                        _numberController.text.isEmpty || 
                        _expiryController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isArabic ? 'يرجى ملء البيانات المطلوبة' : 'Please fill required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      // Determine type based on first digit (simple simulation)
                      String type = _numberController.text.startsWith('4') ? 'Visa' : 'Mastercard';
                      
                      // Format number to show only last 4 digits
                      String fullNumber = _numberController.text.replaceAll(' ', '');
                      String lastFour = fullNumber.length >= 4 
                          ? fullNumber.substring(fullNumber.length - 4) 
                          : fullNumber;
                      String maskedNumber = '**** **** **** $lastFour';

                      _cards.add({
                        'type': type,
                        'number': maskedNumber,
                        'expiry': _expiryController.text,
                        'holder': _holderController.text,
                      });
                    });

                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabic ? 'تمت إضافة البطاقة بنجاح' : 'Card added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(isArabic ? 'حفظ البطاقة' : 'Save Card'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required bool isArabic,
    String? hint,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'طرق الدفع' : 'Payment Methods'),
          leading: IconButton(
            icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              isArabic ? 'بطاقاتك المحفوظة' : 'Your Saved Cards',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._cards.map((card) => _buildCreditCard(card, theme, isArabic)),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _showAddCardSheet(context, isArabic),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.5),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.add_circle, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      isArabic ? 'إضافة بطاقة دفع جديدة' : 'Add New Payment Card',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              isArabic ? 'طرق دفع أخرى' : 'Other Payment Methods',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOtherMethod(
              title: isArabic ? 'أبل باي' : 'Apple Pay',
              icon: Icons.apple,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildOtherMethod(
              title: isArabic ? 'مدى' : 'Mada',
              icon: Iconsax.wallet_1,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(Map<String, String> card, ThemeData theme, bool isArabic) {
    final isVisa = card['type'] == 'Visa';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVisa 
              ? [const Color(0xFF1A237E), const Color(0xFF3949AB)]
              : [const Color(0xFF37474F), const Color(0xFF546E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card['type']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Icon(Iconsax.card, color: Colors.white70, size: 28),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            card['number']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'حامل البطاقة' : 'CARD HOLDER',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                  Text(
                    card['holder']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تنتهي في' : 'EXPIRES',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                  Text(
                    card['expiry']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMethod({required String title, required IconData icon, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
