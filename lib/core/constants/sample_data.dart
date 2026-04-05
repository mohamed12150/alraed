import '../../models/category.dart';
import '../../models/banner.dart';
import '../../models/product.dart';

class SampleData {
  static final List<Category> categories = [
    Category(
      id: 'occasions',
      nameEn: 'Occasions Sacrifices',
      nameAr: 'ذبائح المناسبات',
      icon: 'occasions',
      image: 'assets/images/download (1).jpg',
      colorHex: '#B71C1C',
    ),
    Category(
      id: 'kilo_selections',
      nameEn: 'Kilo Selections',
      nameAr: 'مختارات الكيلو',
      icon: 'kilo',
      image: 'assets/images/download (3).jpg',
      colorHex: '#D84315',
    ),
    Category(
      id: 'bbq_boxes',
      nameEn: 'BBQ Boxes',
      nameAr: 'بوكسات الشواء',
      icon: 'bbq',
      image: 'assets/images/images (1).jpg',
      colorHex: '#4E342E',
    ),
    Category(
      id: 'feast',
      nameEn: 'Aajibak Feast',
      nameAr: 'وليمة أعجبك',
      icon: 'feast',
      image: 'assets/images/1.png',
      colorHex: '#8D6E63',
    ),
    Category(
      id: 'quick_picnic',
      nameEn: 'Quick Picnic Box',
      nameAr: 'بوكس الكشتة السريعة',
      icon: 'picnic',
      image: 'assets/images/images.jpg',
      colorHex: '#FBC02D',
    ),
  ];

  static final List<Banner> banners = [
    Banner(
      id: '1',
      titleEn: 'Fresh Meat Daily',
      titleAr: 'لحوم طازجة يومياً',
      image: 'assets/images/download (2).jpg',
      link: '/category/beef',
    ),
    Banner(
      id: '2',
      titleEn: 'Weekend BBQ Special',
      titleAr: 'عروض الشواء لنهاية الأسبوع',
      image: 'assets/images/images (1).jpg',
      link: '/category/lamb',
    ),
    Banner(
      id: '3',
      titleEn: 'Free Delivery',
      titleAr: 'توصيل مجاني',
      image: 'assets/images/images.jpg',
      link: '/shipping',
    ),
  ];

  static final List<Product> products = [
    // ذبائح المناسبات
    Product(
      id: '1',
      title: 'ذبيحة نعيمي كاملة',
      description: 'ذبيحة نعيمي طازجة وكاملة، تربية مزارعنا. تشمل خيارات التقطيع والتغليف حسب الطلب.',
      price: 1450.00,
      imageUrl: 'assets/images/download (1).jpg',
      weights: ['ذبيحة كاملة', 'نصف ذبيحة'],
      options: ['تقطيع ثلاجة', 'تقطيع حضرمي', 'تقطيع قوزي', 'بدون تقطيع'],
      category: 'ذبائح المناسبات',
      rating: 4.9,
      reviewCount: 156,
    ),
    Product(
      id: '2',
      title: 'ذبيحة حري كاملة',
      description: 'ذبيحة حري طازجة، جودة عالية وطعم أصيل. مثالية للمناسبات والولائم.',
      price: 1250.00,
      imageUrl: 'assets/images/download (2).jpg',
      weights: ['ذبيحة كاملة', 'نصف ذبيحة'],
      options: ['تقطيع ثلاجة', 'تقطيع حضرمي', 'تقطيع قوزي'],
      category: 'ذبائح المناسبات',
      rating: 4.8,
      reviewCount: 92,
    ),

    // مختارات الكيلو
    Product(
      id: '3',
      title: 'لحم بقري مفروم',
      description: 'لحم بقري طازج مفروم يومياً، خالي من الدهون الزائدة. مثالي للاستخدام اليومي.',
      price: 45.00,
      imageUrl: 'assets/images/download (3).jpg',
      weights: ['1 كجم', '2 كجم', '5 كجم'],
      options: ['فرمة ناعمة', 'فرمة خشنة'],
      category: 'مختارات الكيلو',
      rating: 4.7,
      reviewCount: 210,
    ),
    Product(
      id: '4',
      title: 'أوصال غنم طازجة',
      description: 'قطع لحم غنم منتقاة بعناية (أوصال) للاستخدام في الطبخ اليومي.',
      price: 65.00,
      imageUrl: 'assets/images/images.jpg',
      weights: ['1 كجم', '2 كجم'],
      options: ['بالعظم', 'بدون عظم'],
      category: 'مختارات الكيلو',
      rating: 4.6,
      reviewCount: 128,
    ),

    // بوكسات الشواء
    Product(
      id: '5',
      title: 'بوكس الشواء العائلي',
      description: 'يحتوي على ريش غنم، كباب، وشيش طاووق. متبلة وجاهزة للشواء مباشرة.',
      price: 185.00,
      imageUrl: 'assets/images/images (1).jpg',
      weights: ['بوكس وسط (3-4 أشخاص)', 'بوكس كبير (6-8 أشخاص)'],
      options: ['تتبيلة حارة', 'تتبيلة عادية'],
      category: 'بوكسات الشواء',
      rating: 4.9,
      reviewCount: 75,
    ),

    // وليمة أعجبك
    Product(
      id: '6',
      title: 'وليمة أعجبك (جاهز للأكل)',
      description: 'نجمع لك بين الذبيحة الطازجة وخدمة الطبخ الاحترافية. تصلك الوليمة جاهزة للأكل مع الأرز والمقبلات.',
      price: 1850.00,
      imageUrl: 'assets/images/1.png',
      weights: ['ذبيحة كاملة مطبوخة', 'نصف ذبيحة مطبوخة'],
      options: ['مندى', 'مدفون', 'كابلي', 'بخاري'],
      category: 'وليمة أعجبك',
      rating: 5.0,
      reviewCount: 45,
    ),

    // بوكس الكشتة السريعة
    Product(
      id: '7',
      title: 'بوكس الكشتة السريعة',
      description: 'البوكس المثالي للطلعات المفاجئة. يحتوي على: 1 كجم شيش طاووق متبل، 1 كجم كباب متبل، أسياخ، صوص باربيكيو.',
      price: 145.00,
      imageUrl: 'assets/images/download (1).jpg',
      weights: ['بوكس متكامل'],
      options: ['جاهز للشواء'],
      category: 'بوكس الكشتة السريعة',
      rating: 4.8,
      reviewCount: 64,
    ),
  ];
}
