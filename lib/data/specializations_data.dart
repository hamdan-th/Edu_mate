class SpecializationItem {
  final String id;
  final String name;
  final String college;

  const SpecializationItem({
    required this.id,
    required this.name,
    required this.college,
  });
}

const List<String> collegesList = [
  'كلية الطب البشري',
  'العلوم الطبية والصحية',
  'الهندسة وتكنولوجيا المعلومات',
  'العلوم الإدارية والإنسانية',
];

const List<SpecializationItem> specializationsList = [
  // كلية الطب البشري
  SpecializationItem(
    id: 'medicine',
    name: 'طب بشري',
    college: 'كلية الطب البشري',
  ),

  // العلوم الطبية والصحية
  SpecializationItem(
    id: 'dentistry',
    name: 'طب وجراحة الفم والأسنان',
    college: 'العلوم الطبية والصحية',
  ),
  SpecializationItem(
    id: 'nursing',
    name: 'التمريض',
    college: 'العلوم الطبية والصحية',
  ),
  SpecializationItem(
    id: 'lab',
    name: 'المختبرات',
    college: 'العلوم الطبية والصحية',
  ),
  SpecializationItem(
    id: 'pharmacy',
    name: 'الصيدلة',
    college: 'العلوم الطبية والصحية',
  ),

  // الهندسة وتكنولوجيا المعلومات
  SpecializationItem(
    id: 'electronics',
    name: 'هندسة إلكترونيات',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),
  SpecializationItem(
    id: 'telecom',
    name: 'هندسة اتصالات',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),
  SpecializationItem(
    id: 'computer_engineering',
    name: 'هندسة حاسوب',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),
  SpecializationItem(
    id: 'it',
    name: 'تقنية معلومات',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),
  SpecializationItem(
    id: 'cs',
    name: 'علوم الحاسوب',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),
  SpecializationItem(
    id: 'is',
    name: 'نظم المعلومات',
    college: 'الهندسة وتكنولوجيا المعلومات',
  ),

  // العلوم الإدارية والإنسانية
  SpecializationItem(
    id: 'business',
    name: 'إدارة أعمال',
    college: 'العلوم الإدارية والإنسانية',
  ),
  SpecializationItem(
    id: 'accounting',
    name: 'محاسبة',
    college: 'العلوم الإدارية والإنسانية',
  ),
  SpecializationItem(
    id: 'marketing',
    name: 'تسويق',
    college: 'العلوم الإدارية والإنسانية',
  ),
  SpecializationItem(
    id: 'mis',
    name: 'نظم معلومات إدارية',
    college: 'العلوم الإدارية والإنسانية',
  ),
  SpecializationItem(
    id: 'media',
    name: 'إعلام',
    college: 'العلوم الإدارية والإنسانية',
  ),
  SpecializationItem(
    id: 'law',
    name: 'قانون',
    college: 'العلوم الإدارية والإنسانية',
  ),
];