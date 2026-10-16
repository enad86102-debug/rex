// Arabic first. Keep copy centralized until the reviewed localization catalog.
abstract final class RexStrings {
  static const title = 'REX';
  static const entry = 'أهلًا بك في ركس';
  static const guest = 'الدخول كضيف';
  static const guestNotice =
      'تُحفظ جلسة الضيف على هذا الجهاز. استعادة الحساب على جهاز آخر غير متاحة حاليًا.';
  static const home = 'مجلس ركس';
  static const privateTable = 'طاولة خاصة';
  static const invite = 'رمز الدعوة';
  static const join = 'الانضمام إلى الطاولة';
  static const create = 'إنشاء طاولة';
  static const leave = 'مغادرة الطاولة';
  static const logout = 'تسجيل الخروج';
  static const logoutNotice =
      'تسجيل الخروج يُنهي جلسة الضيف. لن تتمكن من استعادة هذه الهوية حاليًا. هل تريد المتابعة؟';
  static const cancel = 'إلغاء';
  static const retry = 'إعادة المحاولة';
  static const ready = 'أنا جاهز';
  static const notReady = 'إلغاء الجاهزية';
  static const waiting = 'بانتظار لاعب';
  static const copy = 'نسخ الدعوة';
  static const copied = 'نُسخ رمز الدعوة';
  static const unavailable =
      'يمكن تجهيز طاولة خاصة ودعوة اللاعبين. اللعب غير متاح حاليًا.';
  static const seats = ['الشمال', 'الشرق', 'الجنوب', 'الغرب'];
  static String game(String value) =>
      value == 'tarneeb' ? 'طرنيب' : 'تركس كومبلكس';
  static String failure(String code) => switch (code) {
    'unauthorized' => 'انتهت الجلسة. يرجى الدخول من جديد.',
    'not_found' => 'الطاولة أو الدعوة غير متاحة. تحقّق من الرمز.',
    'table_full' => 'الطاولة مكتملة بأربعة لاعبين.',
    'conflict' => 'تغيّرت حالة الطاولة. حُدّثت البيانات؛ أعد المحاولة.',
    'invalid_input' => 'تحقّق من البيانات وأعد المحاولة.',
    'rate_limited' => 'طلبات كثيرة. انتظر دقيقة ثم أعد المحاولة.',
    'pending_action' => 'هناك طلب لم تُحسم نتيجته. أعد المحاولة أولًا.',
    'rules_not_approved' => 'اللعب غير متاح حاليًا.',
    'secure_storage_or_response_failed' =>
      'تعذّر حفظ الجلسة أو قراءة البيانات بأمان. أعد المحاولة.',
    _ => 'تعذّر الاتصال بالخدمة. تحقّق من الشبكة وأعد المحاولة.',
  };
}
