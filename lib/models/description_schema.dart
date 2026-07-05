// lib/models/description_schema.dart

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Dostarcza kompleksowe schematy, kategorie oraz cechy taksonomiczne z podziałem
 * na typy biologiczne (Drzewo, Krzew, Zielne, Grzyb, Mszaki). Pełni funkcję
 * bazy dydaktycznej (podpowiedzi edukacyjne), dostarczając opisy cech morfologicznych
 * oraz ścieżki do grafik referencyjnych ułatwiających terenową identyfikację.
 * Zaktualizowany o dynamiczne filtrowanie struktur na podstawie etapu fenologicznego.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów innych plików z /lib. Stanowi zamkniętą, niezależną
 * strukturę wiedzy morfologicznej (klucz oznaczeń), z której korzystają formularze
 * oraz ekrany identyfikacji (warstwa widoków).
 * ============================================================================
 */

class DescriptionCategory {
  final String number;
  final String title;
  final Map<String, List<String>> subCategories;
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
  // POPRAWKA: Dodanie parametru phenologicalStage do inteligentnego filtrowania cech organów
  static List<DescriptionCategory> getForType(String type, {String? phenologicalStage}) {
    List<DescriptionCategory> categories;
    switch (type) {
      case "Grzyb": return _fungusSchema();
      case "Mszaki": return _bryophyteSchema();
      case "Zielne": categories = _herbaceousSchema(); break;
      case "Drzewo": categories = _treeSchema(); break;
      case "Krzew": categories = _shrubSchema(); break;
      default: categories = _herbaceousSchema(); break;
    }

    // Jeśli etap fenologiczny nie został określony, zwracamy pełny schemat bazowy
    if (phenologicalStage == null || phenologicalStage.isEmpty) {
      return categories;
    }

    List<DescriptionCategory> filtered = [];
    for (var cat in categories) {
      final title = cat.title.toLowerCase().trim();

      // REGÓŁA 1: W fazie czysto wegetatywnej ukrywamy wszelkie organy generatywne (kwiaty, owoce)
      if (phenologicalStage == "Wegetatywny") {
        if (title.contains("kwiat") || title.contains("owoc") || title.contains("rozrodcze")) {
          continue;
        }
      }
      // REGÓŁA 2: W fazie pączkowania i kwitnienia ukrywamy rozwinięte owoce, ale zostawiamy kwiaty
      else if (phenologicalStage == "Pączkowanie" || phenologicalStage == "Kwitnienie") {
        if (title.contains("owoc")) {
          continue;
        }
        // Dla drzew (kategoria połączona): odfiltrowujemy wyłącznie podkategorię "Typ" zawierającą owoce
        if (title == "organy rozrodcze") {
          final newSub = Map<String, List<String>>.from(cat.subCategories)..remove("Typ");
          filtered.add(DescriptionCategory(
            number: cat.number,
            title: cat.title,
            subCategories: newSub,
            referenceImages: cat.referenceImages,
            imageDescriptions: cat.imageDescriptions,
          ));
          continue;
        }
      }
      // REGÓŁA 3: W fazie owocowania i rozsiewania nasion ukrywamy świeże kwiaty, eksponujemy owoce
      else if (phenologicalStage == "Owocowanie" || phenologicalStage == "Rozsiewanie") {
        if (title == "kwiatostany" || title == "kwiaty i kwiatostany") {
          continue;
        }
        // Dla drzew: odfiltrowujemy podkategorie czysto kwitnieniowe z organów rozrodczych
        if (title == "organy rozrodcze") {
          final newSub = Map<String, List<String>>.from(cat.subCategories)
            ..remove("Kwitnienie")
            ..remove("Kwiatostany");
          filtered.add(DescriptionCategory(
            number: cat.number,
            title: cat.title,
            subCategories: newSub,
            referenceImages: cat.referenceImages,
            imageDescriptions: cat.imageDescriptions,
          ));
          continue;
        }
      }
      // REGÓŁA 4: W stanie spoczynku zimowego ukrywamy liście oraz organy generatywne (zostaje kora, pędy, pąki zimowe)
      else if (phenologicalStage == "Spoczynek") {
        if (title.contains("kwiat") || title.contains("owoc") || title.contains("rozrodcze") || title == "liście") {
          continue;
        }
      }

      filtered.add(cat);
    }
    return filtered;
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
          "stożkowata": "assets/grass.png", "kolumnowa": "assets/grass.png", "płaskokulista": "assets/grass.png",
          "płacząca": "assets/grass.png", "parasolowata": "assets/grass.png", "jajowata": "assets/grass.png",
          "pęd główny dominuje": "assets/grass.png", "brak wyraźnego przewodnika": "assets/grass.png",
          "jednopniowy": "assets/grass.png", "wielopniowy": "assets/grass.png",
          "rozwidlowany (widlasty)": "assets/grass.png", "zbieżysty (mocno zwężający się)": "assets/grass.png",
        },
        imageDescriptions: {
          "stożkowata": "Korona o szerokiej nasadzie, wyraźnie zwężająca się ku górze, przypominająca kształt stożka (typowa dla wielu iglaków).",
          "kolumnowa": "Korona wąska i wysoka, o zbliżonej szerokości na całej długości pnia.",
          "płaskokulista": "Korona o zarysie kolistym, jednak wyraźnie spłaszczona w górnej części.",
          "płacząca": "Forma, w której gałęzie i pędy boczne zwisają pionowo w dół (np. u wierzby płaczącej).",
          "parasolowata": "Korona szeroka i płaska na szczycie, z pędami rozrastającymi się poziomo, przypominająca otwarty parasol.",
          "jajowata": "Korona najszersza w dolnej lub środkowej części, o zaokrąglonym dole i szczycie.",
          "pęd główny dominuje": "Wzrost monopodialny, gdzie główny pień (przewodnik) rośnie pionowo i dominuje nad cieńszymi gałęziami bocznymi.",
          "brak wyraźnego przewodnika": "Pień rozwidla się nisko na kilka niemal równorzędnych konarów, tworząc rozłożystą strukturę bez pędu głównego.",
          "jednopniowy": "Drzewo wykształca tylko jeden, wyraźny pień główny wyrastający bezpośrednio z ziemi.",
          "wielopniowy": "Roślina posiada kilka pni o podobnej grubości, wyrastających obok siebie z tego samego systemu korzeniowego.",
          "rozwidlowany (widlasty)": "Pień, który na pewnej wysokości dzieli się na dwa główne, symetryczne ramiona (widły).",
          "zbieżysty (mocno zwężający się)": "Cecha pnia, którego średnica bardzo gwałtownie maleje wraz z wysokością (pienność zbieżysta).",
        },
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
          "Typ liścia": ["niepodzielne","wrębne", "dzielne", "klapowate", "sieczne", "złożone"],
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
          "kłączowy": "assets/ref/zielne/korzen/korzen_klacze.png",
          "bulwy": "assets/ref/zielne/korzen/korzen_bulwa.png",
          "cebula": "assets/ref/zielne/korzen/korzen_cebula.png",
          "płytki": "assets/ref/zielne/korzen/korzen_plytki.png",
          "średni": "assets/ref/zielne/korzen/korzen_sredni.png",
          "głęboki": "assets/ref/zielne/korzen/korzen_gleboki.png",
        },
        imageDescriptions: {
          "palowy": "System z jednym wyraźnym korzeniem głównym rosnącym pionowo w dół i mniejszymi korzeniami bocznymi.",
          "wiązkowy": "Liczne korzenie o podobnej grubości wyrastające pęczkiem z nasady pędu, typowe dla traw i roślin jednoliściennych.",
          "kłączowy": "Podziemny pęd rosnący poziomo, pełniący funkcję spichrzową, z którego wyrastają korzenie przybyszowe.",
          "bulwy": "Zgrubiałe części podziemne (pędu lub korzenia) magazynujące substancje zapasowe.",
          "cebula": "Podziemny organ spichrzowy o silnie skróconej łodydze i mięsistych liściach (np. u czosnku lub tulipana).",
          "płytki": "System korzeniowy rozwijający się głównie w wierzchniej warstwie gleby (do ok. 15-20 cm). Roślina jest łatwa do wyrwania, ale wrażliwa na przesuszenie powierzchni gruntu.",
          "średni": "Korzenie sięgające umiarkowanej głębokości profilu glebowego (ok. 20-50 cm), zapewniające stabilne zakotwiczenie i dostęp do wilgoci.",
          "głęboki": "Korzenie penetrujące glebę na głębokość powyżej 50 cm. Pozwala to roślinie przetrwać susze dzięki dostępowi do głębszych zasobów wody podziemnej.",
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
          "Mleczko": ["przezroczyste", "białe","inne"],
        },
        referenceImages: {
          "zielna": "assets/ref/zielne/lodyga/lodyga_zielna.png", "zdrewniała": "assets/grass.png", "półzdrewniała": "assets/grass.png",
          "okrągły": "assets/grass.png", "kanciasty": "assets/grass.png", "bruzdowany": "assets/grass.png", "spłaszczony": "assets/grass.png",
          "gładka": "assets/grass.png", "owłosiona": "assets/grass.png", "szorstka": "assets/grass.png", "lepka": "assets/grass.png", "woskowa": "assets/grass.png",
          "proste": "assets/grass.png", "gruczołowe": "assets/grass.png", "haczykowate": "assets/grass.png", "kutnerowate": "assets/grass.png",
          "zielona": "assets/grass.png", "brunatna": "assets/grass.png", "czerwonawa": "assets/grass.png", "sina": "assets/grass.png",
          "przezroczyste": "assets/grass.png", "białe": "assets/grass.png",
        },
        imageDescriptions: {
          "zielna": "Łodyga miękka, soczysta, zwykle zielona, obumierająca po zakończeniu sezonu wegetacyjnego.",
          "zdrewniała": "Twarda łodyga pokryta warstwą korka lub kory, charakterystyczna dla krzewów i drzew.",
          "półzdrewniała": "Łodyga, której dolna część drewnieje i jest trwała, natomiast górna pozostaje zielna i obumiera na zimę.",
          "okrągły": "Przekrój poprzeczny łodygi o kształcie zbliżonym do koła, bez wyraźnych krawędzi.",
          "kanciasty": "Obecność wyraźnych podłużnych krawędzi (np. łodyga czworokątna u roślin jasnotowatych).",
          "bruzdowany": "Powierzchnia łodygi z wyraźnymi, podłużnymi wgłębieniami i rynienkami.",
          "spłaszczony": "Łodyga wyraźnie szersza w jednej osi, często o formie wstęgowatej.",
          "gładka": "Powierzchnia pozbawiona włosków, brodawek i innych wyraźnych nierówności.",
          "owłosiona": "Pokryta różnego rodzaju włoskami (epidermą), które mogą pełnić funkcję ochronną.",
          "szorstka": "Nieprzyjemna w dotyku przez obecność sztywnych włosków lub wysycenie krzemionką.",
          "lepka": "Pokryta wydzieliną gruczołowatą, która klei się przy dotyku (często bariera dla owadów).",
          "woskowa": "Pokryta warstwą matowego nalotu (kutikuli), który można zetrzeć palcem; chroni przed parowaniem.",
          "proste": "Pojedyncze, nierozgałęzione włoski wyrastające z powierzchni łodygi.",
          "gruczołowe": "Włoski zakończone główką wydzielniczą, często zawierającą olejki eteryczne.",
          "haczykowate": "Sztywne włoski zakrzywione na końcach, ułatwiające roślinie wspinanie się lub czepianie.",
          "kutnerowate": "Bardzo gęste, splątane i miękkie włoski tworzące warstwę przypominającą filc.",
          "zielona": "Naturalna barwa łodygi wynikająca z obecności chlorofilu w tkankach.",
          "brunatna": "Ciemne zabarwienie, często pojawiające się u starszych roślin lub przy nasadzie pędu.",
          "czerwonawa": "Zabarwienie spowodowane obecnością antocyjanów, często reakcja na silne nasłonecznienie.",
          "sina": "Niebieskawo-zielony lub szary odcień nadany przez grubą warstwę wosku.",
          "przezroczyste": "Wypływający po uszkodzeniu bezbarwny, wodnisty sok roślinny.",
          "białe": "Gęsty, nieprzezroczysty płyn (lateks) wypływający z rurek mlecznych po przerwaniu tkanki.",
        },

      ),
      DescriptionCategory(
        number: "3",
        title: "Liście",
        subCategories: {
          "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
          "Typ liścia": ["niepodzielne","wrębne", "dzielne", "klapowate", "sieczne"],
          "Kształt blaszki": ["igiełkowy", "równowąski", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "łopatowaty", "owalny", "odwrotnie jajowaty", "strzałkowaty", "nerkowy"],
          "Brzeg Liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty","podwójnie pikowany","podwójnie ząbkowany", "podwójnie karbowany"],
          "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
        },referenceImages: {
        "skrętoległe": "assets/ref/zielne/liscie/lisc_skretolegly.png",
        "naprzeciwległe": "assets/ref/zielne/liscie/liscie_naprzeciwlegle.png",
        "okółkowe": "assets/ref/zielne/liscie/lisc_okolkowe.png",
        "niepodzielne": "assets/grass.png", "wrębne": "assets/grass.png", "dzielne": "assets/grass.png",
        "klapowate": "assets/grass.png", "sieczne": "assets/grass.png",
        "pierzasty": "assets/ref/zielne/liscie/lisc_pierzasty.png",
        "dłoniasty": "assets/ref/zielne/liscie/lisc_dloniasty.png",
        "igiełkowy": "assets/grass.png", "równowąski": "assets/grass.png", "lancetowaty": "assets/grass.png",
        "eliptyczny": "assets/grass.png", "jajowaty": "assets/grass.png", "sercowaty": "assets/grass.png",
        "łopatowaty": "assets/grass.png", "owalny": "assets/grass.png", "odwrotnie jajowaty": "assets/grass.png",
        "strzałkowaty": "assets/grass.png", "nerkowy": "assets/grass.png",
        "całobrzegi": "assets/grass.png", "piłkowany": "assets/grass.png", "ząbkowany": "assets/grass.png",
        "karbowany": "assets/grass.png", "falisty": "assets/grass.png", "kolczasty": "assets/grass.png",
        "podwójnie pikowany": "assets/grass.png", "podwójnie ząbkowany": "assets/grass.png", "podwójnie karbowany": "assets/grass.png",
        "pierzaste": "assets/ref/zielne/liscie/lisc_pierzasty.png",
        "dłoniaste": "assets/ref/zielne/liscie/lisc_dloniasty.png",
        "równoległe": "assets/ref/zielne/liscie/lisc_rownolegly.png",
      },
        imageDescriptions: {
          "skrętoległe": "Liście wyrastają pojedynczo z węzłów, tworząc spiralę wokół łodygi.",
          "naprzeciwległe": "Z jednego węzła wyrastają dwa liście położone po przeciwnych stronach łodygi.",
          "okółkowe": "Z jednego węzła wyrastają co najmniej trzy liście, tworząc pierścień (okółek) dookoła pędu.",
          "niepodzielne": "Blaszka liściowa o ciągłym obrysie, bez głębokich wcięć sięgających nerwu głównego.",
          "wrębne": "Wcięcia w blaszce są płytkie, sięgają nie dalej niż do 1/4 odległości od brzegu do nerwu głównego.",
          "dzielne": "Głębokie wcięcia sięgające do około połowy szerokości blaszki liściowej.",
          "klapowate": "Wcięcia blaszki sięgają głębiej niż u liścia wrębnego, ale nie dochodzą do połowy blaszki.",
          "sieczne": "Bardzo głębokie wcięcia sięgające niemal do samego nerwu głównego lub nasady liścia.",
          "pierzasty": "Liść złożony z mniejszych listków wyrastających parami wzdłuż wspólnej osi (ogonka pomocniczego).",
          "dłoniasty": "Listki lub klapy liścia wyrastają promieniście z jednego wspólnego punktu u nasady ogonka.",
          "igiełkowy": "Liście bardzo wąskie, sztywne i zwykle ostro zakończone, przypominające igły (np. u iglaków).",
          "równowąski": "Liść o niemal stałej szerokości na całej długości, znacznie dłuższy niż szerszy.",
          "lancetowaty": "Kształt wydłużony, najszerszy poniżej środka, zwężający się ku obu końcom (jak grot lancy).",
          "eliptyczny": "Kształt regularnej elipsy, najszerszy w połowie długości liścia.",
          "jajowaty": "Obrys przypominający jajko, z szerszą nasadą i węższym szczytem.",
          "sercowaty": "Blaszka z głębokim wcięciem u nasady, o kształcie przypominającym serce.",
          "łopatowaty": "Szeroki i zaokrąglony u szczytu, stopniowo zwężający się w stronę nasady.",
          "owalny": "Szeroko zaokrąglony kształt o długości nieco większej od szerokości.",
          "odwrotnie jajowaty": "Podobny do jajowatego, ale szerszy u góry (przy szczycie) niż przy nasadzie.",
          "strzałkowaty": "Nasada liścia posiada ostre klapy skierowane w dół, przypominając grot strzały.",
          "nerkowy": "Szeroki, zaokrąglony liść z głębokim, łagodnym wcięciem u nasady.",
          "całobrzegi": "Krawędź blaszki liściowej jest całkowicie gładka, bez żadnych wycięć.",
          "piłkowany": "Brzeg z ostrymi ząbkami skierowanymi wyraźnie w stronę szczytu liścia.",
          "ząbkowany": "Ząbki o równych bokach, skierowane prostopadle do krawędzi liścia.",
          "karbowany": "Brzeg z zaokrąglonymi ząbkami (karbami).",
          "falisty": "Brzeg nie tworzy ząbków, lecz faluje w płaszczyźnie blaszki.",
          "kolczasty": "Ząbki na brzegu liścia są zakończone sztywnymi, kłującymi wyrostkami.",
          "podwójnie pikowany": "Większe ząbki piłkowane posiadają na sobie dodatkowe, mniejsze ząbki.",
          "podwójnie ząbkowany": "System zębów, gdzie każdy ząb główny jest dodatkowo powcinany.",
          "podwójnie karbowany": "Krawędź z dużymi karbami, które same są dodatkowo delikatnie karbowane.",
          "pierzaste": "Jeden wyraźny nerw główny przebiega przez środek, a od niego odchodzą nerwy boczne.",
          "dłoniaste": "Kilka głównych nerwów o podobnej grubości rozchodzi się promieniście od nasady blaszki.",
          "równoległe": "Liczne, drobne nerwy biegną wzdłuż liścia niemal równolegle do siebie (typowe dla traw).",
        },
      ),
      DescriptionCategory(
        number: "4",
        title: "Kwiatostany",
        subCategories: {
          "Typ Kwiatostanu": ["grono", "baldachogrono", "wiecha", "baldach", "koszyczek", "kłos", "główka", "baldach podwójny", "kłos złożony", "sierpik", "wachlarz", "wiechotka", "wiechotka złożona"],
          "Zapach": ["brak", "słaby", "intensywny"],
        },
        referenceImages: {
          "grono": "assets/ref/zielne/kwiat/grono.png",
          "baldachogrono": "assets/ref/zielne/kwiat/baldachogrono.png",
          "baldach podwójny": "assets/ref/zielne/kwiat/kwiat_baldach_podwojny.png",
          "baldach": "assets/ref/zielne/kwiat/kwiat_baldach.png",
          "główka": "assets/ref/zielne/kwiat/kwiat_glowka.png",
          "kłos": "assets/ref/zielne/kwiat/kwiat_klos.png",
          "kłos złożony": "assets/ref/zielne/kwiat/kwiat_klos_zlozony.png",
          "koszyczek": "assets/ref/zielne/kwiat/kwiat_koszyk.png",
          "sierpik": "assets/ref/zielne/kwiat/kwiat_sierpik.png",
          "wachlarz": "assets/ref/zielne/kwiat/kwiat_wachlarz.png",
          "wiecha": "assets/ref/zielne/kwiat/kwiat_wiecha.png",
          "wiechotka": "assets/ref/zielne/kwiat/kwiat_wiechotka.png",
          "wiechotka złożona": "assets/ref/zielne/kwiat/kwiat_wiechotka_wielo.PNG",
          "brak": "assets/grass.png",
          "słaby": "assets/grass.png",
          "intensywny": "assets/grass.png",
        },
        imageDescriptions: {
          "grono": "Kwiaty osadzone na szypułkach o podobnej długości wzdłuż wydłużonej osi głównej (np. u konwalii).",
          "baldachogrono": "Odmiana grona, w której dolne szypułki są znacznie dłuższe od górnych, przez co wszystkie kwiaty znajdują się niemal na jednej wysokości.",
          "wiecha": "Złożony kwiatostan o rozgałęzionej osi głównej, gdzie odgałęzienia boczne są gronami lub kolejnymi wiechami.",
          "baldach": "Wszystkie szypułki kwiatowe wyrastają z jednego punktu na szczycie osi, przypominając pręty parasola (np. u czosnku).",
          "koszyczek": "Kwiaty siedzące osadzone na silnie skróconej, rozszerzonej osi tworzącej dno kwiatostanowe (charakterystyczny dla roślin astrowatych).",
          "kłos": "Kwiaty bezszypułkowe (siedzące) osadzone bezpośrednio wzdłuż wydłużonej osi głównej.",
          "główka": "Kwiaty siedzące lub na bardzo krótkich szypułkach, gęsto skupione na skróconej, kulistej osi (np. u koniczyny).",
          "baldach podwójny": "Z osi głównej wyrastają baldaszki (baldachy mniejszego rzędu) zamiast pojedynczych kwiatów (typowy dla selerowatych).",
          "kłos złożony": "Na osi głównej zamiast pojedynczych kwiatów osadzone są mniejsze kłoski (charakterystyczny dla traz).",
          "sierpik": "Kwiatostan wierzchotkowy, w którym kolejne osie boczne wyrastają zawsze po jednej stronie, zwijając się na kształt sierpa.",
          "wachlarz": "Odmiana wierzchotki, w której kwiaty wyrastają naprzemiennie po obu stronach osi, tworząc płaską strukturę przypominającą wachlarz.",
          "wiechotka": "Kwiatostan, w którym oś główna kończy się kwiatem, a poniżej wyrastają jedna lub dwie osie boczne (również zakończone kwiatami).",
          "wiechotka złożona": "Rozbudowana struktura wierzchotkowa z wielokrotnymi odgałęzieniami bocznymi.",
          "brak": "Kwiaty nie wydzielają wyczuwalnego aromatu.",
          "słaby": "Zapach delikatny, wyczuwalny jedynie z bliskiej odległości.",
          "intensywny": "Silna woń wyczuwalna wyraźnie nawet z pewnej odległości od rośliny.",
        },
      ),
      DescriptionCategory(
        number: "5",
        title: "Owoce",
        subCategories: {
          "Typ owocu": ["jagoda", "orzech", "torebka", "niełupka", "strąk"],
          "Smak": ["gorzki", "słodki", "cierpki", "słony", "pikantny"],
        },
        referenceImages: {
          "jagoda": "assets/ref/zielne/owoce/owoce_jagoda.png",
          "orzech": "assets/ref/zielne/owoce/owoc_orzech.png",
          "torebka": "assets/ref/zielne/owoce/owoc_torebka.png",
          "niełupka": "assets/ref/zielne/owoce/owoc_nielupka.png",
          "strąk": "assets/ref/zielne/owoce/owoc_strak.png",
          "gorzki": "assets/grass.png",
          "słodki": "assets/grass.png",
          "cierpki": "assets/grass.png",
          "słony": "assets/grass.png",
          "pikantny": "assets/grass.png",
        },
        imageDescriptions: {
          "jagoda": "Owoc mięsisty, wielonasienny, o cienkiej skórce (np. borówka).",
          "orzech": "Owoc suchy, niepękający, o zdrewniałej owocni.",
          "torebka": "Owoc suchy, pękający, wielonasienny.",
          "niełupka": "Owoc suchy, jednonasienny, o skórzastej owocni (np. słonecznik).",
          "strąk": "Owoc suchy, pękający dwoma szwami (np. fasola).",
          "gorzki": "Smak wywołujący wrażenie goryczy, często związany z obecnością alkaloidów lub glikozydów.",
          "słodki": "Przyjemny smak kojarzony z obecnością cukrów, często zachęcający zwierzęta do zjadania owoców i rozsiewania nasion.",
          "cierpki": "Wrażenie ściągania w ustach, typowe dla owoców bogatych w garbniki lub kwasy organiczne.",
          "słony": "Smak rzadko spotykany u owoców, charakterystyczny dla wysokiej zawartości soli mineralnych.",
          "pikantny": "Piekące lub ostre wrażenie na języku, wywołane specyficznymi substancjami obronnymi rośliny (np. kapsaicyną).",
        },
      ),
    ];
  }
}