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
      case "Zielne": return _herbaceousSchema();
      case "Drzewo": return _treeSchema();
      case "Krzew": return _shrubSchema();
      case "Krzewinka": return _dwarfShrubSchema();
      default: return _herbaceousSchema();
    }
  }

  static List<DescriptionCategory> _fungusSchema() {
    return [
      DescriptionCategory(
          number: "1",
          title: "Kapelusz / Owocnik",
          subCategories: {
            "Kształt": ["wypukły", "płaski", "wklęsły", "lejkowaty", "stożkowaty"],
            "Powierzchnia": ["sucha", "lepka/śluzowata", "aksamitna", "łuskowata"],
            "Brzeg": ["podwinięty", "prosty", "pofalowany", "prążkowany"],
          }
      ),
      DescriptionCategory(
        number: "2",
        title: "Hymenofor (spód)",
        subCategories: {
          "Typ": ["rurki", "blaszki", "kolce", "listewki", "gładki"],
          "Sposób przyrośnięcia": ["wolne", "zatokowato wycięte", "zbiegające"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Trzon",
        subCategories: {
          "Kształt": ["walcowaty", "bulwiasty", "wrzecionowaty", "pusty w środku"],
          "Pierścień": ["obecny (ruchomy)", "obecny (przyrośnięty)", "brak"],
          "Pochwa u nasady": ["obecna", "brak"],
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Miąższ",
        subCategories: {
          "Zmiana barwy": ["nie zmienia", "sinieje", "czerwienieje", "czernieje"],
          "Mleczko": ["brak", "obecne (białe)", "obecne (pomarańczowe/inne)"],
          "Zapach": ["brak", "grzybowy", "owocowy", "mączny", "nieprzyjemny"],
        },
      ),
    ];
  }

  static List<DescriptionCategory> _bryophyteSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Gametofit (część zielona)",
        subCategories: {
          "Typ budowy": ["listkowaty (mech)", "plechowaty (wątrobowiec)"],
          "Pokrój": ["darnie luźne", "darnie zbite", "płożący", "wzniesiony pierzasto"],
          "Żeberko w listku": ["brak", "pojedyncze", "podwójne"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Sporofit (część zarodniowa)",
        subCategories: {
          "Seta (trzonek)": ["krótka", "długa", "brak"],
          "Puszka": ["z wieczkiem", "otwierająca się szczelinami"],
          "Perystom (uzębienie)": ["obecny", "brak"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Siedlisko",
        subCategories: {
          "Podłoże": ["gleba", "kamienie/skały", "kora drzew", "martwe drewno"],
        },
      ),
    ];
  }

  static List<DescriptionCategory> _dwarfShrubSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Morfologia",
        subCategories: {
          "Wzrost": ["podnoszący się", "płożący", "poduszkowy"],
          "Drewnienie": ["tylko u nasady", "całe pędy"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Liście",
        subCategories: {
          "Typ": ["skórzaste", "wrzosowate (drobne)", "łopatkowate"],
          "Brzeg": ["podwinięty", "piłkowany", "gładki"],
          "Zimozieloność": ["tak", "nie"],
        },
      ),
    ];
  }

  static List<DescriptionCategory> _shrubSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Budowa ogólna",
        subCategories: {
          "Pokrój": ["wzniesiony", "rozłożysty", "płożący", "kulisty"],
          "Gęstość": ["zwarty", "ażurowy", "formujący zarośla"],
          "Pędy": ["proste", "łukowato wygięte", "zygzakowate"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Cechy pędów",
        subCategories: {
          "Uzbrojenie": ["brak", "kolce", "ciernie"],
          "Przekrój": ["obły", "kanciasty"],
          "Rdzeń": ["pełny", "pusty", "komorowy"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Owoce i Kwiaty",
        subCategories: {
          "Rodzaj owocu": ["jagoda", "pestkowiec", "torebka", "pozorny (np. róża)"],
          "Barwa owoców": ["czerwona", "czarna", "niebieska", "żółta", "biała"],
        },
      ),
    ];
  }

  static List<DescriptionCategory> _treeSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Pokrój i Pień",
        subCategories: {
          "Forma korony": ["stożkowata", "kolumnowa", "płacząca", "parasolowata", "nieregularna"],
          "Typ pnia": ["jednopniowy", "wielopniowy", "pochylony"],
          "Wysokość (szacowana)": ["niskie (do 10m)", "średnie (10-20m)", "wysokie (powyżej 20m)"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Kora",
        subCategories: {
          "Struktura": ["gładka", "spękana podłużnie", "łuszcząca się płatami", "z przetchlinkami", "korkowata"],
          "Barwa": ["biała", "szara", "brunatna", "czarniawa", "miedziana"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Liście / Igły",
        subCategories: {
          "Typ": ["liściaste szerokie", "igły", "łuski"],
          "Trwałość": ["sezonowe (zrzucane)", "zimozielone"],
          "Ułożenie igieł": ["pojedyncze", "pęczkowe (po 2, 3, 5)", "zebrane na krótkopędach"],
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Organy rozrodcze",
        subCategories: {
          "Typ": ["szyszki", "owoce mięsiste", "skrzydlaki", "orzechy"],
          "Kwitnienie": ["kotki", "kwiaty okazałe", "niepozorne"],
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
            "Typ": ["palowy", "wiązkowy", "sercowaty", "kłączowy"], // Zmieniono z wiązowy na wiązkowy
            "Głębokość": ["płytki", "średni", "głęboki"],
            "Organy ziemne": ["bulwy", "kłącza", "cebule", "brak"],
          },
          referenceImages: {
           "palowy": "assets/ref/korzen_palowy.png"

          }
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
            "Kształt blaszki": ["igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "łopatowaty", "owalny", "odwrotnie jajowaty", "strzałkowaty", "nerkowy"], // Zmieniłem wielkość liter dla spójności
            "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty"],
            "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
            "Wcięcie": ["wrębne", "dzielne", "klapowate", "sieczne"],
          },
          referenceImages: {

          }
      ),
      DescriptionCategory(
        number: "4",
        title: "Kwiatostany",
        subCategories: {
          "Obecność": ["brak", "obecne", "obecne nierozwinięte"],
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