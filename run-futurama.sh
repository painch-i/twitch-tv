#!/bin/bash

# Variables à modifier
TWITCH_KEY=""  # Remplace par ta clé de stream Twitch
INPUT_FOLDER="/var/lib/transmission-daemon/downloads/Futurama.S08.COMPLETE.720p.DSNP.WEBRip.x264-GalaxyTV[TGx]"  # Chemin vers le dossier contenant les fichiers vidéo
PLAYLIST_FILE="playlist.txt"  # Nom du fichier playlist
STREAM_URL="rtmp://live.twitch.tv/app/$TWITCH_KEY"
LOG_FILE="stream_logs.txt"  # Fichier de log

# Créer le fichier playlist.txt avec le bon format pour FFmpeg
echo "Génération de la playlist..." | tee -a "$LOG_FILE"
cd "$INPUT_FOLDER" || { echo "Impossible d'accéder au dossier $INPUT_FOLDER" | tee -a "$LOG_FILE"; exit 1; }

# Vider le fichier playlist s'il existe
> "$PLAYLIST_FILE"

# Ajouter chaque fichier vidéo au fichier playlist.txt avec le bon format
for file in *.mkv; do
    if [[ -f "$file" ]]; then
        echo "file '$(pwd)/$file'" >> "$PLAYLIST_FILE"
        echo "Ajout de '$file' à la playlist." | tee -a "$LOG_FILE"
    fi
done

# Vérifier que le fichier playlist a été créé et contient des vidéos
if [[ ! -s "$PLAYLIST_FILE" ]]; then
    echo "Aucune vidéo trouvée dans le dossier." | tee -a "$LOG_FILE"
    exit 1
fi


# Boucle infinie pour relancer ffmpeg indéfiniment
while true; do
    # Streamer la playlist sur Twitch et rediriger les logs de FFmpeg
    echo "Démarrage du stream..." | tee -a "$LOG_FILE"
    ffmpeg -re -stream_loop -1 -f concat -safe 0 -i "$PLAYLIST_FILE" \
        -c:v libx264 -preset veryfast -b:v 2500k -maxrate 3000k -bufsize 7500k \
        -pix_fmt yuv420p -r 30 -g 60 \
        -c:a aac -b:a 160k -ar 44100 \
        -f flv -flvflags no_duration_filesize \
        -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 2 \
        -tune zerolatency \
        "$STREAM_URL" 2>&1 | tee -a "$LOG_FILE"

    
    # Attendre 10 secondes avant de relancer
    echo "FFmpeg s'est arrêté. Redémarrage dans 10 secondes..." | tee -a "$LOG_FILE"
    sleep 10
done

# Supprimer le fichier playlist après le stream
echo "Suppression de la playlist..." | tee -a "$LOG_FILE"
rm "$PLAYLIST_FILE"