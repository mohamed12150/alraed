import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../logic/providers/language_provider.dart';
import '../../../logic/providers/shop_provider.dart';
import '../../../logic/providers/location_provider.dart';
import '../../../logic/providers/notifications_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../models/product.dart';
import '../../../models/banner.dart' as banner_model;
import '../../widgets/shimmer_loading.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _categoryTabController;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 5, vsync: this);

    // Auto-scroll banners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerTimer();
      context.read<LocationProvider>().determinePosition();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        final notifProvider = context.read<NotificationsProvider>();
        notifProvider.fetchNotifications(authProvider.user!.id);
        notifProvider.subscribeRealtime(authProvider.user!.id);
      }
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        final shopProvider = context.read<ShopProvider>();
        if (shopProvider.banners.isEmpty) return;

        final nextPage = (_bannerController.page?.round() ?? 0) + 1;
        _bannerController.animateToPage(
          nextPage % shopProvider.banners.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryTabController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final shopProvider = context.watch<ShopProvider>();
    final isArabic = languageProvider.isArabic;
    final theme = Theme.of(context);
    final isLoading = shopProvider.isLoading;

    // Filter products based on search query
    final allProducts = shopProvider.products;
    final filteredProducts = _searchQuery.isEmpty
        ? allProducts
        : allProducts.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.title.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query);
          }).toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(child: _buildHeader(isArabic, theme)),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Banners Section
            if (shopProvider.banners.isNotEmpty && _searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: _buildBanners(shopProvider.banners, theme),
              ),

            if (shopProvider.banners.isNotEmpty && _searchQuery.isEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Trending Section
            if (_searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  isArabic ? 'الأكثر طلباً' : 'Trending Now',
                  isArabic ? 'عرض الكل' : 'View All',
                  theme,
                  () {
                    context.pushNamed(
                      'product-list',
                      pathParameters: {'type': 'trending'},
                      extra: {
                        'title': isArabic ? 'الأكثر طلباً' : 'Trending Now',
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: (isLoading && shopProvider.trendingProducts.isEmpty)
                    ? ShimmerLoading(
                        child: SizedBox(
                          height: 260,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) =>
                                const ProductHorizontalShimmer(),
                          ),
                        ),
                      )
                    : _buildHorizontalList(
                        shopProvider.trendingProducts.take(5).toList(),
                        theme,
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

            // Special Offers Section
            if ((shopProvider.discountedProducts.isNotEmpty || isLoading) &&
                _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  isArabic ? 'عروض مميزة' : 'Special Offers',
                  isArabic ? 'عرض الكل' : 'View All',
                  theme,
                  () {
                    context.pushNamed(
                      'product-list',
                      pathParameters: {'type': 'discounted'},
                      extra: {
                        'title': isArabic ? 'عروض مميزة' : 'Special Offers',
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: (isLoading && shopProvider.discountedProducts.isEmpty)
                    ? ShimmerLoading(
                        child: SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.9),
                            itemCount: 3,
                            itemBuilder: (context, index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _buildOffersList(shopProvider.discountedProducts, theme),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

            // Endless Journey Section
            if (_searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isArabic ? 'رحلة في عالم اللحوم' : 'Endless Meat Journey',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: (isLoading && shopProvider.categories.isEmpty)
                    ? ShimmerLoading(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: List.generate(
                              4,
                              (index) => const CategoryShimmer(),
                            ),
                          ),
                        ),
                      )
                    : _buildCategoryTabs(isArabic, shopProvider, theme),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Vertical List using SliverList for better performance
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ShimmerLoading(
                          child: ProductVerticalShimmer(),
                        ),
                        childCount: 5,
                      ),
                    )
                  : filteredProducts.isEmpty && _searchQuery.isNotEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.search_status,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isArabic ? 'لا توجد نتائج' : 'No results found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildVerticalItem(
                          filteredProducts[index],
                          theme,
                        );
                      }, childCount: filteredProducts.length),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic, ThemeData theme) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => locationProvider.determinePosition(),
                child: Row(
                  children: [
                    const Icon(Iconsax.location, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationProvider.isLoading
                            ? (isArabic ? 'جاري تحديد الموقع...' : 'Getting location...')
                            : (locationProvider.currentAddress.isNotEmpty
                                ? '${isArabic ? 'التوصيل إلى: ' : 'Deliver to: '}${locationProvider.currentAddress}'
                                : (isArabic ? 'اضغط لتحديد الموقع' : 'Tap to set location')),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    // Bell icon
                    Consumer<NotificationsProvider>(
                      builder: (context, notifProvider, _) {
                        final unread = notifProvider.unreadCount;
                        return GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Iconsax.notification, color: Colors.white, size: 24),
                              if (unread > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'أهلاً بك!' : 'Hello Meat Lover!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'ذبيحة كاملة أو مقطعة حسب طلبك'
                    : 'Whole carcass or cut to order',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.white
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: isArabic ? 'ابحث عن نوع اللحم...' : 'Search meat...',
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    fillColor: Colors
                        .transparent, // Overriding the theme's fillColor for this specific case
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanners(List<banner_model.Banner> banners, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: banner.image.startsWith('http')
                        ? NetworkImage(banner.image)
                        : AssetImage(banner.image) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? banner.titleAr
                            : banner.titleEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _bannerController,
          count: banners.length,
          effect: ExpandingDotsEffect(
            activeDotColor: theme.primaryColor,
            dotColor: theme.disabledColor.withOpacity(0.2),
            dotHeight: 8,
            dotWidth: 8,
            spacing: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action,
    ThemeData theme,
    VoidCallback? onActionTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: onActionTap,
            child: Text(
              action,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Product> products, ThemeData theme) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.light ? 0.05 : 0.2,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pushNamed(
                  'product',
                  pathParameters: {'id': product.id},
                  extra: product,
                ),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(
                              product.imageUrl,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 110,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            )
                          : Image.asset(
                              product.imageUrl,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.rating.toString(),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (product.discountPrice != null &&
                                        product.discountPrice! > 0) ...[
                                      Text(
                                        product.discountPrice!.toStringAsFixed(
                                          0,
                                        ),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.price.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        product.price.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Image.asset(
                                      'assets/images/sar.png',
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersList(List<Product> products, ThemeData theme) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return GestureDetector(
            onTap: () {
              context.pushNamed(
                'product',
                pathParameters: {'id': product.id},
                extra: product,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: product.imageUrl.startsWith('http')
                      ? NetworkImage(product.imageUrl)
                      : AssetImage(product.imageUrl) as ImageProvider,
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.discountPrice!.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/sar.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.price.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white,
                            fontSize: 14,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isArabic ? 'اطلب الآن' : 'Order Now',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(
    bool isArabic,
    ShopProvider shopProvider,
    ThemeData theme,
  ) {
    final categories = shopProvider.categories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = shopProvider.selectedCategoryId == category.id;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                selected: isSelected,
                label: Text(isArabic ? category.nameAr : category.nameEn),
                onSelected: (selected) {
                  shopProvider.selectCategory(category.id);
                },
                backgroundColor: theme.cardColor,
                selectedColor: theme.primaryColor.withOpacity(0.2),
                checkmarkColor: theme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.primaryColor
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVerticalItem(Product product, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF8F8F8)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(
            'product',
            pathParameters: {'id': product.id},
            extra: product,
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product.imageUrl.startsWith('http')
                      ? Image.network(
                          product.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                        )
                      : Image.asset(
                          product.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (product.discountPrice != null &&
                              product.discountPrice! > 0) ...[
                            Text(
                              product.discountPrice!.toStringAsFixed(0),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.price.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                          ] else
                            Text(
                              product.price.toStringAsFixed(0),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/sar.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
