class BaZiHelper {
  static const Map<String, Map<String, String>> _stems = {
    '甲': {'en': 'Jia (Wood)', 'id': 'Jia (Kayu)', 'zh': '甲'},
    '乙': {'en': 'Yi (Wood)', 'id': 'Yi (Kayu)', 'zh': '乙'},
    '丙': {'en': 'Bing (Fire)', 'id': 'Bing (Api)', 'zh': '丙'},
    '丁': {'en': 'Ding (Fire)', 'id': 'Ding (Api)', 'zh': '丁'},
    '戊': {'en': 'Wu (Earth)', 'id': 'Wu (Tanah)', 'zh': '戊'},
    '己': {'en': 'Ji (Earth)', 'id': 'Ji (Tanah)', 'zh': '己'},
    '庚': {'en': 'Geng (Metal)', 'id': 'Geng (Logam)', 'zh': '庚'},
    '辛': {'en': 'Xin (Metal)', 'id': 'Xin (Logam)', 'zh': '辛'},
    '壬': {'en': 'Ren (Water)', 'id': 'Ren (Air)', 'zh': '壬'},
    '癸': {'en': 'Gui (Water)', 'id': 'Gui (Air)', 'zh': '癸'},
  };

  static const Map<String, Map<String, String>> _branches = {
    '子': {'en': 'Zi (Rat)', 'id': 'Zi (Tikus)', 'zh': '子'},
    '丑': {'en': 'Chou (Ox)', 'id': 'Chou (Kerbau)', 'zh': '丑'},
    '寅': {'en': 'Yin (Tiger)', 'id': 'Yin (Macan)', 'zh': '寅'},
    '卯': {'en': 'Mao (Rabbit)', 'id': 'Mao (Kelinci)', 'zh': '卯'},
    '辰': {'en': 'Chen (Dragon)', 'id': 'Chen (Naga)', 'zh': '辰'},
    '巳': {'en': 'Si (Snake)', 'id': 'Si (Ular)', 'zh': '巳'},
    '午': {'en': 'Wu (Horse)', 'id': 'Wu (Kuda)', 'zh': '午'},
    '未': {'en': 'Wei (Goat)', 'id': 'Wei (Kambing)', 'zh': '未'},
    '申': {'en': 'Shen (Monkey)', 'id': 'Shen (Monyet)', 'zh': '申'},
    '酉': {'en': 'You (Rooster)', 'id': 'You (Ayam)', 'zh': '酉'},
    '戌': {'en': 'Xu (Dog)', 'id': 'Xu (Anjing)', 'zh': '戌'},
    '亥': {'en': 'Hai (Pig)', 'id': 'Hai (Babi)', 'zh': '亥'},
  };

  static String localize(String char, String languageCode) {
    if (languageCode == 'zh') return char;

    // Check stems
    if (_stems.containsKey(char)) {
      return _stems[char]?[languageCode] ?? _stems[char]?['en'] ?? char;
    }
    // Check branches
    if (_branches.containsKey(char)) {
      return _branches[char]?[languageCode] ?? _branches[char]?['en'] ?? char;
    }

    return char;
  }

  static String localizePillar(String pillar, String languageCode) {
    if (pillar.length != 2) return pillar;
    final stem = pillar[0];
    final branch = pillar[1];
    return '${localize(stem, languageCode)} ${localize(branch, languageCode)}';
  }
}
