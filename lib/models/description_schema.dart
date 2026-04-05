class DescriptionCategory {
  final String number;
  final String title;
  final Map<String, List<String>> subCategories;

  DescriptionCategory({required this.number, required this.title, required this.subCategories});
}

class SchemaGenerator {
  static List<DescriptionCategory> getForType(String type) {
    if (type == "Zielona") return _herbaceousSchema();
    // Domyślnie zwraca zielne, dopóki nie dodasz drzew/krzewów
    return _herbaceousSchema();
  }

  static List<DescriptionCategory> _herbaceousSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "System korzeniowy",
        subCategories: {
          "Typ": ["palowy", "wiązowy", "sercowaty", "kłączowy"],
          "Głębokość": ["płytki", "średni", "głęboki"],
          "Organy ziemne": ["bulwy", "kłącza", "cebule", "brak"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Łodyga",
        subCategories: {
          "Typ łodygi": ["zielna", "zdrewniała", "półzdrewniała"],
          "Kształt (przekrój)": ["okrągły", "kanciasty", "bruzdowany", "spłaszczony"],
          "Powierzchnia": ["gładka", "owłosiona", "szorstka", "lepka", "woskowa"],
          "Włoski": ["proste", "gruczołowe", "haczykowate", "kutnerowate"],
          "Barwa": ["zielona", "brunatna", "czerwonawa", "sina"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Liście",
        subCategories: {
          "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
          "Typ liścia": ["pojedynczy", "pierzasty", "dłoniasty"],
          "Kształt blaszki": ["Igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "Łopatowaty", "owalny", "Odwrotnie jajowaty", "strzałkowaty", "nerkowy"],
          "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty"],
          "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
          "Wcięcie": ["Wrębne", "Dzielne", "klapowate", "sieczne"],
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Kwiatostany",
        subCategories: {
          "Obecność": ["Brak", "Obecne", "Obecne nierozwinięte"],
          "Typ Kwiatostanu": ["grono", "wiecha", "baldach", "koszyczek", "kłos", "główka"],
          "Zapach": ["brak", "słaby", "intensywny"],
        },
      ),
      DescriptionCategory(
        number: "5",
        title: "Owoce",
        subCategories: {
          "Typ owocu": ["jagoda", "orzech", "torebka", "niełupka", "strąk"],
          "Smak": ["gorzki", "słodki", "cierpki", "słony", "pikantny"],
        },
      ),
    ];
  }
}