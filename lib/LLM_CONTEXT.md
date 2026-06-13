# Kontekst Projektu i Struktura Repozytorium dla LLM

## 1. Cel i Opis Aplikacji
**Plantifikator** to zaawansowana aplikacja mobilna stworzona z myślą o botanikach, fitosocjologach oraz zielarzach terenowych. Łączy ona funkcje terenowego rejestratora danych florystycznych z asystentem ekologicznym opartym na cyfrowych wskaźnikach Ellenberga oraz systemem zarządzania recepturami zielarskimi.

### Kluczowa Filozofia i Założenia Projektu:
- **Cel Edukacyjny:** Głównym założeniem aplikacji jest interaktywna edukacja botaniczna użytkownika. Poprzez system wbudowanych asystentów oraz „podpowiadajek” (szczególnie w module opisu cech morfologicznych), użytkownik uczy się poprawnej terminologii, rozpoznawania struktur diagnostycznych oraz analizy organów roślinnych.
- **Brak Wewnętrznej Globalnej Bazy (Własny Klucz):** Aplikacja świadomie nie posiada wbudowanego na stałe, sztywnego atlasu wszystkich gatunków flory. Kluczowym elementem jest to, że użytkownik **buduje swój własny, spersonalizowany klucz taksonomiczny**. Opisując lokalne rośliny oraz lokalne obszary, tworzy unikalną dla swojego regionu bazę wiedzy.
- **Silnik Matematyczny i Detekcja Anomalii:** Aplikacja zawiera dedykowany silnik ekologiczny, który dopasowuje spektrum tolerancji roślin do parametrów fizjograficznych płatów. Jednym z jego najważniejszych zadań jest **wychwytywanie okazów odstających (outliers)**. Jeśli okaz zostanie przypisany do obszaru, z którego charakterystyki wynikają skrajnie inne warunki (np. roślina wybitnie światłolubna przypisana do mrocznego, gęstego lasu), silnik identyfikuje to jako anomalię preferencji. *Uwaga: komponent matematyczny jest w fazie ciągłego rozwoju i ulepszeń w trakcie dalszego developmentu.*

### Główne filary funkcjonalne aplikacji:
- **Ewidencja okazów (Magazyn):** Szybka lub szczegółowa rejestracja znalezionych roślin wraz z dokumentacją fotograficzną, współrzędnymi GPS oraz precyzyjnym określeniem parametrów populacyjnych (faza fenologiczna, witalność, obfitość w skali Brauna-Blanqueta) i cech morfologicznych.
- **Mapowanie płatów roślinnych (Obszary/Zdjęcia fitosocjologiczne):** Wyznaczanie na mapie wielokątów reprezentujących płaty roślinności i opisywanie ich parametrów siedliskowych (odczyn pH gleby, typ podłoża, ocienienie okapu, kontekst hydrologiczny, antropopresja).
- **Matryca ekologiczna i dopasowania (Liczby Ellenberga):** Porównywanie rzeczywistych warunków siedliskowych płatu ze spektrum tolerancji ekologicznej roślin (7 osi wskaźnikowych: L – światło, F – wilgotność, R – pH, N – azot, T – temperatura, K – kontynentalizm, S – zasolenie). System potrafi określić prawdopodobieństwo wystąpienia gatunków potencjalnych oraz wykryć anomalie ekologiczne i morfologiczne.
- **Asystent Czasowy i Minutniki Zielarskie:** Przechowywanie przepisów na preparaty ziołowe (napary, odwary, maceraty, nalewki) z możliwością uruchomienia systemowych liczników odliczających czas procesów oraz generowanie automatycznych powiadomień o fenologicznych terminach zbioru surowców na podstawie danych zebranych w terenie.
- **Eksport danych dla Machine Learning:** Konsolidacja kompletnych obserwacji terenowych i powiązanych cech siedliskowych do ujednoliconego pliku CSV w celu dalszego trenowania zewnętrznych modeli uczenia maszynowego.

## 2. Architektura i Stos Technologiczny
- **Framework:** Flutter (Dart) – interfejs w pełni reaktywny, dostosowany do pracy w terenie (tryb ciemny/hybrydowy map, elementy dotykowe Material 3).
- **Zarządzanie Stanem:** Architektura MVVM (Model-View-ViewModel) realizowana za pomocą pakietu `Provider`. ViewModels izolują kompletną logikę biznesową od widoków.
- **Baza Danych:** Lokalny silnik SQLite poprzez pakiet `sqflite` (baza `planticator.db` w wersji v23), zapewniający integralność referencyjną i relacje kluczy obcych (np. kaskadowe usuwanie obserwacji przy usuwaniu płatu).
- **Integracje sprzętowe:** Google Maps API (rysowanie poligonów, korekta pozycji okazów), Geolocator (lokalizacja GPS z ograniczeniem czasowym), Camera (wielokrotna rejestracja cech diagnostycznych), Flutter Local Notifications (zarządzanie alarmami systemowymi Android).
## 3. Drzewo Projektu (Spis Treści)

```text
lib/
│
├── main.dart                             # Punkt wejścia, inicjalizacja usług, MultiProvider
│
├── models/                               # Encje danych i schematy bazodanowe
│   ├── app_reminder.dart                 # Model przypomnienia / minutnika (RECIPE / HARVEST)
│   ├── description_schema.dart           # Generator cech morfologicznych dla typów biologicznych
│   ├── habitat_info.dart                 # Opcje i struktura parametrów siedliskowych płatu
│   ├── harvest_season.dart               # Przedziały czasowe i typy zbieranego surowca
│   ├── has_ellenberg_profile.dart        # Interfejs wymuszający profil 7 wskaźników Ellenberga
│   ├── plant_observation.dart            # Model konkretnego zaobserwowanego okazu w terenie
│   ├── plant_species.dart                # Model gatunku (baza wiedzy/atlas) z wzorcem morfologicznym
│   ├── recipe.dart                       # Model przepisu zielarskiego ze składnikami i krokami
│   ├── releve.dart                       # Model płatu roślinnego / zdjęcia fitosocjologicznego
│   ├── sought_plant.dart                 # Model rośliny poszukiwanej za pomocą matrycy
│   └── syntaxon.dart                     # Model jednostki fitosocjologicznej (baza syntaxa.json)
│
├── services/                             # Warstwa usług systemowych i silników obliczeniowych
│   ├── camera_service.dart               # Sterownik aparatu fotograficznego urządzenia
│   ├── data_export_service.dart          # Kompilator i eksporter danych CSV dla modeli ML
│   ├── database_helper.dart              # Konfiguracja SQLite, migracje, surowe operacje CRUD
│   ├── ecological_matching_service.dart  # Translacja siedlisk i obliczanie kar dla osi Ellenberga
│   ├── identification_assistant_service.dart # Silnik sugestii taksonomicznych i wykrywania anomalii
│   ├── location_service.dart             # Moduł pobierania pozycji GPS z timeout-guardem
│   ├── notification_service.dart         # Harmonogram powiadomień i stref czasowych systemu Android
│   ├── phytosociology_service.dart       # Algorytm określania przynależności do syntaksonów
│   └── spatial_service.dart              # Obliczenia geometryczne (punkt wewnątrz wielokąta płatu)
│
├── viewmodels/                           # Warstwa logiki biznesowej i zarządzania stanem (MVVM)
│   ├── observation_view_model.dart       # Zarządzanie aparatami, pozycją i ewidencją okazów
│   ├── recipe_view_model.dart            # Obsługa bazy przepisów i ich sortowania
│   ├── releve_view_model.dart            # Obsługa struktur płatów, relacji hierarchicznych i predykcji
│   ├── reminder_view_model.dart          # Zarządzanie minutnikami i asystentem zbiorów fenologicznych
│   └── search_filter_view_model.dart     # Stan globalnych filtrów katalogu, map oraz poszukiwań
│
└── views/                                # Warstwa interfejsu użytkownika (UI) i widżetów
    ├── add_observation_long_step1.dart   # Krok 1 trybu długiego: typ biologiczny i parametry populacji
    ├── add_observation_morphology_step2.dart # Krok 2 trybu długiego: dynamiczne drzewo cech morfologicznych
    ├── add_observation_quick_steps.dart  # Szybki wpis: podgląd kamery i uproszczony drop-down stanu
    ├── add_observation_screen.dart       # Kontroler PageView koordynujący ewidencję okazu
    ├── add_plant_choice_screen.dart      # Menu wyboru rodzaju ewidencji (znana / nieznana roślina)
    ├── add_sought_plant_screen.dart      # Kreator nowego celu poszukiwań z pickerem amplitudy
    ├── area_filter_screen.dart           # Zaawansowane filtry parametrów środowiskowych dla płatów
    ├── browse_plants_screen.dart         # Główny katalog/atlas zebranych gatunków z filtrami grupującymi
    ├── camera_screen.dart                # Ekran seryjnego zbierania zdjęć detali morfologicznych
    ├── description_grid_screen.dart      # Siatka (Grid) okazów oczekujących na pełną identyfikację
    ├── detail_description_screen.dart    # Kompletny edytor wiedzy o gatunku i taksonomii okazu
    ├── filtered_areas_map_screen.dart    # Podgląd wyfiltrowanych wielokątów płatów na mapie hybrydowej
    ├── form_screen.dart                  # Formularz terenowej modyfikacji cech z asystentem sugestii
    ├── habitat_details_screen.dart       # Formularz wprowadzania cech fizjograficznych nowego płatu
    ├── habitat_form_screen.dart          # Ekran szczegółowego przeglądu i edycji parametrów glebowych
    ├── home_screen.dart                  # Pulpit główny aplikacji (Siatka 9 modułów startowych)
    ├── map_screen.dart                   # Główna mapa terenowa z markerami okazów i celownikiem relokalizacji
    ├── plant_card_view.dart              # Widok dolnego arkusza (BottomSheet) pojedynczego okazu
    ├── quick_find_form_screen.dart       # Potwierdzenie znalezienia poszukiwanej rośliny wewnątrz płatu
    ├── recipe_form_screen.dart           # Kreator receptur z dynamicznymi składnikami i krokami czasowymi
    ├── recipe_list_screen.dart           # Menadżer przepisów z podziałem na etykiety i starterami liczników
    ├── releve_details_screen.dart        # Karta płatu: powiązane okazy, analiza ekologiczna i gatunki potencjalne
    ├── releve_list_map_screen.dart       # Lista płatów z obsługą relacji hierarchicznych (podobszary)
    ├── releve_map_screen.dart            # Interfejs satelitarny do geometrycznego rysowania granic płatu
    ├── reminder_list_screen.dart         # Oś czasu asystenta czasowego (zakładki W toku / Historia)
    ├── results_map_screen.dart           # Mapa wyników analizy matrycowej dla rośliny poszukiwanej
    ├── search_plants_screen.dart         # Wyszukiwarka oparta na dopasowaniu matrycowym siedlisk
    └── widgets/                          # Widżety współdzielone
        ├── ecological_amplitude_picker.dart # Trzystanowa siatka wyboru optymalnych liczb Ellenberga
        ├── ellenberg_matrix_card.dart    # Karta prezentacji rozkładu wymagań ekologicznych gatunku
        ├── harvest_season_picker.dart    # Widżet definiowania zakresów dat zbioru części roślin
        ├── species_harvest_averages.dart # Widżet uśrednionego czasu wegetacji z aktywacją powiadomień
        └── specimen_reference_card.dart  # Karta podglądu cech okazu ze swobodnym zoomem zdjęć
```
## 4. Szczegółowy Opis Plików i Ich Ról
### Klasy Modeli (lib/models/)
- app_reminder.dart: Definiuje strukturę przypomnień. Obsługuje flagę type rozróżniającą minutniki laboratoryjne (RECIPE) od alertów kalendarzowych (HARVEST).
- description_schema.dart: Dostarcza kompletne, sformalizowane drzewa cech diagnostycznych dla pięciu głównych królestw/typów biologicznych. Odpowiada za dostarczanie opisów i powiązań z grafikami wzorcowymi.
- habitat_info.dart: Agreguje predefiniowane opcje słownikowe dla parametrów środowiskowych. Odpowiada za serializację/deserializację list podłoży mineralno-organicznych do formatu JSON.
- harvest_season.dart: Reprezentuje przedział czasu zbierania konkretnego surowca zielarskiego (np. kora, liście, kłącza).
- has_ellenberg_profile.dart: Abstrakcyjny interfejs zapewniający polimorfizm dla obiektów posiadających profil ekologiczny (używany zamiennie dla PlantSpecies oraz SoughtPlant w silniku dopasowań).
- plant_observation.dart: Reprezentuje pojedynczy rekord botaniczny zarejestrowany w terenie. Przechowuje mapę cech characteristics (Kategoria -> Wybrane cechy) oraz dynamiczne stany populacyjne.
- plant_species.dart: Klasa atlasowa reprezentująca wzorzec botaniczny danego gatunku. Zawiera mapy dopuszczalnych cech (patternTraits) używane do weryfikacji poprawności oznaczeń.
- recipe.dart: Encja przepisu medycyny naturalnej. Dzieli kroki na tekstowe instrukcje oraz kroki czasowe z określonym czasem trwania w minutach, godzinach lub dniach.
- releve.dart: Odpowiednik zdjęcia fitosocjologicznego. Przechowuje listę punktów granicznych LatLng, relację do obszaru nadrzędnego parentId oraz mapę predykcji ekologicznych gatunków potencjalnych.
- sought_plant.dart: Obiekt przechowujący konfigurację poszukiwań danej rośliny, inicjowany na podstawie danych atlasowych lub wpisany ręcznie przez użytkownika.
- syntaxon.dart: Klasyfikacja zespołów roślinnych według ról diagnostycznych i gatunków charakterystycznych wczytywanych z pliku zasobów.

### Usługi i Silniki Logiczne (lib/services/)
- camera_service.dart: Odpowiada za bezpieczną inicjalizację sprzętową aparatu fotograficznego. Wymusza format JPEG i dba o usuwanie starego kontrolera z pamięci przed alokacją nowego.
- data_export_service.dart: Filtruje kompletne rekordy i spaja parametry środowiskowe płatu z przypisanym do okazu gatunkiem. Generuje plik znakowany czasowo, gotowy do przekazania do zewnętrznych bibliotek ML.
- database_helper.dart: Wzorzec Singleton zarządzający połączeniem bazodanowym. Definiuje schematy tabel, włącza ograniczenia kluczy obcych (PRAGMA foreign_keys = ON) oraz realizuje operacje zapisu i kasowania danych.
- ecological_matching_service.dart: Serce analityczne aplikacji. Klasa AdvancedEcologicalTranslator przekształca opisowe parametry terenu (nachylenie, ekspozycja, darń) na ciągłe wartości numeryczne profili. Następnie obliczana jest odległość matematyczna od optimum gatunku, generując końcowy wynik zgodności oraz wektor diagnostyczny (✓/✗/?).
- identification_assistant_service.dart: Zawiera reguły eksperckie. Metoda checkAnomalies wykrywa, czy cechy przypisane przez użytkownika w terenie nie kłócą się z oficjalnym wzorcem botanicznym. Metoda getSuggestions wylicza wagowy ranking (60% morfologia, 40% ekologia siedliska) w celu podpowiedzenia właściwego gatunku.
- location_service.dart: Pobiera współrzędne geograficzne z urządzenia. Posiada sztywny guard czasowy (timeLimit: 5s), zapobiegający zamrożeniu wątku interfejsu w przypadku braku odpowiedzi satelitów GPS.
- notification_service.dart: Odpowiada za obsługę systemowych alarmów. Inicjalizuje natywne kanały powiadomień, pobiera lokalną strefę czasową urządzenia i planuje dokładne wywołania powiadomień (exactAllowWhileIdle).
- phytosociology_service.dart: Analizuje listę gatunków występujących w danym płacie i porównuje je z bazą syntaksonów. Wylicza wskaźnik pokrycia diagnostycznego i generuje ostrzeżenia w przypadku wykrycia płatów niejednorodnych (wymieszanie klas).
- spatial_service.dart: Implementuje algorytm powłoki (Ray-casting / punkt w wielokącie). Służy do automatycznego wiązania nowo dodawanych okazów z płatami roślinnymi na podstawie ich współrzędnych geograficznych.

### Zarządy Stanu / ViewModels (lib/viewmodels/)
- observation_view_model.dart: Reaktywny punkt zarządzania okazami i słownikami. Koordynuje asynchroniczny zapis powiązany z automatyczną weryfikacją obecności i usuwaniem osieroconych gatunków z atlasu.
- recipe_view_model.dart: Ładuje i sortuje receptury użytkownika (najnowsze na górze).
- releve_view_model.dart: Odpowiada za stan obszarów. Obsługuje hierarchiczne zapytania o podobszary (getChildren) oraz waliduje poprawność budowania drzewa syntaksonów.
- reminder_view_model.dart: Komunikuje się bezpośrednio z usługą powiadomień systemowych. Odpowiada za wyliczanie dokładnych dat rozpoczęcia i zakończenia procesów oraz aktualizację wyciszeń (toggleMute).
- search_filter_view_model.dart: Centralny rejestr stanów filtrowania. Przechowuje zakresy dat, wybrane rodziny, zakresy suwaków pH gleby i stany filtrów wielokrotnego wyboru podłoża mineralnego.

## 5. Wytyczne dla LLM podczas wprowadzania zmian (Modyfikacje Kodu)
Zasada Nienaruszania Architektury MVVM: Logika biznesowa, zapisy bazodanowe, transformacje numeryczne i pobieranie danych sprzętowych MUSZĄ znajdować się wyłącznie w warstwie services lub viewmodels. Widoki (views) mogą jedynie odczytywać stan lub wywoływać metody kontrolerów.

Spójność Typów Liczb Ellenberga: Zarówno w modelach gatunków, jak i roślin poszukiwanych, osie Ellenberga realizowane są za pomocą struktur Map<int, int> odzwierciedlających cyfrową mapę trzystanową (0 = brak powiązania, 1 = tolerancja/występowanie, 2 = optimum gatunku). Nie wolno zmieniać tych struktur na proste listy czy ciągi tekstowe.

Dokumentacja Importów w Kodzie: Każdy plik źródłowy w tym projekcie stosuje rygorystyczny standard opisu zależności zewnętrznych. Bezpośrednio pod blokiem instrukcji import musi znaleźć się komentarz blokowy dokumentujący, jakie kluczowe elementy (metody, encje, widżety) są importowane z innych plików projektu i do czego służą. Przy modyfikacji importów, zaktualizuj ten komentarz.

