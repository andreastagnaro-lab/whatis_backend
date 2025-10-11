#!/bin/bash
# ⚓ Backup automatico intelligente con log + notifiche — Andaly Whatis Backend

cd ~/Desktop/whatis_backend || exit

LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/backup.log"
mkdir -p "$LOG_DIR"

DATA=$(date +"%Y-%m-%d_%H-%M")
TAG="backup_$DATA"
DEST="/Volumes/HD di Andrea/Backup_Whatis/$DATA"

notify() {
  osascript -e "display notification \"$2\" with title \"$1\""
}

echo "🧭 Avvio controllo backup intelligente..."
echo "[$(date +"%Y-%m-%d %H:%M:%S")] ▶️ Avvio controllo backup intelligente..." >> "$LOG_FILE"

# 1️⃣ Controlla ultimo backup Git
LAST_TAG=$(git tag --sort=-creatordate | head -n 1)
if [ -z "$LAST_TAG" ]; then
  echo "⚠️ Nessun backup precedente trovato — ne creo uno."
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] ⚠️ Nessun backup precedente trovato." >> "$LOG_FILE"
  NEED_BACKUP=true
else
  LAST_DATE=$(echo "$LAST_TAG" | sed 's/backup_//')
  LAST_TIMESTAMP=$(date -j -f "%Y-%m-%d_%H-%M" "$LAST_DATE" +%s 2>/dev/null)
  NOW_TIMESTAMP=$(date +%s)
  if [ -n "$LAST_TIMESTAMP" ] && [ $((NOW_TIMESTAMP - LAST_TIMESTAMP)) -lt 86400 ]; then
    echo "✅ Backup recente trovato ($LAST_TAG) — nessuna azione necessaria."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ✅ Backup recente ($LAST_TAG), nessuna azione." >> "$LOG_FILE"
    NEED_BACKUP=false
  else
    echo "🕒 Ultimo backup vecchio di più di 24 ore — ne creo uno nuovo."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] 🕒 Ultimo backup >24h, creazione nuovo." >> "$LOG_FILE"
    NEED_BACKUP=true
  fi
fi

# 2️⃣ Esegue backup se necessario
if [ "$NEED_BACKUP" = true ]; then
  git add .
  git commit -m "🧭 Backup automatico $DATA"
  git tag -a "$TAG" -m "Backup giornaliero del $DATA"
  echo "✅ Backup Git creato con tag: $TAG"
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] ✅ Backup Git creato ($TAG)." >> "$LOG_FILE"

  # 3️⃣ Copia su HD esterno se collegato
  if [ -d "/Volumes/HD di Andrea" ]; then
    mkdir -p "$DEST"
    rsync -av --exclude 'node_modules' --exclude '.git' ./ "$DEST/" >> "$LOG_FILE" 2>&1
    echo "💾 Copia completata su HD esterno: $DEST"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] 💾 Copia su HD completata: $DEST" >> "$LOG_FILE"
    notify "✅ Backup completato" "Copia salvata anche su HD esterno"
  else
    echo "⚠️ HD di Andrea non trovato — copia saltata."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ⚠️ HD non collegato — copia saltata." >> "$LOG_FILE"
    notify "⚠️ Backup parziale" "HD di Andrea non collegato — copia saltata"
  fi

  echo "✅ Backup intelligente completato."
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] ✅ Backup completato con successo." >> "$LOG_FILE"
else
  echo "⏸ Nessuna operazione eseguita — backup già aggiornato."
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] ⏸ Nessuna operazione (backup già aggiornato)." >> "$LOG_FILE"
  notify "ℹ️ Nessuna azione necessaria" "Backup già aggiornato ($LAST_TAG)"
fi
