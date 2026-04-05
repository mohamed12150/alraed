import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../../logic/providers/language_provider.dart';
import '../../../logic/providers/theme_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../screens/privacy_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _showLogoutDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
          content: Text(
            isArabic
                ? 'هل أنت متأكد من تسجيل الخروج؟'
                : 'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.read<AuthProvider>().logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'حذف الحساب نهائياً' : 'Delete Account Permanently',
            style: const TextStyle(color: Colors.red),
          ),
          content: Text(
            isArabic
                ? 'تحذير: سيتم حذف جميع بياناتك وطلباتك نهائياً من النظام. هل أنت متأكد؟'
                : 'Warning: All your data and orders will be permanently deleted from the system. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.read<AuthProvider>().deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(isArabic ? 'حذف الحساب' : 'Delete Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        authProvider.fetchProfile();
      }
    });

    return Consumer3<LanguageProvider, ThemeProvider, AuthProvider>(
      builder: (context, languageProvider, themeProvider, authProvider, child) {
        final isArabic = languageProvider.isArabic;

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isArabic ? 'حسابي' : 'Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.global),
                  onPressed: () {
                    languageProvider.toggleLanguage();
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Iconsax.user,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.isLoggedIn
                                      ? (authProvider.user?.name ??
                                            (isArabic ? 'مستخدم' : 'User'))
                                      : (isArabic ? 'زائر' : 'Guest'),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  authProvider.isLoggedIn
                                      ? (authProvider.user?.phone ??
                                          (isArabic
                                              ? 'بدون رقم محفوظ'
                                              : 'No phone saved'))
                                      : (isArabic
                                            ? 'سجل دخولك للمزيد من الميزات'
                                            : 'Login for more features'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (authProvider.isLoggedIn)
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic ? 'قريباً!' : 'Coming soon!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Iconsax.edit),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!authProvider.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => context.push('/auth'),
                          child: Text(
                            isArabic
                                ? 'تسجيل الدخول / إنشاء حساب'
                                : 'Login / Sign Up',
                          ),
                        ),
                      ),
                    ),

                  // Menu Items
                  _buildMenuSection(context, isArabic, [
                    _ProfileMenuData(
                      icon: Iconsax.receipt_item,
                      title: isArabic ? 'طلباتي' : 'My Orders',
                      onTap: () {
                        context.push('/orders');
                      },
                    ),
                    _ProfileMenuData(
                      icon: Iconsax.card,
                      title: isArabic ? 'طرق الدفع' : 'Payment Methods',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic ? 'قريباً' : 'Coming Soon'),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Settings Section
                  _buildMenuSection(context, isArabic, [
                    _ProfileMenuData(
                      icon: themeProvider.isDarkMode
                          ? Iconsax.moon
                          : Iconsax.sun_1,
                      title: isArabic ? 'الوضع المظلم' : 'Dark Mode',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                        activeThumbColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    _ProfileMenuData(
                      icon: Iconsax.global,
                      title: isArabic ? 'اللغة' : 'Language',
                      subtitle: isArabic ? 'العربية' : 'English',
                      onTap: () => languageProvider.toggleLanguage(),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Support Section
                  _buildMenuSection(context, isArabic, [
                    _ProfileMenuData(
                      icon: Iconsax.message_question,
                      title: isArabic ? 'المساعدة والدعم' : 'Help & Support',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isArabic ? 'الدعم الفني' : 'Support'),
                            content: Text(
                              isArabic
                                  ? 'يمكنك التواصل معنا عبر البريد: zbihacompany@gmail.com'
                                  : 'Contact us via email: zbihacompany@gmail.com',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(isArabic ? 'إغلاق' : 'Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _ProfileMenuData(
                      icon: Iconsax.lock,
                      title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuData(
                      icon: Iconsax.info_circle,
                      title: isArabic ? 'عن التطبيق' : 'About App',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isArabic ? 'عن التطبيق' : 'About App'),
                            content: Text(
                              isArabic
                                  ? 'الرائد للذبائح تطبيق لطلب الذبائح واللحوم الطازجة وتوصيلها بسهولة إلى باب منزلك.'
                                  : 'Al Raed Dhabaeh is an app to order fresh meat and have it delivered easily to your door.',
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(isArabic ? 'إغلاق' : 'Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (authProvider.isLoggedIn)
                      _ProfileMenuData(
                        icon: Iconsax.trash,
                        title: isArabic ? 'حذف الحساب' : 'Delete Account',
                        textColor: Colors.red,
                        onTap: () => _showDeleteAccountDialog(context, isArabic),
                      ),
                  ]),

                  if (authProvider.isLoggedIn) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context, isArabic),
                        icon: const Icon(Iconsax.logout, color: Colors.red),
                        label: Text(
                          isArabic ? 'تسجيل الخروج' : 'Logout',
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  Text(
                    isArabic ? 'إصدار 1.0.0' : 'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isArabic,
    List<_ProfileMenuData> items,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  item.icon,
                  color: item.textColor ?? Theme.of(context).primaryColor,
                  size: 22,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: item.textColor,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(item.subtitle!, style: const TextStyle(fontSize: 12))
                    : null,
                trailing:
                    item.trailing ??
                    Icon(
                      isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                      size: 14,
                      color: item.textColor,
                    ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 50,
                  endIndent: 20,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileMenuData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? textColor;
  final VoidCallback? onTap;

  _ProfileMenuData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.textColor,
    this.onTap,
  });
}
