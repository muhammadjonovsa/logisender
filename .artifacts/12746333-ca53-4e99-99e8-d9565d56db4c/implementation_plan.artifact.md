# Qurilma nomini "LogiSenderapp" ga o'zgartirish rejasi

Ushbu reja Telegram sessiyalarida (Settings -> Devices) qurilma nomi sifatida "Samsung..." o'rniga foydalanuvchi so'ragan "LogiSenderapp" nomini ko'rsatishni nazarda tutadi.

## Foydalanuvchi tekshiruvi zarur

> [!NOTE]
> Ushbu o'zgarishdan so'ng, Telegram xavfsizlik sozlamalarida yangi kirganingizda qurilma nomi aynan "LogiSenderapp" bo'lib ko'rinadi.

## Taklif qilinayotgan o'zgarishlar

### [Component] Telegram Client

#### [MODIFY] [telegram_client_impl.dart](file:///C:/Users/saydu/StudioProjects/logisender/lib/core/telegram/telegram_client_impl.dart)
- `initConnection` chaqiruvidagi `deviceModel` parametrini "LogiSenderapp" ga o'zgartirish.
- `systemVersion` ni ham "LogiSender Pro" ga o'zgartirish (ixtiyoriy, lekin yaxshiroq ko'rinishi uchun).

## Tekshirish rejasi

### Qo'lda tekshirish
- Ilovaga qaytadan kirib ko'rish.
- Telegram ilovasidagi "Settings -> Devices" bo'limiga kirib, yangi sessiya nomini tekshirish.
