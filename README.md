# إدارة المكتبة — ASP.NET وFlutter

مشروع تعليمي لإدارة الكتب والتصنيفات والعملاء والاستعارات، مع نسختين من واجهة Flutter تتصلان بباك إند واحد.

## المكونات

- ملفات Flutter في جذر المستودع، والكود داخل `lib`.
- `lib/App1`: خدمات HTTP، وإدارة الحالة داخل الشاشات باستخدام FutureBuilder.
- `lib/App2`: خدمات HTTP خلف LibraryProvider، وتحديث الواجهة باستخدام Provider وConsumer.
- `lib/connection.dart`: عنوان API موحد للنسختين.
- `LibraryManagement`: حل ASP.NET، ويضم MVC وAPI وDomain وApplication وInfrastructure وEF Core migrations.

أسماء الكلاسات والكيانات الحالية محفوظة: Book وCategory وCustomer وBorrowing. الاستعارة هي وظيفة المكتبة؛ لا توجد سلة شراء أو مدفوعات.

## المتطلبات

Flutter متوافق مع Dart 3.13.7 أو أحدث ضمن القيود في pubspec.yaml، و.NET SDK 10 لفتح صيغة slnx، و.NET 8 runtime، وSQL Server. تطبيقات C# تستهدف net8.0. أدوات Android المطلوبة يحددها Flutter SDK.

## تشغيل الباك إند

الملفات المنشورة لا تحتوي كلمات مرور أو مفاتيح دخول. اتصال SQL الافتراضي يستخدم Windows Authentication على localhost وقاعدة LibraryManagementDB. يمكن تخصيص الاتصال محليًا بمتغير البيئة ConnectionStrings__DefaultConnection؛ لا تضع كلمة مرور حقيقية في ملفات المستودع.

من جذر المستودع:

~~~powershell
dotnet build LibraryManagement/LibraryManagement.slnx
# إذا لم تكن أداة EF مثبتة:
dotnet tool install --global dotnet-ef --version 8.0.31
# استخدم قاعدة تطوير محلية، وراجع التغييرات قبل تحديث قاعدة موجودة.
dotnet ef database update --project LibraryManagement/LibraryManagement.Infrastructure --startup-project LibraryManagement/LibraryManagement.API
$env:ASPNETCORE_ENVIRONMENT='Development'
dotnet run --project LibraryManagement/LibraryManagement.API --urls http://0.0.0.0:63728
~~~

Swagger المحلي: http://localhost:63728/swagger

واجهات API: /api/Books و/api/Categories و/api/Customers و/api/Borrowings، ومسارات /api/Users/register و/login و/logout. قراءة بيانات المكتبة وتعديلها تتطلب تسجيل الدخول. كلمات المرور تحفظ باستخدام ASP.NET Identity PasswordHasher، والجلسة تستخدم Cookie Authentication.

لا تتضمن النسخة قاعدة بيانات المستخدم أو حساباته. أنشئ حساب التطبيق من Create an account عند التشغيل على قاعدة جديدة. حساب Visual Studio أو GitHub لا يُستخدم للدخول إلى المكتبة.

## تشغيل Flutter

~~~powershell
flutter pub get
flutter run -d <android-device-id>
~~~

العنوان الافتراضي http://10.0.2.2:63728 مناسب لمحاكي Android للوصول إلى API على الكمبيوتر نفسه. افتح App1 - HTTP أو App2 - Provider من شاشة البداية. يجب إبقاء الباك إند قيد التشغيل أثناء استخدام التطبيق.

على هاتف حقيقي، استخدم عنوان الكمبيوتر المتاح على الشبكة من خلال --dart-define=API_URL=http://<pc-lan-address>:63728. إعداد HTTP المحلي مسموح في Android debug فقط؛ إعداد الإنتاج يحتاج HTTPS.

## معاينة نفس الواجهة في المتصفح

المعاينة تخدم Flutter وAPI من الأصل نفسه، حتى تعمل جلسة الدخول بدون إعداد CORS خارجي. من جذر المستودع، بعد بناء Flutter:

~~~powershell
flutter build web --debug --no-wasm-dry-run --dart-define=API_URL=http://localhost:63728
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:FlutterWebRoot=(Join-Path (Get-Location) 'build/web')
dotnet run --project LibraryManagement/LibraryManagement.API --urls http://0.0.0.0:63728
~~~

ثم افتح http://localhost:63728 . إعداد FlutterWebRoot اختياري ويعمل في Development فقط.

## لوحة MVC

لوحة MVC منفصلة عن حسابات تطبيق Flutter. لتفعيل حساب الإدارة التعليمي محليًا، اضبط DemoAdmin__Email وDemoAdmin__Password وJwt__Key في بيئة التشغيل أو .NET User Secrets قبل تشغيل LibraryManagement/LibraryManagement. يجب أن يكون مفتاح JWT خاصًا وطويلًا بما يكفي لـHMAC-SHA256، ولا يُحفظ في Git. الإعدادات المنشورة فارغة حتى لا ينشر المستودع حساب إدارة ثابتًا أو مفتاحًا سريًا.

## الاختبارات وحدود التحقق

~~~powershell
flutter analyze --no-fatal-infos
flutter test
~~~

توجد ثلاثة اختبارات واجهة واختبارا تكامل اختياريان للـAPI. الاختبارات الحقيقية على القاعدة لا تعمل افتراضيًا؛ لتفعيلها على قاعدة تطوير محلية فقط:

~~~powershell
flutter test --dart-define=API_URL=http://localhost:63728 --dart-define=RUN_API_TESTS=true --dart-define=TEST_RUN_ID=unique_run_id
~~~

اختبارات التكامل تضيف سجلات مؤقتة وتنظف الكتب والاستعارات والتصنيفات والعملاء في finally. حسابات الاختبار المسماة verify_<runId>_App1/App2 تبقى حتى تنظفها محليًا؛ لا تحذف الحسابات الأصلية.

تم التحقق من بناء حل ASP.NET ومن APK Android. نجحت اختبارات HTTP وProvider. جُرّبت الواجهة فعليًا في المتصفح: الدخول في النسختين، عرض بيانات من القاعدة، الإضافة والتعديل في App1، انعكاسها والتحديث في App2، وتسجيل الخروج. ظهرت شاشة الدخول على محاكي Android، لكن التحقق الكامل من الدخول وعرض البيانات على Android لم يكتمل بعد؛ لا يعد بناء APK وحده تحققًا كاملًا للتشغيل.

Migration AddLibraryUsers تدعم اعتماد جدول Users موجود بدون حذف حساباته، بعد التحقق من التكرارات والأطوال وإضافة فهارس فريدة. التراجع التلقائي عنها معطّل عمدًا لحماية جدول قد يكون موروثًا من إصدار آخر. راجع أي تغييرات مستقبلية على قاعدة بيانات موجودة قبل تطبيقها.

## المرجع التعليمي

مرجع المهندس: https://github.com/mohamedalswaify/First-Bootcamp2026

- HTTP وFutureBuilder: 5mpbileApp/lib/App1/data/ProductService.dart وApp1/productsScreen.dart، مع تكييفها لبيانات المكتبة.
- Provider: 5mpbileApp/lib/App2/providers/UserProvider.dart وlib/main.dart، مع توسيع إدارة الحالة لتشمل بيانات المكتبة.
- الطبقات وDTOs وRepositories: ملفات EmployeeService.cs وEmployeeRepository.cs تحت 4_ASP_And_EF/Bootcamp_MVC_EF.
- التسجيل في DI ومصادقة Cookies وخدمة الملفات الثابتة: Program.cs في مشروع MVC المرجعي.

لم يُعدّل مشروع المرجع، ولم تُنسخ وظائف المنتجات أو السلة أو الطلبات غير المناسبة لمعنى الاستعارة.
