export interface TranslationContent {
  nav: {
    howItWorks: string;
    features: string;
    categories: string;
    faq: string;
    privacyPolicy: string;
    getGooglePlay: string;
  };
  hero: {
    badge: string;
    title: string;
    subtitle: string;
    googlePlayBtn: string;
    googlePlaySub: string;
    packageName: string;
    readPrivacy: string;
    distancePill: string;
    carParkedBadge: string;
  };
  onboarding: {
    badge: string;
    title: string;
    subtitle: string;
    steps: Array<{
      id: string;
      image: string;
      title: string;
      body: string;
      highlight: string;
    }>;
  };
  actions: {
    badge: string;
    title: string;
    subtitle: string;
    items: Array<{
      icon: string;
      title: string;
      description: string;
      badgeText: string;
    }>;
  };
  categories: {
    badge: string;
    title: string;
    subtitle: string;
    items: Array<{
      name: string;
      icon: string;
      color: string;
    }>;
  };
  faq: {
    badge: string;
    title: string;
    subtitle: string;
    items: Array<{
      question: string;
      answer: string;
    }>;
  };
  ctaBanner: {
    badge: string;
    title: string;
    subtitle: string;
    googlePlayBtn: string;
    packageName: string;
    note: string;
  };
  footer: {
    tagline: string;
    aboutTitle: string;
    aboutText: string;
    quickLinks: string;
    privacyPolicy: string;
    copyright: string;
    packageId: string;
  };
  privacyPage: {
    backToHome: string;
    title: string;
    lastUpdated: string;
    intro: string;
    sections: Array<{
      heading: string;
      content: string[];
    }>;
  };
}

export const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.dalely.app';
export const PACKAGE_NAME = 'com.dalely.app';
export const CONTACT_EMAIL = 'salem.dev.77@gmail.com';
export const CONTACT_PHONE = '+201123225592';

export const translations: Record<'en' | 'ar', TranslationContent> = {
  en: {
    nav: {
      howItWorks: 'How it Works',
      features: 'Features',
      categories: 'Categories',
      faq: 'FAQ',
      privacyPolicy: 'Privacy Policy',
      getGooglePlay: 'Google Play',
    },
    hero: {
      badge: '100% Local • Zero Accounts • No Tracking',
      title: 'Never forget where you parked.',
      subtitle:
        'Save your car and favourite spots in one tap. Local-only, private, and simple.',
      googlePlayBtn: 'GET IT ON',
      googlePlaySub: 'Google Play',
      packageName: 'com.dalely.app',
      readPrivacy: 'Privacy Policy',
      distancePill: '45 m away',
      carParkedBadge: 'Parked just now',
    },
    onboarding: {
      badge: 'Simple by Design',
      title: 'Built to be friendly and easy',
      subtitle:
        'Dalely is designed to do one thing exceptionally well: help you find your way back without friction.',
      steps: [
        {
          id: 'step-1',
          image: '/assets/onboarding_1.png',
          title: 'Never forget where you parked',
          body: 'Save your car with one tap, then open it in Maps when you are ready to walk back. No more wandering around the car park.',
          highlight: '1-Tap Park',
        },
        {
          id: 'step-2',
          image: '/assets/onboarding_2.png',
          title: 'All your places, one spot',
          body: 'Your market, home, pharmacy and more live in one list and on one map. Share any spot, or all of them, with a map link anytime.',
          highlight: '1 Map for All',
        },
        {
          id: 'step-3',
          image: '/assets/onboarding_3.png',
          title: 'Your places stay on your phone',
          body: 'Everything is saved only on this device and never sent anywhere. No sign-up, no cloud storage, and zero tracking cookies.',
          highlight: '100% Private',
        },
      ],
    },
    actions: {
      badge: '3 Actions per Spot',
      title: 'Every spot has just 3 clear actions',
      subtitle: 'No complex menus or clutter. Tap any saved spot to get what you need instantly.',
      items: [
        {
          icon: 'MapPin',
          title: 'On Map',
          description:
            'See the spot immediately on the in-app Google Map with your current location and walking heading.',
          badgeText: 'Instant view',
        },
        {
          icon: 'Navigation',
          title: 'Open in Maps',
          description:
            'Hand off smoothly to Google Maps or your default navigation app for turn-by-turn driving or walking directions.',
          badgeText: 'Turn-by-turn',
        },
        {
          icon: 'Share2',
          title: 'Share',
          description:
            'Send a clean, friendly link to anyone: "Name - https://maps.google.com/?q=lat,lng" in one tap.',
          badgeText: '1-Tap share',
        },
      ],
    },
    categories: {
      badge: 'Categories',
      title: 'Organize your daily places',
      subtitle: 'Tag any spot with a friendly icon and color for fast searching.',
      items: [
        { name: 'Car', icon: '🚗', color: '#FF8A65' },
        { name: 'Home', icon: '🏠', color: '#4CAF50' },
        { name: 'Market', icon: '🛒', color: '#3C79F3' },
        { name: 'Pharmacy', icon: '💊', color: '#E91E63' },
        { name: 'Work', icon: '💼', color: '#607D8B' },
        { name: 'Restaurant', icon: '🍽️', color: '#FF9800' },
        { name: 'Hospital', icon: '🏥', color: '#F44336' },
        { name: 'School', icon: '🎓', color: '#9C27B0' },
        { name: 'Gym', icon: '🏋️', color: '#009688' },
        { name: 'Mosque', icon: '🕌', color: '#00BCD4' },
        { name: 'Fuel', icon: '⛽', color: '#795548' },
        { name: 'Other', icon: '📍', color: '#607D8B' },
      ],
    },
    faq: {
      badge: 'Common Questions',
      title: 'Frequently Asked Questions',
      subtitle: 'Clear, transparent answers about how Dalely protects your privacy.',
      items: [
        {
          question: 'Is Dalely completely free?',
          answer:
            'Yes, Dalely is 100% free with no hidden subscriptions, no ads, and no in-app purchases.',
        },
        {
          question: 'Do I need to create an account or sign in?',
          answer:
            'Never. You open the app and start using it right away. We do not have user accounts, email logins, or passwords.',
        },
        {
          question: 'Where is my location and saved spots data stored?',
          answer:
            'All data is saved strictly inside your phone’s local storage (Hive database). It never leaves your phone and is never uploaded to any cloud server.',
        },
        {
          question: 'Does the app track my location when closed?',
          answer:
            'No. Dalely only accesses your location while you are actively using the app in the foreground, or optionally when tracking walking distance back to your parked car. The location stream pauses automatically in the background.',
        },
        {
          question: 'How do I install the app on Android?',
          answer:
            'You can download Dalely directly from Google Play under package name com.dalely.app.',
        },
      ],
    },
    ctaBanner: {
      badge: 'Available Now',
      title: 'Ready to find your car without stress?',
      subtitle:
        'Download Dalely on Google Play today. Safe, fast, and completely private.',
      googlePlayBtn: 'Get it on Google Play',
      packageName: 'Package: com.dalely.app',
      note: 'Compatible with Android phones, foldable devices & tablets.',
    },
    footer: {
      tagline: 'Simple, friendly, and local-only spot & car finder.',
      aboutTitle: 'About Dalely',
      aboutText:
        'Dalely is designed with a privacy-by-design mindset. No cloud servers, no account sign-ups, and no analytics.',
      quickLinks: 'Quick Links',
      privacyPolicy: 'Privacy Policy',
      copyright: '© 2026 Dalely (دليلى). All rights reserved.',
      packageId: 'Android: com.dalely.app',
    },
    privacyPage: {
      backToHome: 'Back to Home',
      title: 'Privacy Policy',
      lastUpdated: 'Last Updated: October 2026',
      intro:
        'At Dalely (دليلى), your privacy is our foundational principle. We believe that remembering where you parked your car or saving your favorite corner store shouldn’t require handing over your personal life, habits, or location history to remote servers.',
      sections: [
        {
          heading: '1. Zero Account & Zero Registration Policy',
          content: [
            'Dalely operates entirely without accounts. There are no sign-up forms, no logins via third parties (Google, Apple, or Facebook), and no passwords.',
            'You can use all features immediately upon launching the app without providing an email address, telephone number, name, or identity.',
          ],
        },
        {
          heading: '2. 100% On-Device Local Storage (Hive)',
          content: [
            'Every spot you save (coordinates, custom name, category, and timestamp) is stored strictly in your phone’s local on-device Hive database.',
            'We do not operate backend servers, databases, or cloud sync engines. Your data resides solely on your physical device hardware.',
            'If you delete the app or clear its storage data via device settings, all saved spots are erased permanently.',
          ],
        },
        {
          heading: '3. Location & GPS Data Usage',
          content: [
            'Dalely requires location permissions ("While Using the App") to identify your coordinates when you tap "Park here" or save a spot, and to calculate your live walking distance back to your car.',
            'Location coordinates are never transmitted to us or any remote server. The location stream actively listens only while the application is in the foreground and stops when closed.',
            'When parked car live tracking is active, the foreground service monitors distance strictly on your device to notify you when you arrive.',
          ],
        },
        {
          heading: '4. External Maps & Navigation',
          content: [
            'Dalely does not build proprietary navigation routes. When you tap "Open in Maps", Dalely hands off your saved coordinates to your chosen default maps app (such as Google Maps) via standard system URI.',
            'Any interaction within external mapping apps is governed by their respective privacy policies.',
          ],
        },
        {
          heading: '5. No Analytics, Tracking, or Advertising',
          content: [
            'We have deliberately omitted third-party analytics SDKs (e.g., Firebase Analytics, Mixpanel) and advertising networks.',
            'We do not track your behavioral patterns, session length, screen views, or physical movements.',
          ],
        },
        {
          heading: '6. Contact & Package Details',
          content: [
            'Dalely is published for Android under package name com.dalely.app.',
            'If you have questions, feedback, or inquiries regarding this Privacy Policy or your data, you can reach the developer directly at salem.dev.77@gmail.com or by phone/WhatsApp at +201123225592.',
          ],
        },
      ],
    },
  },
  ar: {
    nav: {
      howItWorks: 'كيف يعمل؟',
      features: 'المميزات',
      categories: 'التصنيفات',
      faq: 'الأسئلة الشائعة',
      privacyPolicy: 'سياسة الخصوصية',
      getGooglePlay: 'جوجل بلاي',
    },
    hero: {
      badge: 'بجهازك فقط • بدون حسابات • بدون تتبع',
      title: 'ما راح تنسى وين وقفت سيارتك.',
      subtitle:
        'احفظ مكان سيارتك وأماكنك المفضلة بضغطة زر. خصوصية كاملة، وبجهازك بس.',
      googlePlayBtn: 'متوفر على',
      googlePlaySub: 'Google Play',
      packageName: 'com.dalely.app',
      readPrivacy: 'سياسة الخصوصية',
      distancePill: 'على بُعد 45 متر',
      carParkedBadge: 'تم التوقف الآن',
    },
    onboarding: {
      badge: 'بساطة وسهولة',
      title: 'تطبيق لطيف وسهل الاستخدام',
      subtitle:
        'تم تصميم دليلى ليؤدي غرضاً واحداً باحترافية: يرجعك لمكان سيارتك وأماكنك بدون أي تعقيد.',
      steps: [
        {
          id: 'step-1',
          image: '/assets/onboarding_1.png',
          title: 'ما راح تنسى وين وقفت سيارتك',
          body: 'احفظ مكان سيارتك بضغطة زر، وافتحها في الخرايط وقت ما ترجع. وداعاً للبحث واللف في المواقف.',
          highlight: 'ضغطة زر واحدة',
        },
        {
          id: 'step-2',
          image: '/assets/onboarding_2.png',
          title: 'كل أماكنك بمكان واحد',
          body: 'البقالة، البيت، الصيدلية وكل مشاويرك بقائمة وخريطة وحدة. شارك أي موقع برابط بأي وقت.',
          highlight: 'خريطة واحدة للكل',
        },
        {
          id: 'step-3',
          image: '/assets/onboarding_3.png',
          title: 'أماكنك محفوظة بجهازك بس',
          body: 'كل بياناتك محفوظة بجهازك وما تنرسل لأي مكان. بدون تسجيل دخول، وبدون خوادم سحابية، وبدون تتبع.',
          highlight: 'خصوصية ١٠٠٪',
        },
      ],
    },
    actions: {
      badge: '٣ إجراءات فقط',
      title: '٣ إجراءات واضحة وسريعة لكل مكان',
      subtitle: 'بدون قوائم معقدة أو زحمة. اضغط على أي مكان واحصل على اللي تحتاجه فوراً.',
      items: [
        {
          icon: 'MapPin',
          title: 'على الخريطة',
          description:
            'شاهد المكان فوراً داخل خريطة التطبيق مع موقعك الحالي واتجاه مشيك الحقيقي.',
          badgeText: 'عرض فوري',
        },
        {
          icon: 'Navigation',
          title: 'فتح في الخرائط',
          description:
            'انتقل مباشرة لتطبيق خرائط جوجل لبدء التوجيه الصوتي والمسار خطوة بخطوة.',
          badgeText: 'ملاحة دقيقة',
        },
        {
          icon: 'Share2',
          title: 'مشاركة',
          description:
            'أرسل رسالة نصية نظيفة مع رابط خرائط جوجل بلمسة واحدة لأهلك وأصحابك.',
          badgeText: 'مشاركة بضغطة',
        },
      ],
    },
    categories: {
      badge: 'التصنيفات',
      title: 'رتب مشاويرك وأماكنك اليومية',
      subtitle: 'اختر أي تصنيف بأيقونة ولون واضح للوصول السريع والبحث.',
      items: [
        { name: 'السيارة', icon: '🚗', color: '#FF8A65' },
        { name: 'البيت', icon: '🏠', color: '#4CAF50' },
        { name: 'البقالة', icon: '🛒', color: '#3C79F3' },
        { name: 'الصيدلية', icon: '💊', color: '#E91E63' },
        { name: 'العمل', icon: '💼', color: '#607D8B' },
        { name: 'المطعم', icon: '🍽️', color: '#FF9800' },
        { name: 'المستشفى', icon: '🏥', color: '#F44336' },
        { name: 'المدرسة', icon: '🎓', color: '#9C27B0' },
        { name: 'النادي', icon: '🏋️', color: '#009688' },
        { name: 'المسجد', icon: '🕌', color: '#00BCD4' },
        { name: 'المحطة', icon: '⛽', color: '#795548' },
        { name: 'أخرى', icon: '📍', color: '#607D8B' },
      ],
    },
    faq: {
      badge: 'أسئلة تهمك',
      title: 'الأسئلة الشائعة',
      subtitle: 'إجابات واضحة وشفافة حول التطبيق وخصوصية بياناتك.',
      items: [
        {
          question: 'هل تطبيق دليلى مجاني بالكامل؟',
          answer:
            'نعم، دليلى مجاني ١٠٠٪ تماماً، بدون أي إعلانات، وبدون أي رسوم خفية أو اشتراكات.',
        },
        {
          question: 'هل أحتاج لإنشاء حساب أو تسجيل دخول؟',
          answer:
            'أبداً! بمجرد فتح التطبيق تبدأ باستخدامه فوراً. لا نطلب بريداً إلكترونياً، ولا رقماً، ولا أي كلمة مرور.',
        },
        {
          question: 'أين يتم حفظ أماكن وموقع سيارتي؟',
          answer:
            'جميع بياناتك محفوظة محلياً داخل ذاكرة هاتفك فقط (قاعدة بيانات Hive). لا يتم رفعها لأي سيرفر أو خادم سحابي.',
        },
        {
          question: 'هل يتابع التطبيق موقعي عندما يكون مغلقاً؟',
          answer:
            'لا، يعمل تحديد الموقع فقط وأنت فاتح التطبيق لتحديد مكان وقوفك أو لمتابعة مسافة العودة للسيارة. يتوقف بث الموقع فور خروجك.',
        },
        {
          question: 'كيف يمكنني تحميل التطبيق على أندرويد؟',
          answer:
            'يمكنك تحميل التطبيق مباشرة من متجر Google Play تحت الحزمة الرسمية com.dalely.app.',
        },
      ],
    },
    ctaBanner: {
      badge: 'متوفر الآن',
      title: 'جاهز تحفظ مكان سيارتك بدون أي قلق؟',
      subtitle:
        'حمّل تطبيق دليلى من متجر Google Play الآن. خفيف، سريع، وبخصوصية مطلقة.',
      googlePlayBtn: 'تحميل من Google Play',
      packageName: 'الحزمة: com.dalely.app',
      note: 'متوافق مع هواتف أندرويد، الأجهزة القابلة للطي، والأجهزة اللوحية.',
    },
    footer: {
      tagline: 'تطبيق لطيف، بسيط، وبخصوصية كاملة لحفظ مكان سيارتك وأماكنك.',
      aboutTitle: 'عن دليلى',
      aboutText:
        'تم بناء دليلى بالاعتماد على مبدأ الخصوصية أولاً. بدون خوادم سحابية، بدون حسابات، وبدون أدوات تحليل.',
      quickLinks: 'روابط سريعة',
      privacyPolicy: 'سياسة الخصوصية',
      copyright: '© 2026 دليلى (Dalely). جميع الحقوق محفوظة.',
      packageId: 'أندرويد: com.dalely.app',
    },
    privacyPage: {
      backToHome: 'العودة للرئيسية',
      title: 'سياسة الخصوصية',
      lastUpdated: 'آخر تحديث: أكتوبر ٢٠٢٦',
      intro:
        'في تطبيق دليلى (Dalely)، الخصوصية هي الأساس الراسخ الذي بُني عليه التطبيق. نحن نؤمن بأن تذكّر مكان ركن سيارتك أو حفظ مكان البقالة المفضلة لديك لا ينبغي أن يتطلب التخلي عن بياناتك الشخصية، أو مشاركة موقعك الجغرافي مع خوادم خارجية.',
      sections: [
        {
          heading: '١. عدم طلب الحسابات أو التسجيل نهائياً',
          content: [
            'يعمل تطبيق دليلى بالكامل بدون أي حاجة لحسابات مستخدمين. لا توجد شاشات تسجيل، ولا تسجيل عبر أطراف ثالثة (مثل جوجل أو أبل)، ولا كلمات مرور.',
            'يمكنك الاستفادة من كافة خصائص التطبيق لحظة فتحه دون تقديم اسمك أو بريدك الإلكتروني أو رقم هاتفك.',
          ],
        },
        {
          heading: '٢. تخزين البيانات محلياً على جهازك بنسبة ١٠٠٪ (Hive)',
          content: [
            'كافة المواقع المحفوظة (الإحداثيات، الاسم المخصص، التصنيف، والوقت) يتم تخزينها داخل ذاكرة هاتفك فقط باستخدام قاعدة بيانات Hive المحلية.',
            'لا نملك خوادم خلفية أو قواعد بيانات سحابية لتخزين أماكنك. بياناتك تخصك وحدك وتظل محفوظة داخل عتاد جهازك.',
            'عند قيامك بحذف التطبيق أو مسح بياناته من إعدادات الهاتف، يتم مسح كافة بيانات الأماكن نهائياً.',
          ],
        },
        {
          heading: '٣. إذن الموقع الجغرافي (GPS) واستخدامه',
          content: [
            'يطلب التطبيق إذن الموقع ("أثناء استخدام التطبيق فقط") لتحديد إحداثياتك عند الضغط على "وقفت هنا" أو حفظ مكان جديد، ولحساب المسافة المتبقية سيراً على الأقدام لسيارتك.',
            'لا يتم إرسال إحداثيات موقعك الجغرافي إلى أي جهة خارجية أو خوادم تحليلية إطلاقاً. يتوقف تحديث الموقع فور إغلاق التطبيق.',
            'في حال تفعيل ميزة تتبع المسافة للسيارة المركونة، تعمل الخدمة المؤقتة محلياً على هاتفك لتنبيهك عند الوصول.',
          ],
        },
        {
          heading: '٤. الخرائط والملاحة الخارجية',
          content: [
            'لا يقوم دليلى بإنشاء مسارات قيادة خاصة به. عند الضغط على "فتح في الخرائط"، يتم فتح إحداثياتك داخل تطبيق الخرائط الافتراضي في جهازك (مثل خرائط جوجل).',
            'أي تعامل داخل تطبيقات الخرائط الخارجية يخضع لسياسات الخصوصية الخاصة بتلك التطبيقات.',
          ],
        },
        {
          heading: '٥. انعدام الإعلانات والتحليلات والتتبع',
          content: [
            'التطبيق خالٍ تماماً من حزم تتبع السلوك (مثل Firebase Analytics أو Mixpanel) وشبكات الإعلانات.',
            'لا نجمع أي معلومات حول نمط استخدامك، أو مدة جلساتك، أو مسارات تنقلك اليومية.',
          ],
        },
        {
          heading: '٦. معلومات الحزمة والتواصل',
          content: [
            'التطبيق منشور رسمياً لنظام أندرويد تحت اسم الحزمة com.dalely.app.',
            'لأي استفسارات أو ملاحظات بخصوص سياسة الخصوصية أو التطبيق، يمكنك التواصل مباشرة مع المطور عبر البريد الإلكتروني salem.dev.77@gmail.com أو عبر الهاتف / واتساب على الرقم 201123225592+.',
          ],
        },
      ],
    },
  },
};
