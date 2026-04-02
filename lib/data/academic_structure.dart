class SpecializationItem {
  final String id;
  final String name;

  const SpecializationItem({
    required this.id,
    required this.name,
  });
}

class CollegeItem {
  final String id;
  final String name;
  final List<SpecializationItem> specializations;

  const CollegeItem({
    required this.id,
    required this.name,
    required this.specializations,
  });
}

class AcademicStructure {
  static const List<CollegeItem> colleges = [
    CollegeItem(
      id: 'engineering_it',
      name: 'الهندسة وتكنولوجيا المعلومات',
      specializations: [
        SpecializationItem(id: 'ai', name: 'الذكاء الاصطناعي'),
        SpecializationItem(id: 'cs', name: 'علوم الحاسوب'),
        SpecializationItem(id: 'it', name: 'تقنية المعلومات'),
        SpecializationItem(id: 'software', name: 'هندسة البرمجيات'),
        SpecializationItem(id: 'cyber', name: 'الأمن السيبراني'),
        SpecializationItem(id: 'network', name: 'الشبكات'),
      ],
    ),
    CollegeItem(
      id: 'medicine',
      name: 'كلية الطب البشري',
      specializations: [
        SpecializationItem(id: 'medicine', name: 'طب بشري'),
      ],
    ),
    CollegeItem(
      id: 'dentistry',
      name: 'كلية طب الأسنان',
      specializations: [
        SpecializationItem(id: 'dentistry', name: 'طب الأسنان'),
      ],
    ),
    CollegeItem(
      id: 'pharmacy',
      name: 'كلية الصيدلة',
      specializations: [
        SpecializationItem(id: 'pharmacy', name: 'صيدلة'),
      ],
    ),
    CollegeItem(
      id: 'business',
      name: 'كلية العلوم الإدارية',
      specializations: [
        SpecializationItem(id: 'accounting', name: 'محاسبة'),
        SpecializationItem(id: 'management', name: 'إدارة أعمال'),
        SpecializationItem(id: 'finance', name: 'تمويل ومصارف'),
        SpecializationItem(id: 'marketing', name: 'تسويق'),
      ],
    ),
    CollegeItem(
      id: 'law_sharia',
      name: 'كلية الشريعة والقانون',
      specializations: [
        SpecializationItem(id: 'law', name: 'قانون'),
        SpecializationItem(id: 'sharia', name: 'شريعة'),
      ],
    ),
    CollegeItem(
      id: 'arts_humanities',
      name: 'كلية الآداب والعلوم الإنسانية',
      specializations: [
        SpecializationItem(id: 'arabic', name: 'لغة عربية'),
        SpecializationItem(id: 'english', name: 'لغة إنجليزية'),
        SpecializationItem(id: 'history', name: 'تاريخ'),
        SpecializationItem(id: 'media', name: 'إعلام'),
      ],
    ),
  ];
}