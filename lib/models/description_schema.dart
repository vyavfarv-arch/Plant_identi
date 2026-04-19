class DescriptionCategory {
  final String number;
  final String title;
  final Map<String, List<String>> subCategories;
  // Mapa przechowująca ścieżki do zdjęć poglądowych dla konkretnych opcji
  final Map<String, String>? referenceImages;

  DescriptionCategory({
    required this.number,
    required this.title,
    required this.subCategories,
    this.referenceImages,
  });
}

class SchemaGenerator {
  static List<DescriptionCategory> getForType(String type) {
    switch (type) {
      case "Grzyb": return _fungusSchema();
      case "Mszaki": return _bryophyteSchema();
      case "Zielona": return _herbaceousSchema();
      default: return _herbaceousSchema();
    }
  }

  static List<DescriptionCategory> _fungusSchema() {
    return [
      DescriptionCategory(
          number: "1",
          title: "Owocnik",
          subCategories: {
            "Forma": ["kapeluszowy", "hubowaty", "maczugowaty", "kulisty"],
            "Powierzchnia kapelusza": ["gładka", "lepka", "kosmata", "łuskowata"],
          },
          referenceImages: {
            "kapeluszowy": "assets/ref/fungus_cap.png",
            "hubowaty": "assets/ref/fungus_shelf.png",
          }
      ),
      DescriptionCategory(
        number: "2",
        title: "Hymenofor",
        subCategories: {
          "Typ": ["rurki", "blaszki", "kolce", "fałdy"],
        },
      ),
    ];
  }

  static List<DescriptionCategory> _bryophyteSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Budowa gametofitu",
        subCategories: {
          "Pokrój": ["listkowaty", "plechowaty"],
          "Ulistnienie": ["dwustronne", "wielostronne"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Sporofit",
        subCategories: {
          "Czepek": ["gładki", "owłosiony"],
          "Puszka": ["kulista", "walcowata", "wygięta"],
        },
      ),
    ];
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