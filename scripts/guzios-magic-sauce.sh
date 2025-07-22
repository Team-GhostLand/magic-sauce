#!/bin/bash

# shellcheck disable=1111




  #   ===== CONFIG =====



DEFAULT_FISH_PATH="/usr/share/fish/vendor_completions.d/minecraft.fish"
PHANTOM_USER="42069"

# Pick one
#UPDATE_COMMAND="echo \"[ERROR] Auto-updates disabled!\"; exit 1;"
 UPDATE_COMMAND="git clone --recursive https://github.com/Team-GhostLand/magic-sauce.git update;"  # CHANGE GITHUB URL!  # DON'T CHANGE TARGET NAME!  # Make sure `scripts` and `docker-compose.yml` are at repo root (other files/folders at repo root are permitted, but will be ignored).  # If you're a psychopath (or need a private repo), use `gh` instead.
#UPDATE_COMMAND="wget https://example.com/minecraft.zip; unzip minecraft.zip; rm -vf minecraft.zip"  # CHANGE URL AND (optional) FILENAME!  # Must contain exactly one folder `update` at root, and `scripts` and `docker-compose.yml` inside it (other files/folders inside `update` are permitted, but will be ignored).  # If you're a psychopath (no other possible reason), use `curl` or `tar` instead.




  #   ===== SETUP =====



# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

cd "$DIR/../" || exit;

STOPPED_NOTE="NOTE: The server seems to be offline. If this command fails, run \`minecraft start\` and try again."
if [ -e "minecraft.lock" ]; then
    STOPPED_NOTE=""
fi

if [ -z "$FISH_PATH" ]; then
    FISH_PATH=$DEFAULT_FISH_PATH
fi

# Common strings:
WORKDIR_NOTE="[[Working from: $(pwd)]]"
SUDO_NOTE="ERROR: This script must be ran as root!"
INSTALL_PATH="%INSTALL_PATH%"
INSTALL_PATH_LITERAL=$'\x25\x49\x4e\x53\x54\x41\x4c\x4c\x5f\x50\x41\x54\x48\x25'
SCRIPT_PATH="$(pwd)/scripts/guzios-magic-sauce.sh"
FISH_SUBCOMMANDS="start stop send health restart kill inspect sh workdir fixown mark-stopped install uninstall update reinstall startd allow cleanup test help"




  #   ===== MAIN =====



 #  === SERVER MANAGEMENT ===

if [ -z "$1" ]; then
    echo "$STOPPED_NOTE";
    docker compose logs -n 4096 "minecraft";
    docker compose attach --detach-keys="ctrl-a,ctrl-d" "minecraft";
    exit 0;
fi

if [ "$1" = "start" ]; then
    echo "$WORKDIR_NOTE";
    echo;

    if [ -e "minecraft.lock" ]; then
        echo "NOTE: The server is already starting/running.";
        echo;
        echo "This isn't a problem - the command does nothing in such a case.";
        echo "...Unless docker-compose.yml changed - then we'll reboot only";
        echo "those containers that had something changed about them.";
        echo "Please watch the logs below to see exaclty what happens.";
        echo;
        echo "(note that if it's the Minecraft server that ends up restarting, you'll";
        echo "have to run \`minecraft\` from a different terminal to see the logs)";
        echo;
    else
        touch "minecraft.lock";
        echo "Server powering up. If you want to spectate the logs as it starts, run \`minecraft\` from a different terminal.";
        echo;
    fi
    
    docker compose up -d;
    if [ $? -ne 0 ]; then
        echo "ERROR: Docker threw an exception. If it was something about not being able to open a socket, then:";
        echo "  - Make sure you are a member of the \`docker\` group. You can add users to it using \`sudo minecraft allow <USERNAME>\`.";
        echo "  - Make sure that the Docker Daemon is running. You can check it and start it automatically using \`sudo minecraft startd\`.";
        echo "  - Go cry in a corner, in case the above solutions fail - most likely, Docker is borked somehow.";
        rm "minecraft.lock";
        exit 1;
    fi
    exit 0;
fi

if [ "$1" = "stop" ]; then
    if [ -z "$2" ]; then
        echo "Minecraft server powering down. If you want to spectate its logs as it stops, run \`minecraft\` from a different terminal.";
        rm "minecraft.lock";
        docker compose stop "minecraft";
        exit;
    fi
    if [ "$2" == "ALL" ]; then
        echo "EVERYTHING powering down! If you want to spectate any stopping logs, run \`minecraft inspect <service>\` (or just \`minecraft\` for the Minecraft Server) from a different terminal.";
        rm "minecraft.lock";
        docker compose stop;
        exit;
    fi
    echo "Service $2 server powering down...";
    docker compose stop "$2";
    exit;
fi

if [ "$1" = "send" ]; then
    if [ -z "$2" ]; then
        echo "$STOPPED_NOTE";
        docker compose exec "minecraft" "rcon-cli";
        exit;
    fi
    echo "Attempting to execute: \`/$2\`";
    echo "$STOPPED_NOTE";
    docker compose exec "minecraft" "rcon-cli" "$2";
    exit;
fi

if [ "$1" = "health" ]; then
    docker container inspect -f "{{.State.Health.Status}}" "ghostland-minecraft-1"; # Compose has no "inspect" command, so we're using Docker's one - which means we need to use the full container name, not the service name. Unless it's the same deal as "attach", ie. command exist, but isn't documented.
    exit;
fi

if [ "$1" = "restart" ]; then
    echo "Stopping the server via the \`/stop\` command:";
    echo "(Afterwards, Docker's auto-restart mechanism should kick in.)";
    $SCRIPT_PATH send "stop";
    exit;
fi

if [ "$1" = "kill" ]; then
    if [ -z "$2" ]; then
        echo "Minecraft server powering down. If you want to spectate its logs as it stops, run \`minecraft\` from a different terminal.";
        rm "minecraft.lock";
        docker compose down "minecraft";
        exit;
    fi
    if [ "$2" == "ALL" ]; then
        echo "EVERYTHING powering down! If you want to spectate any stopping logs, run \`minecraft inspect <service>\` (or just \`minecraft\` for the Minecraft Server) from a different terminal.";
        rm "minecraft.lock";
        docker compose down;
        exit;
    fi
    echo "Service $2 server powering down...";
    docker compose down "$2";
    exit;
fi

if [ "$1" = "inspect" ]; then
    if [ -z "$2" ]; then
        echo "Please specify a service name!";
        exit 1;
    fi
    docker compose logs -n 4096 "$2";
    exit;
fi

if [ "$1" = "sh" ]; then
    if [ -z "$2" ]; then
        echo "Please specify service name!";
        exit 1;
    fi
    docker compose exec "$2" "sh";
    exit;
fi



 #  === WORKDIR MANAGEMENT ===

if [ "$1" = "workdir" ]; then
    pwd;
    exit;
fi

if [ "$1" = "fixown" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi

    echo "$WORKDIR_NOTE";
    echo;
    # Why am I giving read+write+exec perms to things that SHOULD only need read+write perms? Because folders in Linux need execute permissions to be writable. Stupid? Yes! But what can we do about it?
    chmod --verbose --recursive 770 .;
    chmod --verbose 070 .;
    chmod --verbose --recursive 050 ./scripts;
    chmod --verbose 040 ./docker-compose.yml;
    chown --verbose --recursive "$PHANTOM_USER:docker" .;
    echo "Now, server-owned files are also accessible to everyone in the \`docker\` group. Keep in mind that";
    echo "you're stil not their owner - that honor belongs to user $PHANTOM_USER. You are merely a guest allowed inside.";
    echo "This, however, won't be the case for any file you CREATE here - which is pretty bad, as this could";
    echo "make said file inaccessible to the server. As such, should you ever create a file here, make sure to run";
    echo "\`sudo minecraft fixown\` again. Don't worry, editing/viewing/removing files is fine. Only creation";
    echo "causes problems. Also, for security reasons, you cannot edit scripts or compose. To change anything,";
    echo "please edit them on GitHub and run \`sudo minecraft update\`. In DIRE situations, edit them as root.";
    exit 0;
fi

if [ "$1" = "mark-stopped" ]; then
    rm --verbose "minecraft.lock";
    exit;
fi



 #  === SCRIPT MANAGEMENT ===

if [ "$1" = "install" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi
    if [ -e $INSTALL_PATH ]; then
        echo "Już zainstalowany!";
        exit 1;
    fi

    echo " ---INSTALACJA ROZPOCZĘTA! :: STEP 1/7: DOCKER---";
    HAS_APT=YES
    apt -v > /dev/null 2> /dev/null;
    if [ $? -ne 0 ]; then
        HAS_APT=NO
    fi

    HAS_DOCKER=YES
    docker help > /dev/null 2> /dev/null;
    if [ $? -ne 0 ]; then
        HAS_DOCKER=NO
    fi

    HAS_COMPOSE=YES
    docker compose > /dev/null 2> /dev/null;
    if [ $? -ne 0 ]; then
        HAS_COMPOSE=NO
    fi

    # FOR DEBUGGING PURPOUSES
    #HAS_APT=YES
    #HAS_APT=NO
    #HAS_DOCKER=YES
    #HAS_DOCKER=NO
    #HAS_COMPOSE=YES
    #HAS_COMPOSE=NO

    echo "Konfiguracja systemu: APT: $HAS_APT // Docker: $HAS_DOCKER // Docker Compose: $HAS_COMPOSE";
    echo "Wspierana konfiguracja 1: APT: YES // Docker: NO // Docker Compose: NO";
    echo "Wspierana konfiguracja 2: APT: (ignored) // Docker: YES // Docker Compose: YES";

    SKIP_APT=NO
    if [ "$HAS_COMPOSE" == "YES" ]; then
        if [ "$HAS_DOCKER" == "NO" ]; then
            echo "Jakimś cudem, masz Docker Compose bez Dockera. To nie powinno być możliwe, więc przyjmuję to jako błąd. Instalacja anulowana.";
            exit 1;
        fi

        echo "Brawo, masz Dockera! Pomijanie jego instalacji.";
        SKIP_APT=YES
    fi

    if [ "$HAS_COMPOSE" == "NO" ]; then
        if [ "$HAS_DOCKER" == "YES" ]; then
            echo "Niewspierana konfiguracja: Docker bez Docker Compose. Musisz: albo nie mieć żadnego (i mieć APT), albo mieć oba. Instalacja anulowana.";
            exit 1;
        fi
    fi

    if [ "$SKIP_APT" == "NO" ]; then
        if [ "$HAS_APT" == "NO" ]; then
            echo "Niewspierana konfiguracja: Brak Dockera i Docker Compose - ale i APT, żeby je zainstalować. Zainstaluj Docker manualnie i spróbuj ponownie.";
            exit 1;
        fi

        echo "Instaluję Docker za pomocą APT...";
        sleep 3;

        apt install -y docker-compose-v2;
        if [ $? -ne 0 ]; then
            echo "APT wywalił inny exit-code niż 0; przyjmuję to jako błąd. Instalacja anulowana.";
            exit 1;
        fi
    fi

    sleep 3;
    GROUPID=$(cat /etc/group | grep docker | cut -d: -f3)
    if [ -z "$GROUPID" ]; then
        echo "Katastrofalny błąd: grupa \`docker\` nie istnieje po rzekomo zakończonej instalacji Dockera. Coś musiało pójść bardzo nie tak. Instalacja anulowana.";
        exit 1;
    fi
    echo "Instalacja Dockera zakończona. ID grupy: $GROUPID; Wersja kompozytora:";
    docker compose version;
    if [ $? -ne 0 ]; then
        echo "Docker Compose wywalił inny exit-code niż 0 po rzekomo zakończonej instalacji; przyjmuję to jako błąd. Instalacja anulowana.";
        exit 1;
    fi

    sleep 3;
    echo;
    echo " ---STEP 2/7: INSTALACJA---";
    echo "Pobieram skrypt z workdira: $(pwd) (pełna ścieżka: $SCRIPT_PATH) i linkuję go do: $INSTALL_PATH";
    ln --symbolic --verbose "$SCRIPT_PATH" "$INSTALL_PATH";
    
    sleep 3;
    echo;
    echo " ---STEP 3/7: TEST---";
    echo "Teraz, skrypt TEORETYCZNIE powinien być zainstalowany w $INSTALL_PATH. Wykonywanie \`minecraft test\`", aby to sprawdzić.;
    $INSTALL_PATH test;
    if [ $? -ne 0 ]; then
        echo "Wykryto non-0 exit code. Anulowanie instalacji.";
        exit 1;
    fi
    echo "Wygląda dobrze. Idę dalej."

    sleep 3;
    echo;
    echo " ---STEP 4/7: FIXOWN---";
    echo "Pożegnaj się z tym logiem - mega-spam za 10s...";
    sleep 10;
    $INSTALL_PATH fixown;

    sleep 3;
    echo;
    echo " ---STEP 5/7: SEDDING---";
    sed -i -e "s/%DOCKER_GROUP_ID%/$GROUPID/g" "./docker-compose.yml";
    if [ $? -ne 0 ]; then
        echo "Błąd nie jest na tyle poważny, by przerywać przez niego instalację.";
        echo "Niesterty, to znaczy, że zanim serwer będzie uruchamialny, trzeba manualnie";
        echo "zamienić %DOCKER_GROUP_ID% na ID grupy \`docker\` w pliku $(pwd)/docker-compose.yml";
        echo "JEŚLI ROZUMIESZ - NACIŚNIJ DOWOLNY PRZYCISK ABY KONTYNUOWAĆ!";
        read -r -n 1 -s;
    fi
    echo "Operacja SED zakończona. Zamieniono %DOCKER_GROUP_ID% na $GROUPID, bądź już było zamienione.";

    sleep 3;
    echo;
    echo " ---STEP 6/7: DOCKERD---";
    sleep 3;
    $INSTALL_PATH startd;

    sleep 3;
    echo;
    echo " ---STEP 7/7: FISH---";
    COMPLETIONS="complete -c minecraft -a '$FISH_SUBCOMMANDS'"
    echo "Zapisywanie \`$COMPLETIONS\` do \`$FISH_PATH\`.";
    echo "$COMPLETIONS" > "$FISH_PATH";
    chmod --verbose 555 "$FISH_PATH";

    echo;
    echo " ---INSTALACJA ZAKOŃCZONA SUKCESEM!---";
    echo;
    echo "Dodaj wszystkich ważnych adminów do grupy \`docker\`. W ten sposób, będą oni mogli:";
    echo "  - Dowolnie interaktować z workdirem - chodź czasem będzie to wymagało zrobienia \`sudo minecraft fixown\`"
    echo "    (don't worry, to nie psuje permisji serwera - tylko zrób \`sudo minecraft fixown\`, jeśli TWORZYSZ pliki/foldery).";
    echo "  - Wykonywać część komend (np. startować serwer) jako \`minecraft [komenda]\`, a nie \`sudo minecraft [komenda]\` - sprawdź \`minecraft help\` po listę.";
    echo "  - Widzieć auto-completion \`minecraft\` i \`sudo minecraft\`.";
    echo "Zrobisz to za pomocą \`sudo minecraft allow <NAZWA_UŻYTKOWNIKA>\`."
    echo;
    echo "Wpisz \`minecraft help\` (lub \`sudo minecraft help\`), aby zapoznać się z tym nowym, fancy narzędziem!";
    exit 0;
fi

if [ "$1" = "uninstall" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi

    echo "NOTE: This script WILL NOT uninstall Docker. Do it yourself, if you so desire.";
    echo "  [1/3]"
    echo "Unlinking: $INSTALL_PATH";
    unlink "$INSTALL_PATH";
    echo "  [2/3]"
    chmod --verbose 777 "$FISH_PATH";
    echo "  [3/3]"
    rm -vf "$FISH_PATH";
    echo;
    echo "Uninstalled."
    echo;
    echo "Keep in mind, that $(pwd) still exists with all"
    echo "of its content, as uninstalling only reverts steps taken during \`install\` (except Docker),"
    echo "and $(pwd)'s creation wasn't a part of the installation."
    exit 0;
fi

if [ "$1" = "update" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi

    echo " ---UPDATE STARTED! :: STEP 1/6: DOWNLOAD---";
    echo "Sprzątanie po poprzednim update. Jeśli wywali błąd - super, już było czysto!";
    rm -rdfv "./update";
    echo "Oczyszczono. Teraz, mamy wolne miejsce do pobierania.";
    bash -c "$UPDATE_COMMAND";
    if [ $? -ne 0 ]; then
        echo "Nie udało się pobrać. Sprawdź błąd powyżej po szczegóły.";
        exit 1;
    fi

    echo;
    echo " ---STEP 2/6: UNINSTALLING THE OLDER SCRIPT AND DELETEING OLDER FILES---";
    
    $SCRIPT_PATH uninstall;
    if [ $? -ne 0 ]; then
        echo "Couldn't uninstall! See above for errors.";
        exit 1;
    fi
    
    chmod --verbose --recursive 777 "./scripts";
    if [ $? -ne 0 ]; then
        echo "Couldn't configure script permissions ahead of deletion! See above for errors.";
        exit 1;
    fi
    
    chmod --verbose 777 "./docker-compose.yml";
    if [ $? -ne 0 ]; then
        echo "Couldn't configure compose permissions ahead of overwrite! See above for errors.";
        chmod --verbose --recursive 050 "./scripts";
        if [ $? -ne 0 ]; then
            echo "Couldn't restore script permissions after the recent failure! THIS LEAVES YOUR SERVER IN A VULNERABLE STATE, PLEASE FIX ASAP! See above for errors.";
        fi
        exit 1;
    fi
    
    rm -rdfv "./scripts";
    if [ $? -ne 0 ]; then
        echo "Couldn't delete the scripts folder! See above for errors.";
        chmod --verbose --recursive 050 "./scripts";
        if [ $? -ne 0 ]; then
            echo "Couldn't restore script permissions after the recent failure! THIS LEAVES YOUR SERVER IN A VULNERABLE STATE, PLEASE FIX ASAP! See above for errors.";
        fi
        chmod --verbose --recursive 040 "./docker-compose.yml";
        if [ $? -ne 0 ]; then
            echo "Couldn't restore compose permissions after the recent failure! THIS LEAVES YOUR SERVER IN A VULNERABLE STATE, PLEASE FIX ASAP! See above for errors.";
        fi
        exit 1;
    fi
    
    chmod --verbose --recursive 777 "./web";
    if [ $? -ne 0 ]; then
        echo "Couldn't configure web permissions ahead of overwrite! See above for errors.";
        echo "We won't halt the update at this stage becasue the ./scripts directory is alread gone.";
        echo "Let's pray that this error won't cause a cascadning failure down the line.";
    fi
    
    rm -rdfv "./web/public/*";
    if [ $? -ne 0 ]; then
        echo "Couldn't delete public web contents ahead of overwrite! See above for errors.";
        echo "We won't halt the update at this stage becasue the ./scripts directory is alread gone.";
        echo "Let's pray that this error won't cause a cascadning failure down the line.";
    fi
    
    rm -fv "./web/etc-caddy/Caddyfile";
    if [ $? -ne 0 ]; then
        echo "Couldn't delete the Caddyfile ahead of overwrite! See above for errors.";
        echo "We won't halt the update at this stage becasue the ./scripts directory is alread gone.";
        echo "Let's pray that this error won't cause a cascadning failure down the line.";
    fi

    echo;
    echo " ---STEP 3/6: COPYING---";
    mkdir -p "./web/etc-caddy/"
    cp --verbose --force "./update/web/etc-caddy/Caddyfile" "./web/etc-caddy/";
    cp --verbose --recursive --force "./update/web/public" "./web/";
    cp --verbose --recursive "./update/scripts" "$(pwd)";
    cp "./update/docker-compose.yml" "./update/docker-compose-test.yml";
    GROUPID=$(cat /etc/group | grep docker | cut -d: -f3)
    if [ -z "$GROUPID" ]; then
        GROUPID="SOMETHING_IS_WRONG_BUT_IT_IS_NOT_MY_PROBLEM"
    fi
    sed -i -e "s/%DOCKER_GROUP_ID%/$GROUPID/g" "./update/docker-compose-test.yml";
    
    if cmp -s "./update/docker-compose-test.yml" "./docker-compose.yml"; then
        cp --verbose "./update/docker-compose.yml" "$(pwd)/docker-compose.yml";
    else
        echo "UWAGA! Definicje Kompozytora różnią się między wersjami!";
        echo "Aby poprawnie zaaplikować update, zrób \`minecraft start\` (nie restart).";
        echo "JEŚLI ROZUMIESZ - NACIŚNIJ DOWOLNY PRZYCISK ABY KONTYNUOWAĆ!";
        read -r -n 1 -s;
        cp --verbose "./update/docker-compose.yml" "$(pwd)/docker-compose.yml";
    fi
    chmod --verbose 777 "$SCRIPT_PATH";

    echo;
    echo " ---STEP 4/6: CLEANUP---";
    rm -rdfv "./update";
    if [ $? -ne 0 ]; then
        echo "Błąd czyszczenia. Patrz na wiadomość powyżej po szczegóły.";
        echo "Nie wpływa to negatywnie na resztę procesu aktualizacji, ale"
        echo "oznacza to więcej roboty dla ciebie. Gdy aktualizacja się";
        echo "zakończy, manualnie usuń folder \`$(pwd)/update/\`.";
        echo "JEŚLI ROZUMIESZ - NACIŚNIJ DOWOLNY PRZYCISK ABY KONTYNUOWAĆ!";
        read -r -n 1 -s;
    fi

    echo;
    echo " ---STEP 5/6: SEDDING---";
    sed -i -e "s:$INSTALL_PATH_LITERAL:$INSTALL_PATH:g" "$SCRIPT_PATH";
    if [ $? -ne 0 ]; then
        echo "SED wywalił błąd! Nie udało się zamienić $INSTALL_PATH_LITERAL na $INSTALL_PATH.";
        echo "W związku z błędem, aktualizację trzeba dokończyć manualnie:"
        echo "  - Zamień $INSTALL_PATH_LITERAL na $INSTALL_PATH w pliku $SCRIPT_PATH";
        echo "  - Wykonaj komendę \`sudo $SCRIPT_PATH install\`";
        exit 1;
    fi
    echo "Operacja SED zakończona. Zamieniono %INSTALL_PATH% na $INSTALL_PATH, bądź już było zamienione.";

    echo;
    echo " ---STEP 6/6: INSTALLING THE NEWER SCRIPT---";
    echo "This is the last step. In 10s, the installer will run for the newly-downloaded version.";
    sleep 10;
    echo;
    echo;
    echo "BOOTING UP THE INSTALLER...";
    echo;
    $SCRIPT_PATH install
    exit;
fi

if [ "$1" = "reinstall" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi

    echo " ---STEP 1/2: UNINSTALLING---";
    $SCRIPT_PATH uninstall;

    echo;
    echo " ---STEP 2/2: INSTALLING---";
    echo;
    echo;
    $SCRIPT_PATH install
    exit;
fi



 #  === DOCKER MANAGEMENT ===

if [ "$1" = "startd" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi
    echo "                        >>>>>    Status before:    <<<<<";
    systemctl status --no-pager -l docker.socket docker.service;
    systemctl enable docker.socket docker.service;
    systemctl start docker.socket docker.service;
    echo;
    echo "                        >>>>>    Status  after:    <<<<<";
    systemctl status --no-pager -l docker.socket docker.service;
    exit 0;
fi

if [ "$1" = "allow" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "$SUDO_NOTE";
        exit 1;
    fi

    if [ -z "$2" ]; then
        echo "You must provide a username.";
        exit 1;
    fi
    
    echo "Attempting to \`-a\` (append) \`$2\` into \`-G\` (group) \`docker\`";
    usermod -aG "docker" "$2";
    exit;
fi

if [ "$1" = "cleanup" ]; then
    docker rmi "ghostland-ci";
    exit;
fi



 #  === MISC. ===

if [ "$1" = "test" ]; then
    exit 0;
fi

if [ "$1" = "help" ]; then
    echo " ---ZARZĄDZANIE SERWEREM---";
    echo "  - (brak parametru)"
    echo "     \ Podłącza konsolę. Z konsoli może korzystać kilka osób na raz i da się nią scrollować. Take that, \`screen\`!"
    echo "  - start"
    echo "     \ TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO (*works, but no docs)"
    echo "  - stop"
    echo "     \ Zatrzymuje serwer MC. Jeśli chcesz monitorować status zatrzymywania, wpisz \`minecraft\` z osobnej sesji SSH."
    echo "       UWAGA: Komendy stop i kill to JEDYNY sposób na zatrzymanie serwera MC - użycie \`/stop\` w MC ztriggeruje auto-restart."
    echo "  - stop ALL"
    echo "     \ Zatrzymuje WSZYSTKO. Jeśli chcesz monitorować status zatrzymywania, wpisz \`minecraft\` z osobnej sesji SSH."
    echo "       UWAGA: WSZYSTKO = każdy serwis w Compose. Używać tylko w awaryjnch przypadkach lub przy wyłączaniu maszyny!"
    echo "  - stop <serwis>"
    echo "     \ Zatrzymuje dany serwis. Jeśli chcesz monitorować status zatrzymywania, wpisz \`minecraft inspect <serwis>\` z osobnej sesji SSH."
    echo "  - send"
    echo "     \ Otwiera interaktywne menu RCON."
    echo "       UWAGA: Podobnie, jak w konsoli MC - nie pisz slasha na początku!"
    echo "  - send \"<komenda>\""
    echo "     \ Wysyła komendę przez RCON."
    echo "       UWAGA: Podobnie, jak w konsoli MC - nie pisz slasha na początku!"
    echo "       UWAGA: Nie bez powodu jest \"<komenda>\", nie <komenda> - wpisanie komendy ze spacją (eg. \`\"say Hi!\"\`),"
    echo "              ale bez „uszu” (ie. \`say Hi!\`) wyśle tylko pierwsze słowo (ie. serwer zobaczy \`/say\` zamiast \`/say Hi!\`)."
    echo "  - health"
    echo "     \ Wykonuje healthcheck serwera w przyjaznej dla automatyzacji formie."
    echo "  - restart"
    echo "     \ Restartuje serwer. Jeśli chcesz monitorować status restartowania, wpisz \`minecraft\` z osobnej sesji SSH."
    echo "  - kill [opcjonalny parametr, jak w \`stop\`]"
    echo "     \ Jak \`stop\`, ale dodatkowo usuwa kontener(y). To NIE ZNACZY, że usunięte zostaną jakiekolwiek dane - te zapisywane są poza kontenerem."
    echo "  - inspect <serwis>"
    echo "     \ Wyświetla logi dowolnego serwisu, np. ci lub backuper. (Lub minecraft, ale to można zrobić uruchamiając skrypt bez parametru.)"
    echo "  - sh <serwis>"
    echo "     \ Otwiera shella w danym serwisie."
    echo;
    echo " ---ZARZĄDZANIE FOLDEREM---";
    echo "  - workdir"
    echo "     \ Pokazuje folder, z poziomu którego operuje ten skrypt."
    echo "  - fixown"
    echo "     \ Serwer lubi czasem zabrać innym permisje do swojego folderu. Ta pod-komenda ustawia permisje w taki sposób, że:"
    echo "       a) Członkowie grupy \`docker\` mogą bez problemu interaktować z workdirem (nie licząc edycji skryptów i compose)."
    echo "       b) Serwer będzie działać. (Co ważne, bo jeśli ustawia się permisje manualnie - można go przypadkiem zablokować. Z doświadczenia.)"
    echo "       c) Exposowane są minimalne wymagane uprawnienia, aby osiągnąć wszystko powyżej - thus minimalizując attack surface."
    echo "       Fixown dodatkowo ustawia ownership na $PHANTOM_USER:docker, na wypadek gdyby permisje popsuły się „odwrotnie” (dla serwera).";
    echo "       UWAGA: Rób to ZAWSZE, gdy DODAJESZ pliki!!!!!!!!"
    echo "       [Tę komendę należy wykonać jako root, nawet jeśli jest się w grupie \`docker\`!]"
    echo "  - mark-stopped"
    echo "     \ Usuwa lockfile. Wpływa to jedynie na wiadomości tekstowe, więc RACZEJ powinno być bezpieczne (nawet, jeśli serwer tak na prawdę nie jest wyłączony)."
    echo;
    echo " ---ZARZĄDZANIE SKRYPTEM---";
    echo "  [UWAGA: Wszystkie pod-komendy należy wykonać jako root, nawet jeśli jest się w grupie \`docker\`!]"
    echo "  - install"
    echo "     \ Uruchamia instalator. Po jego zakończeniu, skrypt powinien znaleźć się w $INSTALL_PATH."
    echo "  - uninstall"
    echo "     \ Odinstalowuje skrypt, tj. odwóci akcje wykonane podczas instalacji."
    echo "       UWAGA: Nie usunie to folderu $(pwd), bo jego powstanie to nie efekt instalacji."
    echo "       UWAGA: Nie odinstaluje to Dockera, nawet jeśli został zainstalowany podczas instalacji skryptu!"
    echo "  - update"
    echo "     \ Aktualizuje skrypt. Patrz poniżej po informacje o konfiguracji."
    echo "  - reinstall"
    echo "     \ Odinstalowuje skrypt, a następnie uruchamia instalator. Trochę jak \`update\`, ale nic nie pobiera."
    echo;
    echo " ---ZARZĄDZANIE DOCKEREM---";
    echo "  [UWAGA: Wszystkie pod-komendy należy wykonać jako root, nawet jeśli jest się w grupie \`docker\`!]"
    echo "  - startd"
    echo "     \ Uruchamia daemon Dockera. Powinno wrzucić go również do autostartu, ale to nie zawsze działa."
    echo "  - allow <NAZWA_UŻYTKOWNIKA>"
    echo "     \ Dodaje wybranego użytkownika do grupy \`docker\`."
    echo "  - cleanup"
    echo "     \ Cleans up all images built by this compose file. Does NOT need sudo, unlike all other commands in this section."
    echo;
    echo " ---RÓŻNE---";
    echo "  - test"
    echo "     \ Zwraca exit code 0. Używane wewnętrznie."
    echo "  - help"
    echo "     \ Pokazuje ten ekran."
    echo;
    echo " ---INFORMACJE I KONCEPCJE---";
    echo "  - Fantomowy Użytkownik: $PHANTOM_USER"
    echo "     \ Cały system się bardzo ostro zjebie, jeśli kiedykolwiek przypadkiem powstanie użytkownik o ID $PHANTOM_USER."
    echo "       Obecnie, przyjmujemy za fakt, że nie istnieje on na hoście, ale istnieje w kontenerze. Na tym założeniu zbudowany"
    echo "       jest cały układ permisji. Jeśli kiedykolwiek przestanie ono być prawdą, trzeba będzie manualnie zedytować ten skrypt (linijka 14)"
    echo "       oraz \`docker-compose.yml\` i wskazać je na nowego Fantomowego Użytkownika, a następnie wykonać \`sudo minecraft fixown\`."
    echo "  - Permisje"
    echo "     \ Dodaj wszystkich ważnych adminów do grupy \`docker\`. W ten sposób, będą oni mogli:";
    echo "         - Dowolnie interaktować z workdirem - chodź czasem będzie to wymagało zrobienia \`sudo minecraft fixown\`"
    echo "         - Wykonywać część komend (np. startować serwer) jako \`minecraft [komenda]\`, a nie \`sudo minecraft [komenda]\` - patrz powyżej po listę."
    echo "         - Widzieć auto-completion \`minecraft\` i \`sudo minecraft\`."
    echo "       Zrobisz to za pomocą \`sudo minecraft allow <NAZWA_UŻYTKOWNIKA>\`."
    echo "  - Zmiana lokalizacji FISHa"
    echo "     \ Na linijce 13 w tym skrypcie, znajduje się zmienna, której wartość wskazuje na położenie pliku z autocomplete FISHa."
    echo "       Domyślnie, wartość tej zmiennej to: $DEFAULT_FISH_PATH - tj. standardowa instalacja FISH, a komenda skryptu po instalacji to \`minecraft\`."
    echo "       Jeśli używasz nietypowej instalacji FISH lub skrypt nie wywołujesz skryptu komendą \`minecraft\`, zmień wartość owej zmiennej."
    echo "       UWAGA: Jeśli używasz ścieżki relatywnej - pamiętaj, że jest ona relatywna względem workdira."
    echo "       UWAGA: Edytuj zmienną \$FISH_PATH, a nie \$DEFAULT_FISH_PATH."
    echo "  - Konfigurowanie auto-aktualizacji"
    echo "     \ Na linijce 16-19 w tym skrypcie, znajdują się zmienne, które interpretowane są jako komendy pobrania paczki aktualizacji."
    echo "       Odkomentuj opcję, która tobie odpowaida oraz odpowiednio ją dostosuj (np. zamień adres URL), bądź napisz własną od podstaw."
    exit 0;
fi


echo "Unknown sub-command: $1. Use „help” for help.";
exit 1;


#magic sauce uwu totally nie sperma