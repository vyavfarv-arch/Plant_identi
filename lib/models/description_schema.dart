class DescriptionCategory {
  final String letter;
  final String title;
  final Map<String, List<String>> subCategories;

  DescriptionCategory({required this.letter, required this.title, required this.subCategories});
}

final List<DescriptionCategory> plantDescriptionSchema = [
  DescriptionCategory(
    letter: "A",
    title: "Pokrój ogólny (habitus)",
    subCategories: {
      "Typ biologiczny": ["drzewo", "krzew", "krzewinka", "bylina", "jednoroczna", "dwuletnia"],
      "Forma wzrostu": ["wyprostowana", "płożąca", "pnąca", "kępkowa", "rozetowa", "darniowa"],
      "Gęstość": ["luźna", "zwarta", "bardzo zwarta"],
      "Symetria": ["symetryczna", "asymetryczna"],
      "Architektura pędów": ["monopodialna", "sympodialna", "dychotomiczne"],
      "Stopień rozgałęzienia": ["słabe", "średnie", "silne"],
    },
  ),
  DescriptionCategory(
    letter: "B",
    title: "System korzeniowy",
    subCategories: {
      "Typ": ["palowy", "wiązowy", "sercowaty", "kłączowy"],
      "Głębokość": ["płytki", "średni", "głęboki"],
      "Obecność organów": ["bulwy", "kłącza", "cebule", "brak"],
    },
  ),
  DescriptionCategory(
    letter: "C",
    title: "Łodyga / pęd",
    subCategories: {
      "Typ pędu": ["zielny", "zdrewniały", "półzdrewniały"],
      "Kształt": ["okrągły", "kanciasty", "bruzdowany", "spłaszczony"],
      "Powierzchnia": ["gładka", "owłosiona", "szorstka", "lepka", "woskowa"],
      "Owłosienie": ["brak", "rzadkie", "gęste"],
      "Typ włosków": ["proste", "gruczołowe", "haczykowate", "kutnerowate"],
      "Barwa": ["zielona", "brunatna", "czerwonawa", "sina"],
    },
  ),
  DescriptionCategory(
    letter: "D",
    title: "Liście",
    subCategories: {
      "Ulistnienie": ["skrętoległe", "naprzeciwległe", "okółkowe"],
      "Typ liścia": ["pojedynczy", "pierzasty", "dłoniasty"],
      "Kształt blaszki": ["Igiełkowy", "lancetowaty", "eliptyczny", "jajowaty", "sercowaty", "nerkowy"],
      "Brzeg liścia": ["całobrzegi", "piłkowany", "ząbkowany", "karbowany", "falisty", "kolczasty"],
      "Unerwienie": ["pierzaste", "dłoniaste", "równoległe"],
      "Wcięcie": ["Wrębne", "Dzielne", "klapowate", "sieczne"],
    },
  ),
  DescriptionCategory(
    letter: "E",
    title: "Kwiaty / kwiatostany",
    subCategories: {
      "Obecność": ["brak", "obecne"],
      "Typ kwiatostanu": ["grono", "wiecha", "baldach", "koszyczek", "kłos", "główka"],
      "Symetria": ["promienista", "grzbiecista"],
      "Zapach": ["brak", "słaby", "intensywny"],
    },
  ),
  DescriptionCategory(
    letter: "F",
    title: "Owoce i nasiona",
    subCategories: {
      "Typ owocu": ["jagoda", "orzech", "torebka", "niełupka", "strąk"],
      "Rozsiewanie": ["wiatr", "zwierzęta", "autochoria"],
    },
  ),
  DescriptionCategory(
    letter: "I",
    title: "Pokrycie i ilościowość",
    subCategories: {
      "Ilościowość": ["5 (75-100%)", "4 (50-75%)", "3 (25-50%)", "2 (5-25%)", "1 (<5%)", "r (poj.)"],
      "Rozmieszczenie": ["równomierne", "skupiskowe", "losowe"],
    },
  ),
  DescriptionCategory(
    letter: "J",
    title: "Warstwa fitosocjologiczna",
    subCategories: {
      "Warstwa": ["drzew (A)", "krzewów (B)", "runa (C)", "mszystej (D)"],
    },
  ),
];