class DescriptionCategory {
  final String number;
  final String title;
  final Map<String, List<String>> subCategories;
  // Mapa przechowująca ścieżki do zdjęć poglądowych dla konkretnych opcji
  final Map<String, String>? referenceImages;
  final Map<String, String>? imageDescriptions;

  DescriptionCategory({
    required this.number,
    required this.title,
    required this.subCategories,
    this.referenceImages,
    this.imageDescriptions,
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


  static List<DescriptionCategory> _shrubSchema() {
    return [
      DescriptionCategory(
        number: "1",
        title: "Pokrój i struktura",
        subCategories: {
          "Forma wzrostu": ["wzniesiony", "rozłożysty", "płożący", "zwisający", "pnący"],
          "Wysokość": ["niski (<0.5m)", "średni (0.5-2m)", "wysoki (>2m)"],
          "Gęstość korony": ["zwarta", "ażurowa", "bardzo gęsta"],
          "Sposób krzewienia": ["od nasady", "powyżej gruntu", "odroślowy"],
        },
      ),
      DescriptionCategory(
        number: "2",
        title: "Pędy i Kora",
        subCategories: {
          "Kora na starych pędach": ["gładka", "spękana", "łuszcząca się płatami", "włóknista"],
          "Pędy": ["obłe", "kanciaste", "listewkowate", "owłosione", "oszronione"],
          "Barwa pędów": ["zielona", "czerwona", "oliwkowa", "brunatna", "szara"],
          "Przetchlinki": ["brak", "wyraźne", "punktowe", "soczewkowate"],
          "Uzbrojenie": ["brak", "ciernie", "kolce"],
          "Rdzeń": ["pełny", "pusty", "komorowy", "blaszkowaty"],
        },
      ),
      DescriptionCategory(
        number: "3",
        title: "Pąki ",
        subCategories: {
          "Ułożenie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
          "Kształt": ["kuliste", "jajowate", "wrzecionowate", "stożkowate"],
          "Łuski": ["nagusie (brak łusek)", "jedna łuska", "liczne łuski", "owłosione"],
          "Pąk szczytowy": ["obecny", "brak (pseudoterminalny)"],
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Liście",
        subCategories: {
          "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
          "Typ liścia": ["niepodzielne","wrębne", "dzielne", "klapowate", "sieczne", "pierzasty", "dłoniasty"],
          "Kształt blaszki": ["igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "łopatowaty", "owalny", "odwrotnie jajowaty", "strzałkowaty", "nerkowy"],
          "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty","podwójnie pikowany","podwójnie ząbkowany", "podwójnie karbowany"],
          "Powierzchnia": ["naga", "owłosiona (spód)", "owłosiona (obie strony)", "skórzasta", "woskowa"],
        },
      ),
      DescriptionCategory(
        number: "5",
        title: "Kwiaty i Kwiatostany",
        subCategories: {
          "Płeć": ["obupłciowe", "jednopienne", "dwupienne"],
          "Typ kwiatostanu": ["pojedyncze", "grono", "baldach", "wiecha", "kotki (bazie)"],
          "Barwa korony": ["biała", "żółta", "różowa", "czerwona", "fioletowa", "zielonkawa"],
        },
      ),
      DescriptionCategory(
        number: "6",
        title: "Owoce i Nasiona",
        subCategories: {
          "Typ owocu": ["jagoda", "pestkowiec", "torebka", "skrzydlak", "orzech", "szupinkowy"],
          "Barwa owocu": ["czerwona", "czarna", "niebieska/sina", "żółta", "biała", "brązowa"],
          "Smak": ["gorzki", "słodki", "cierpki", "słony", "pikantny"],
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
          "Forma korony": ["stożkowata", "kolumnowa", "płaskokulista", "płacząca", "parasolowata", "jajowata"],
          "Typ rozgałęziania": ["pęd główny dominuje", "brak wyraźnego przewodnika"],
          "Pień": ["jednopniowy", "wielopniowy", "rozwidlowany (widlasty)", "zbieżysty (mocno zwężający się)"],
        },
          referenceImages: {

          }
      ),
      DescriptionCategory(
        number: "2",
        title: "Kora",
        subCategories: {
          "Struktura": ["gładka","spękana", "spękana podłużnie", "łuszcząca się płatami", "z przetchlinkami"],
          "Barwa korowiny": ["srebrzystobiała", "popielata", "oliwkowa", "miedziana", "brunatna", "czarniawa"],
        },
          referenceImages: {
            "gładka": "assets/ref/drzewo/kora/kora_gladka.png",
            "łuszcząca się płatami": "assets/ref/drzewo/kora/kora_odchodzaca.png",
            "spękana": "assets/ref/drzewo/kora/kora_spekana.png",
            "z przetchlinkami": "assets/ref/drzewo/kora/kora_z_przetchlinakmi.png",
            "spękana podłużnie": "assets/ref/drzewo/kora/kora_spekana_podluznie.png"
          },
          imageDescriptions: {
            "łuszcząca się płatami": "Kora oddzielająca się od pnia w postaci cienkich lub grubych płatów (np. u platana lub brzozy).",
            "gładka": "Powierzchnia pnia pozbawiona wyraźnych spękań i wyniosłości.",
            "spękana": "Kora z wyraźnymi, nieregularnymi pęknięciami na powierzchni.",
            "z przetchlinkami": "Obecność małych otworów (przetchlinek) służących do wymiany gazowej, widocznych często jako kreski lub kropki.",
            "spękana podłużnie": "Głębokie bruzdy biegnące wzdłuż pnia drzewa."
          }
      ),
      DescriptionCategory(
        number: "3",
        title: "Liście",
        subCategories: {
          "Trwałość": ["sezonowe (zrzucane)", "zimozielone"],
          "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
          "Typ liścia": ["niepodzielne","wrębne", "dzielne", "klapowate", "sieczne", "pierzasty", "dłoniasty"],
          "Kształt blaszki": ["igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "łopatowaty", "owalny", "odwrotnie jajowaty", "strzałkowaty", "nerkowy"],
          "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty"],
          "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Organy rozrodcze",
        subCategories: {
          "Typ": ["szyszki", "owoce mięsiste", "skrzydlaki", "orzechy"],
          "Kwitnienie": ["kotki", "kwiaty okazałe", "niepozorne"],
          "System płciowy": ["jednopienne", "dwupienne", "obupłciowe"],
          "Kwiatostany": ["bazie", "wiechy", "baldachy", "pęczki", "szyszki męskie"],
          "Osadzenie": ["siedzące", "na szypułkach", "wzniesione", "zwisające"],
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
            "Typ": ["palowy", "wiązkowy", "kłączowy","bulwy", "cebula"],
            "Głębokość": ["płytki", "średni", "głęboki"]
          },
        referenceImages: {
          "palowy": "assets/ref/zielne/korzen/korzen_palowy.png",
          "wiązkowy": "assets/ref/zielne/korzen/korzen_wiazkowy.png",
          "kłączowy": "assets/ref/zielne/korzen/korzen_palowy.png",
          "bulwy": "assets/ref/zielne/korzen/korzen_bulwa.png",
          "cebula": "assets/ref/zielne/korzen/korzen_cebula.png"
        },
        imageDescriptions: {
          "palowy": "System z jednym wyraźnym korzeniem głównym rosnącym pionowo w dół i mniejszymi korzeniami bocznymi.",
          "wiązkowy": "Liczne korzenie o podobnej grubości wyrastające pęczkiem z nasady pędu, typowe dla traw i roślin jednoliściennych.",
          "kłączowy": "Podziemny pęd rosnący poziomo, pełniący funkcję spichrzową, z którego wyrastają korzenie przybyszowe.",
          "bulwy": "Zgrubiałe części podziemne (pędu lub korzenia) magazynujące substancje zapasowe.",
          "cebula": "Podziemny organ spichrzowy o silnie skróconej łodydze i mięsistych liściach (np. u czosnku lub tulipana).",
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
          "Mleczko": ["przezroczyste", "białe"],
        },
      ),
      DescriptionCategory(
          number: "3",
          title: "Liście",
          subCategories: {
            "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
            "Typ liścia": ["niepodzielne","wrębne", "dzielne", "klapowate", "sieczne", "pierzasty", "dłoniasty"],
            "Kształt blaszki": ["igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "łopatowaty", "owalny", "odwrotnie jajowaty", "strzałkowaty", "nerkowy"],
            "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty","podwójnie pikowany","podwójnie ząbkowany", "podwójnie karbowany"],
            "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
          },
          referenceImages: {
            "skrętoległe": "assets/ref/zielne/liscie/lisc_skretolegly.png","naprzeciwległe": "assets/ref/zielne/liscie/liscie_naprzeciwlegle.png","okółkowe": "assets/ref/zielne/liscie/lisc_okolkowe.png",
            "pierzaste": "assets/ref/zielne/liscie/lisc_pierzasty.png","równoległe": "assets/ref/zielne/liscie/lisc_rownolegly.png","dłoniaste": "assets/ref/zielne/liscie/lisc_dloniasty.png",
          }
      ),
      DescriptionCategory(
        number: "4",
        title: "Kwiatostany",
        subCategories: {
          "Typ Kwiatostanu": ["grono","baldachogrono", "wiecha", "baldach", "koszyczek", "kłos", "główka","baldach podwójny","kłos złożony","sierpik","wachlarz","wiechotka", "wiechotka złożona"],
          "Zapach": ["brak", "słaby", "intensywny"],
        },
          referenceImages: {
            "grono": "assets/ref/zielne/kwiat/grono.png","baldachogrono": "assets/ref/zielne/kwiat/baldachogrono.png","baldach podwójny": "assets/ref/zielne/kwiat/kwiat_baldach_podwojny.png",
            "baldach": "assets/ref/zielne/kwiat/kwiat_baldach.png","główka": "assets/ref/zielne/kwiat/kwiat_glowka.png","kłos": "assets/ref/zielne/kwiat/kwiat_klos.png","kłos złożony": "assets/ref/zielne/kwiat/kwiat_klos_zlozony.png",
            "koszyczek": "assets/ref/zielne/kwiat/kwiat_koszyk.png","sierpik": "assets/ref/zielne/kwiat/kwiat_sierpik.png","wachlarz": "assets/ref/zielne/kwiat/kwiat_wachlarz.png","wiecha": "assets/ref/zielne/kwiat/kwiat_wiecha.png","wiechotka": "assets/ref/zielne/kwiat/kwiat_wiechotka.png","wiechotka złożona": "assets/ref/zielne/kwiat/kwiat_wiechotka_wielo.PNG",
          }
      ),
      DescriptionCategory(
        number: "5",
        title: "Owoce",
        subCategories: {
          "Typ owocu": ["jagoda", "torebka", "niełupka", "strąk"],
          "Smak": ["gorzki", "słodki", "cierpki", "słony", "pikantny"],
        },
        referenceImages: {
          "jagoda": "assets/ref/zielne/owoce/owoce_jagoda.png",
          "torebka": "assets/ref/zielne/owoce/owoc_torebka.png",
          "niełupka": "assets/ref/zielne/owoce/owoc_nielupka.png",
          "strąk": "assets/ref/zielne/owoce/owoc_strak.png",
        },
        imageDescriptions: {
          "jagoda": "Owoc mięsisty, wielonasienny, o cienkiej skórce (np. borówka).",
          "orzech": "Owoc suchy, niepękający, o zdrewniałej owocni.",
          "torebka": "Owoc suchy, pękający, wielonasienny.",
          "niełupka": "Owoc suchy, jednonasienny, o skórzastej owocni (np. słonecznik).",
          "strąk": "Owoc suchy, pękający dwoma szwami (np. fasola).",
        },
      ),
    ];
  }
}