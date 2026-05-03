# Google Sign-In Setup

Gunakan nilai berikut saat membuat OAuth client di Google Cloud/Firebase.

## Android OAuth Client

| Field | Nilai |
|---|---|
| Package name | `com.warungkopi.pos` |
| Debug SHA-1 | `13:B7:CB:29:0B:65:7A:D3:1C:E2:34:8B:59:A7:0D:D6:01:EF:B5:F1` |

SHA-1 di atas berasal dari debug keystore lokal:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Jika membuat APK release dengan signing key sendiri, tambahkan juga SHA-1 release ke Android OAuth client.

## Web OAuth Client

Isi `.env` dengan **Web OAuth Client ID**, bukan Android client ID:

```env
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Web OAuth client dan Android OAuth client harus berada di Google Cloud/Firebase project yang sama.

## Supabase Auth

Di Supabase Dashboard:

1. Buka `Authentication > Providers > Google`.
2. Aktifkan Google provider.
3. Masukkan Web OAuth Client ID dan Web OAuth Client Secret dari project Google yang sama.
4. Pastikan redirect URL Supabase yang diminta dashboard sudah didaftarkan di Web OAuth client.

## Checklist Saat Error Setelah Pilih Akun

- `android/app/build.gradle` memakai `applicationId = "com.warungkopi.pos"`.
- Android OAuth client memakai package `com.warungkopi.pos`.
- Android OAuth client punya SHA-1 debug di atas untuk `flutter run`/debug APK.
- `.env` memakai Web OAuth Client ID yang satu project dengan Android OAuth client.
- Jika memakai release APK, SHA-1 release juga sudah ditambahkan.
