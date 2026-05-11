# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io/).

## Stack

- **OS:** Void Linux
- **WM:** niri (Wayland)
- **Shell:** bash
- **Terminal:** ghostty
- **Multiplexer:** tmux
- **File manager:** yazi
- **Bar:** waybar
- **Notifications:** mako
- **Launcher:** fuzzel
- **Lock:** swaylock
- **System monitor:** btop

## Fresh install (one command)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME
```

chezmoi спросит: имя, email, роль машины (`home` / `work` / `server`).

## Manual install

```bash
# Void Linux
sudo xbps-install -y chezmoi

chezmoi init https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git
chezmoi apply
```

## Daily usage

```bash
# Посмотреть что изменилось в реальных файлах
chezmoi diff

# Применить изменения из source → home
chezmoi apply

# Добавить новый конфиг
chezmoi add ~/.config/newapp/config

# Редактировать файл в source
chezmoi edit ~/.bashrc

# Пушнуть изменения
chezmoi cd && git add -A && git commit -m "feat: ..." && git push
```

## Machine roles

| Role | Отличия |
|---|---|
| `home` | стандарт |
| `work` | + HTTP proxy env vars |
| `server` | без tmux auto-attach, без Wayland |

## Structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl   # интерактивная настройка при init
├── dot_bashrc.tmpl      # шаблон с условиями по роли
├── dot_bash_aliases
├── dot_bash_profile
├── dot_bash_logout
├── dot_inputrc
├── dot_tmux.conf
└── dot_config/
    ├── niri/
    ├── yazi/
    ├── waybar/
    ├── mako/
    ├── ghostty/
    ├── btop/
    ├── fuzzel/
    └── swaylock/
```
