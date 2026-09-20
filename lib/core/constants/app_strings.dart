/// Markazlashtirilgan o'zbekcha matnlar.
/// Ilovaning barcha joylarida ishlatiladigan matnlar shu yerda saqlanadi.
abstract final class AppStrings {
  // ── Umumiy ──
  static const String appName = 'LogiSender Pro';
  static const String professionalManager = 'Professional Logistika Boshqaruvchisi';
  static const String loading = 'Yuklanmoqda...';
  static const String error = 'Xatolik';
  static const String retry = 'Qayta urinish';
  static const String cancel = 'Bekor qilish';
  static const String save = 'Saqlash';
  static const String close = 'Yopish';
  static const String confirm = 'Tasdiqlash';
  static const String delete = 'O\'chirish';
  static const String none = 'Yo\'q';
  static const String active = 'Faol';
  static const String inactive = 'Nofaol';

  // ── Auth: API Config ──
  static const String apiSetup = 'Telegram API Sozlamalari';
  static const String apiSetupSubtitle = 'my.telegram.org dan\nAPI ma\'lumotlaringizni kiriting';
  static const String apiId = 'API ID';
  static const String apiHash = 'API Hash';
  static const String connect = 'Ulanish';
  static const String getApiCredentials = 'my.telegram.org dan API ma\'lumotlarini olish';

  // ── Auth: Telefon ──
  static const String enterPhone = 'Telefon raqamini kiriting';
  static const String phoneSubtitle = 'Telegram akkauntingizga\ntasdiqlash kodi yuboriladi\nXalqaro raqamlar ham ishlaydi (AQSh 🇺🇸, Kanada 🇨🇦, ...)';
  static const String phoneNumber = 'Telefon raqami';
  static const String phoneHint = '+1 555 123 4567';
  static const String phoneExample = '+998901234567';
  static const String sendCode = 'Kodni yuborish';

  // ── Auth: Kod ──
  static const String verificationCode = 'Tasdiqlash kodi';
  static const String codeSubtitle = 'Kod yuborildi:\n';
  static const String codeHint = '000000';
  static const String verify = 'Tasdiqlash';
  static const String changePhone = 'Telefon raqamini o\'zgartirish';

  // ── Auth: 2FA ──
  static const String twoFaTitle = 'Ikki bosqichli autentifikatsiya';
  static const String twoFaHintLabel = 'Maslahat:';
  static const String twoFaDefault = '2FA parolni kiriting';
  static const String password = 'Parol';
  static const String passwordHint = '2FA parolni kiriting';
  static const String verifyPassword = 'Parolni tasdiqlash';
  static const String backToLogin = 'Tizimga qaytish';

  // ── Asosiy ekran ──
  static const String home = 'Bosh sahifa';
  static const String groups = 'Guruhlar';
  static const String templates = 'Shablonlar';
  static const String stats = 'Statistika';
  static const String settings = 'Sozlamalar';
  static const String hello = 'Salom';
  static const String user = 'Foydalanuvchi';
  static const String dashboard = 'LogiSender Pro Boshqaruv Paneli';
  static const String running = 'Ishlamoqda';
  static const String stopped = 'To\'xtatilgan';
  static const String lastSent = 'Oxirgi yuborilgan';
  static const String sentToday = 'Bugun yuborilgan';
  static const String errors = 'Xatoliklar';
  static const String activeGroups = 'Faol guruhlar';
  static const String floodWait = 'Flood kutish';
  static const String startAutomation = 'Avtomatlashtirishni boshlash';
  static const String stopAutomation = 'Avtomatlashtirishni to\'xtatish';
  static const String automationSettings = 'Avtomatlashtirish sozlamalari';

  // ── Guruhlar tanlash ──
  static const String selectGroups = 'Guruhlarni tanlash';
  static const String searchGroups = 'Guruhlarni qidirish...';
  static const String selectAll = 'Barchasini tanlash';
  static const String clearAll = 'Barchasini tozalash';
  static const String groupsSelected = 'Tanlangan';
  static const String failedToLoadGroups = 'Guruhlarni yuklashda xatolik';
  static const String noGroupsFound = 'Guruhlar topilmadi';
  static const String noSelectedGroups = 'Hech qanday guruh tanlanmagan';
  static const String channels = 'Kanallar';
  static const String supergroups = 'Superguruhlar';
  static const String forums = 'Forumlar';

  // ── Guruhlar (oldindan ko'rish) ──
  static const String selectedGroupsPreview = 'Tanlangan guruhlar';

  // ── Shablonlar ──
  static const String adTemplates = 'E\'lon shablonlari';
  static const String noTemplatesYet = 'Hali shablonlar yo\'q';
  static const String noTemplatesSubtitle = 'Avtomatik e\'lon yuborish uchun\nbirinchi shabloningizni yarating';
  static const String templatePreview = 'Shablon ko\'rinishi';
  static const String smartVariation = 'Aqlli variatsiya:';
  static const String smartTemplate = 'Aqlli shablon';
  static const String standard = 'Oddiy';
  static const String autoVariations = 'Unikal variatsiyalarni avtomatik yaratish';
  static const String autoVariationsSend = 'Har bir yuborishda unikal variatsiya yaratish';
  static const String newTemplate = 'Yangi shablon';
  static const String templateName = 'Shablon nomi';
  static const String templateNameHint = 'Masalan: Yekaterinburg - Toshkent';
  static const String adContent = 'E\'lon matni';
  static const String adContentHint = '🇷🇺 Shahar ➜ 🇺🇿 Shahar\n📦 Yuk: ...\n🚛 Kerakli: ...\n💰 Narx: ...';
  static const String adContentHintFull = '🇷🇺 Yekaterinburg ➜ 🇺🇿 Toshkent\n📦 Yuk: Taxta\n🚛 Kerakli: 5 tonnalik tent\n💰 Narx: Kelishiladi\n✅ Yuk tayyor';
  static const String saveTemplate = 'Shablonni saqlash';
  static const String duplicate = 'Nusxa';
  static const String templateCopied = ' (Nusxa)';

  // ── Avtomatlashtirish ──
  static const String automation = 'Avtomatlashtirish';
  static const String sendingTo = 'Yuborilmoqda:';
  static const String sent = 'Yuborildi';
  static const String scheduleConfig = 'Jadval sozlamalari';
  static const String sendInterval = 'Yuborish oralig\'i';
  static const String sendIntervalValue = '1 soat 10 daqiqa (tanaffus)';
  static const String groupSwitch = 'Guruh almashtirish';
  static const String groupSwitchValue = '3-5 soniya kechikish';
  static const String intervalRefresh = 'Interval yangilanishi';
  static const String intervalRefreshValue = 'Kunlik (tasodifiy)';
  static const String sequencing = 'Tartiblash';
  static const String sequencingValue = 'Tasodifiy, hech qachon bir vaqtda';
  static const String createTemplateFirst = 'Avval shablon yarating!';
  static const String noEnabledGroups = 'Faollashtirilgan guruhlar topilmadi';

  // ── Statistika ──
  static const String statisticsLogs = 'Statistika va Loglar';
  static const String totalSent = 'Jami yuborilgan';
  static const String successful = 'Muvaffaqiyatli';
  static const String successRate = 'Muvaffaqiyat foizi';
  static const String recentLogs = 'So\'nggi loglar';
  static const String logsEmpty = 'Avtomatlashtirish ishlaganda loglar shu yerda paydo bo\'ladi';
  static const String today = 'Bugun';
  static const String yesterday = 'Kecha';
  static const String week = 'Hafta';
  static const String month = 'Oy';
  static const String justNow = 'Hozir';

  // ── Sozlamalar ──
  static const String account = 'Akkaunt';
  static const String notSet = 'Belgilanmagan';
  static const String userId = 'Foydalanuvchi ID';
  static const String application = 'Ilova';
  static const String darkMode = 'Qorong\'u rejim';
  static const String notifications = 'Bildirishnomalar';
  static const String batteryOptimization = 'Batareya optimizatsiyasi';
  static const String dataManagement = 'Ma\'lumotlarni boshqarish';
  static const String exportLogs = 'Loglarni eksport qilish';
  static const String backupSession = 'Sessiyani zaxiralash';
  static const String restoreSession = 'Sessiyani tiklash';
  static const String dangerZone = 'Xavfli zona';
  static const String logout = 'Tizimdan chiqish';
  static const String logoutSubtitle = 'Telegram dan chiqish';
  static const String confirmLogout = 'Chiqishni tasdiqlash';
  static const String confirmLogoutMessage = 'Haqiqatan tizimdan chiqmoqchimisiz?';
  static const String appVersion = 'LogiSender Pro v1.0.0';

  // ── Bosh sahifa: oldindan ko\'rish ──
  static const String viewAll = 'Barchasini ko\'rish';
  static const String groupsPreview = 'Guruhlar';
  static const String templatesPreview = 'Shablonlar';
  static const String enabled = 'Yoqilgan';
  static const String disabled = 'O\'chirilgan';
}
