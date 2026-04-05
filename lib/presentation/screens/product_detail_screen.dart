import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/product.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/language_provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  String? selectedWeight;
  String? selectedOption;
  int quantity = 1;
  bool isExpanded = false;

  List<String> _availableWeights = [];
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _cuttingMethods = [];

  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Initialize available weights
    if (widget.product.weights.isNotEmpty) {
      _availableWeights = widget.product.weights;
      selectedWeight = _availableWeights.first;
    } else {
      // Try to extract weight from title
      final weightRegex = RegExp(r'\((.*?)\)');
      final match = weightRegex.firstMatch(widget.product.title);
      if (match != null) {
        _availableWeights = [match.group(1)!];
        selectedWeight = _availableWeights.first;
      } else {
        _availableWeights = ["Standard"];
        selectedWeight = "Standard";
      }
    }
    if (widget.product.options.isNotEmpty) {
      selectedOption = widget.product.options.first;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    final supabase = SupabaseService();
    try {
      final results = await Future.wait([
        supabase.getProductVariants(widget.product.id),
        supabase.getProductCuttingMethods(widget.product.id),
      ]);
      if (mounted) {
        // debugPrint('Loaded variants: ${results[0]}');
        // debugPrint('Loaded cutting methods: ${results[1]}');
        setState(() {
          _variants = results[0];
          _cuttingMethods = results[1];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading product data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    if (_isLoadingData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'جاري تحميل البيانات، يرجى الانتظار...'
                : 'Loading data, please wait...',
          ),
        ),
      );
      return;
    }

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'يرجى تسجيل الدخول أولاً لإضافة منتجات للسلة'
                : 'Please login first to add products to cart',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      context.push('/auth');
      return;
    }

    if (selectedWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'يرجى اختيار الوزن'
                : 'Please select a weight',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.product.options.isNotEmpty && selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isArabic
                ? 'يرجى اختيار طريقة التقطيع'
                : 'Please select a cutting method',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Ensure we have the necessary data to resolve IDs
    if ((selectedWeight != null && _variants.isEmpty) ||
        (selectedOption != null && _cuttingMethods.isEmpty)) {
      await _loadData();
      if (_variants.isEmpty && _cuttingMethods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isArabic
                  ? 'فشل تحميل تفاصيل المنتج. يرجى المحاولة مرة أخرى.'
                  : 'Failed to load product details. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    String? variantId;
    if (selectedWeight != null && _variants.isNotEmpty) {
      try {
        final variant = _variants.firstWhere(
          (v) =>
              v['attributes'] != null &&
              v['attributes']['weight'] == selectedWeight,
        );
        variantId = variant['id'];
      } catch (_) {}
    }

    int? cuttingMethodId;
    if (selectedOption != null) {
      if (_cuttingMethods.isNotEmpty) {
        try {
          final cm = _cuttingMethods.firstWhere((c) {
            final method = c['cutting_methods'] ?? c['cutting_method'];
            if (method == null) return false;
            final nameAr = method['name_ar']?.toString().trim();
            final nameEn = method['name_en']?.toString().trim();
            final selected = selectedOption!.trim();

            // Debug check for mismatch
            // debugPrint('Checking "$selected" against "$nameAr" / "$nameEn"');

            return (nameAr != null && nameAr == selected) ||
                (nameEn != null && nameEn == selected);
          }, orElse: () => {});

          if (cm.isNotEmpty) {
            cuttingMethodId = cm['cutting_method_id'];
          }
        } catch (e) {
          debugPrint('Error finding cutting method: $e');
        }
      }

      // Strict validation: If user selected an option but we couldn't resolve its ID
      if (cuttingMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isArabic
                  ? 'حدث خطأ في تحديد خيار التقطيع. يرجى إعادة تحميل الصفحة.'
                  : 'Error resolving option. Please reload the page.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Force reload data
        _loadData();
        return;
      }
    }

    for (int i = 0; i < quantity; i++) {
      cartProvider.addItem(
        productId: widget.product.id,
        title: widget.product.title,
        image: widget.product.imageUrl,
        price:
            (widget.product.discountPrice != null &&
                widget.product.discountPrice! > 0)
            ? widget.product.discountPrice!
            : widget.product.price,
        weight: selectedWeight!,
        variantId: variantId,
        selectedOption: selectedOption,
        cuttingMethodId: cuttingMethodId,
        userId: authProvider.isLoggedIn ? authProvider.user?.id : null,
      );
    }

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          languageProvider.isArabic
              ? 'تم إضافة المنتج إلى السلة بنجاح!'
              : 'Added to cart successfully!',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        action: SnackBarAction(
          label: languageProvider.isArabic ? 'عرض السلة' : 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            context.go('/home'); // Will navigate to cart tab
          },
        ),
      ),
    );
  }

  // Helper to get display options safely
  List<String> get _displayOptions {
    if (_cuttingMethods.isNotEmpty) {
      final options = <String>{};
      for (var c in _cuttingMethods) {
        // Try both keys to be safe
        final method = c['cutting_methods'] ?? c['cutting_method'];
        if (method != null) {
          if (method['name_ar'] != null) options.add(method['name_ar']);
          if (method['name_en'] != null) options.add(method['name_en']);
        }
      }
      if (options.isNotEmpty) return options.toList();
    }
    return widget.product.options;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        languageProvider.isArabic
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Hero(
                          tag: 'product-${widget.product.id}',
                          child: widget.product.images.length > 1
                              ? PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  itemCount: widget.product.images.length,
                                  itemBuilder: (context, index) {
                                    final imageUrl =
                                        widget.product.images[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageUrl.startsWith('http')
                                              ? NetworkImage(imageUrl)
                                                    as ImageProvider
                                              : AssetImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image:
                                          widget.product.imageUrl.startsWith(
                                            'http',
                                          )
                                          ? NetworkImage(
                                                  widget.product.imageUrl,
                                                )
                                                as ImageProvider
                                          : AssetImage(widget.product.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                        if (widget.product.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: widget.product.images.length,
                                effect: ExpandingDotsEffect(
                                  activeDotColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  dotColor: Colors.white.withOpacity(0.5),
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  spacing: 4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (widget.product.discountPrice !=
                                              null &&
                                          widget.product.discountPrice! >
                                              0) ...[
                                        Text(
                                          widget.product.discountPrice!
                                              .toStringAsFixed(0),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.product.price.toStringAsFixed(
                                            0,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                        ),
                                      ] else
                                        Text(
                                          widget.product.price.toStringAsFixed(
                                            0,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                        ),
                                      const SizedBox(width: 8),
                                      Image.asset(
                                        'assets/images/sar.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Rating
                              Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < widget.product.rating.floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.product.rating} (${widget.product.reviewCount} ${languageProvider.isArabic ? 'تقييم' : 'reviews'})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Weight Selection
                              Text(
                                languageProvider.isArabic
                                    ? 'الحجم / الوزن'
                                    : 'Size / Weight',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _availableWeights.map((weight) {
                                  final isSelected = selectedWeight == weight;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedWeight = weight;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        weight,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 24),

                              // Option Selection
                              Text(
                                languageProvider.isArabic
                                    ? 'طريقة التقطيع / خيارات إضافية'
                                    : 'Cutting Method / Options',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _displayOptions.map((option) {
                                  final isSelected = selectedOption == option;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedOption = option;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.1)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 24),

                              // Quantity
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      languageProvider.isArabic
                                          ? 'الكمية'
                                          : 'Quantity',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: IconButton(
                                            icon: Icon(Icons.remove, size: 18),
                                            onPressed: quantity > 1
                                                ? () {
                                                    setState(() {
                                                      quantity--;
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ),
                                        Container(
                                          width: 40,
                                          alignment: Alignment.center,
                                          child: Text(
                                            quantity.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: IconButton(
                                            icon: Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                quantity++;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Description
                              Text(
                                languageProvider.isArabic
                                    ? 'الوصف'
                                    : 'Description',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: Text(
                                  widget.product.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                                ),
                                secondChild: Text(
                                  widget.product.description,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isExpanded = !isExpanded;
                                  });
                                },
                                child: Text(
                                  languageProvider.isArabic
                                      ? (isExpanded
                                            ? 'اقرأ أقل'
                                            : 'اقرأ المزيد')
                                      : (isExpanded
                                            ? 'Read less'
                                            : 'Read more'),
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.light
                          ? 0.1
                          : 0.4,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.0,
                        end: 0.95,
                      ).animate(_buttonAnimationController),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _addToCart,
                          icon: Icon(Iconsax.shopping_cart),
                          label: Text(
                            languageProvider.isArabic
                                ? 'إضافة للسلة'
                                : 'Add to Cart',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
