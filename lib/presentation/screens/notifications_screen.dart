import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../logic/providers/notifications_provider.dart';
import '../../logic/providers/language_provider.dart';
import '../../logic/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        final notifProvider = context.read<NotificationsProvider>();
        notifProvider.fetchNotifications(authProvider.user!.id).then((_) {
          notifProvider.markAllAsRead(authProvider.user!.id);
        });
      }
    });
  }

  String _timeAgo(DateTime date, bool isArabic) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) return isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final notifications = context.watch<NotificationsProvider>().notifications;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'الإشعارات' : 'Notifications'),
          leading: IconButton(
            icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.notification, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'لا توجد إشعارات' : 'No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final title = isArabic ? n.titleAr : (n.titleEn.isNotEmpty ? n.titleEn : n.titleAr);
                  final body = isArabic ? n.bodyAr : (n.bodyEn.isNotEmpty ? n.bodyEn : n.bodyAr);

                  return Container(
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Theme.of(context).cardColor
                          : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.isRead
                            ? Theme.of(context).dividerColor.withValues(alpha: 0.1)
                            : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.notification, color: Theme.of(context).primaryColor, size: 20),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: body.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(body, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            )
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _timeAgo(n.createdAt, isArabic),
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                          if (!n.isRead) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
