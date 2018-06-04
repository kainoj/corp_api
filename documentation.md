_Przemysław Joniak, grupa 1_

# Zarządzanie Korporacją X

Uruchomienie: `python corp_api.py [-h] [-init] [-file file] [-debug]`. 

API zostało napisane w Pythonie3. Przed pierwszym uruchomienim wymagane jest, aby istniał użytkownik `init` z uprawnieniami `CREATEDB` i `CREATEUSER`, oraz baza danych do której `init` ma dostęp.


## Przykładowe uruchimienia:
```bash
# Inicjalizacja bazy danych, dane pobierane są z pliku
python3 corp_api.py -init -file test/init.json

# Inicjalizacja bazy danych, dane pochodzą ze standardowego wejścia
make init < test/init.json

# Drugie uruchomienie aplikacji, dane pochodzą ze standardowego wejścia
python3 corp_api.py < test/2nd-oks.json
make run < test/2nd-oks.json

# Kolejne uruchomienie aplikacji, dane pochodzą ze standardowego wejścia, a w przypadku błędu wyświetlane są dodatkowe informacje
python3 corp_api.py -debug < test/2nd-errors.json 

# Czyszczenie zawartości bazy danych (wymaga su)
make resetdb

# Usuwanie plików tymczasowych Pythona
make clean
```

## Model fizyczny
# [todo] zdjęcie
Ładowany przy pierwszym uruchimieniu aplikacji model fizyczny znajduje się w pliku `api_schema.sql`. Zdefiniowane są tam kolejno:
- tabele `employee` oraz `pathfromroot`

    - `employee` zawiera podstawowe informaje o pracowniku: jego `id`, hasz hasła `pswd`, dane `dat` oraz wskaźnik `parent` na swojego przełożonego.  `parent` szefa (korzenia) jako jedyny jest pusty. Ze wzglądów bezpieczeństwa atrybut `pswd` nie może być pusty.
    - `pathfromroot` dla każdego pracownika trzyma ścieżkę od korzenia do tego pracownika wyłącznie. Ta ścieżka jest typu `array::int` (w szczególności ścieżka dla korzenia to: `[]` )
- użytkownik `app` wraz z odpowiednimi uprawnieniami
- rozszerzenie `pgcrypto` do obliczania haszy haseł
- wyszczególnine w specyfikacji funkcje API ze, które wywoływane są z poziomu pythona. Dodtkowo zaimplementowane zostały funkcje:
    - `auth_emp(admin, pswd)` - zwraca `true` wtedy i tylko wtedy, gdy podane dane logowania pracownika są poprawne
    - `emp_exists(emp)` - zwraca `true` wtedy i tylko wtedy, gdy pracownik `emp` istnieje w bazie danych

    szczegółowy opis wszystkich funkcji zajduje sie w cześći `Implementacja`

## Implementacja

API zostało zaprojektowane tak, aby jak największa cz






