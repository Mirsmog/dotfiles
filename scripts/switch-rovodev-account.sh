#!/bin/bash

# Скрипт для автоматизации смены аккаунтов Rovo Dev
# Использование: ./switch-rovodev-account.sh
# Интегрирован с rovo-farm проектом

# Путь к accounts.json из rovo-farm
ACCOUNTS_FILE="$HOME/Public/wip/rovo-farm/data/accounts.json"
ACLI_CMD="acli"

# Проверка наличия файла с аккаунтами
if [ ! -f "$ACCOUNTS_FILE" ]; then
    echo "❌ Файл $ACCOUNTS_FILE не найден!"
    echo "   Запустите rovo-farm для создания аккаунтов:"
    echo "   cd ~/Public/wip/rovo-farm && bun run index.ts 5"
    exit 1
fi

# Проверка наличия jq для работы с JSON
if ! command -v jq &> /dev/null; then
    echo "❌ Требуется установить jq для работы с JSON"
    echo "   Установите: sudo apt install jq (Linux) или brew install jq (macOS)"
    exit 1
fi

# Шаг 1: Logout из текущего аккаунта
echo "🔓 Выполняется logout из текущего аккаунта..."
$ACLI_CMD rovodev auth logout 2>/dev/null || true
echo "✅ Logout выполнен"

# Шаг 2: Поиск первого неиспользованного аккаунта
UNUSED_COUNT=$(jq '[.[] | select(.used == false or .used == null)] | length' "$ACCOUNTS_FILE")

# Если все аккаунты использованы - выйти
if [ "$UNUSED_COUNT" = "0" ]; then
    echo "⚠️  Все аккаунты были использованы"
    echo "   Аккаунтов больше нет"
    exit 1
fi

# Получить индекс первого неиспользованного аккаунта
ACTUAL_INDEX=$(jq "to_entries | map(select(.value.used == false or .value.used == null)) | .[0].key" "$ACCOUNTS_FILE")

# Получить данные аккаунта (используем apiToken вместо key)
EMAIL=$(jq -r ".[$ACTUAL_INDEX].email" "$ACCOUNTS_FILE")
TOKEN=$(jq -r ".[$ACTUAL_INDEX].apiToken" "$ACCOUNTS_FILE")
SITE_URL=$(jq -r ".[$ACTUAL_INDEX].siteUrl" "$ACCOUNTS_FILE")

if [ -z "$EMAIL" ] || [ "$EMAIL" = "null" ] || [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "❌ Не удалось получить данные аккаунта"
    exit 1
fi

# Шаг 3: Login с новым аккаунтом
echo ""
echo "🔐 Выполняется login с аккаунтом: $EMAIL"
echo "   Site: $SITE_URL"
echo "$TOKEN" | $ACLI_CMD rovodev auth login --email "$EMAIL" --token

if [ $? -eq 0 ]; then
    echo "✅ Login успешно выполнен"
    
    # Шаг 4: Пометить аккаунт как использованный
    jq ".[$ACTUAL_INDEX].used = true" "$ACCOUNTS_FILE" > "${ACCOUNTS_FILE}.tmp" && mv "${ACCOUNTS_FILE}.tmp" "$ACCOUNTS_FILE"
    echo "✅ Аккаунт помечен как использованный"
    
    # Показать статистику
    TOTAL=$(jq 'length' "$ACCOUNTS_FILE")
    USED=$(jq '[.[] | select(.used == true)] | length' "$ACCOUNTS_FILE")
    REMAINING=$((TOTAL - USED))
    
    echo ""
    echo "📊 Статистика аккаунтов:"
    echo "   Всего: $TOTAL"
    echo "   Использовано: $USED"
    echo "   Осталось: $REMAINING"
else
    echo "❌ Ошибка при выполнении login"
    exit 1
fi
