# Dotfiles

Мои настройки для bash, tmux и git.

## Быстрая установка

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Структура

```
dotfiles/
├── .bashrc           # Основная конфигурация bash
├── .bash_profile     # Загружается при login shell
├── .bash_aliases     # Алиасы (docker, git, pnpm, npm, etc.)
├── .tmux.conf        # Конфигурация tmux
├── .gitconfig        # Глобальные настройки git
├── .secrets.example  # Шаблон для секретов (API ключи)
├── scripts/          # Утилиты
│   ├── clone-repo.sh
│   ├── toggle-proxy.sh
│   └── switch-rovodev-account.sh
├── install.sh        # Скрипт установки
└── README.md
```

## Зависимости

Опциональные, но рекомендуемые:

- [starship](https://starship.rs/) - красивый промпт
- [zoxide](https://github.com/ajeetdsouza/zoxide) - умный `cd` (`z` команда)
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder (Ctrl+R для истории)
- [eza](https://github.com/eza-community/eza) - современный `ls`
- [nvim](https://neovim.io/) - редактор

```bash
# Arch Linux
sudo pacman -S starship zoxide fzf eza neovim

# Ubuntu/Debian
# starship: curl -sS https://starship.rs/install.sh | sh
# zoxide: curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
# fzf: sudo apt install fzf
# eza: cargo install eza
```

## Tmux

Префикс: `Ctrl+a` (вместо `Ctrl+b`)

Основные биндинги:
- `prefix + |` - вертикальный сплит
- `prefix + -` - горизонтальный сплит
- `prefix + h/j/k/l` - навигация по панелям (vim-style)
- `prefix + r` - перезагрузить конфиг
- `prefix + Tab` - переключиться на последнюю сессию
- `prefix + S` - создать новую сессию

### Плагины (TPM)

Установка TPM:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

После этого в tmux нажми `prefix + I` чтобы установить плагины:
- tmux-sensible - разумные дефолты
- tmux-resurrect - сохранение сессий
- tmux-continuum - автосохранение

## Секреты

Скопируй шаблон и заполни свои ключи:

```bash
cp ~/dotfiles/.secrets.example ~/.secrets
nvim ~/.secrets
```

**ВАЖНО:** `.secrets` никогда не коммитится в git!

## Персонализация

Для машиноспецифичных настроек создай `~/.bashrc.local` - он автоматически подгружается.
