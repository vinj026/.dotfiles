# ==============================================================================
# FISH SHELL CONFIGURATION
# ==============================================================================

# Autostart MangoWM on tty1 login
if status is-login
    if test -z "$WAYLAND_DISPLAY" -a "$XDG_VTNR" = 1
        exec mango
    end
end

# Disable welcome greeting
set -g fish_greeting ""

# Environment & PATH
set -gx PATH "$HOME/.local/bin" $PATH
set -gx QT_QPA_PLATFORMTHEME qt6ct
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1

# Prompt / Shell integration
if test "$TERM_PROGRAM" = "kiro"
    string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish 2>/dev/null)
end

if status is-interactive

    # Starship Prompt
    if command -q starship
        starship init fish | source
    end

    # Zoxide (Smart directory jumping)
    if command -q zoxide
        zoxide init fish | source
    end

    # Modern CLI Aliases (eza, bat, lazygit)
    if command -q eza
        alias ls="eza --icons --group-directories-first"
        alias ll="eza -la --icons --group-directories-first --git"
        alias la="eza -a --icons --group-directories-first"
        alias lt="eza --tree --level=2 --icons"
        alias tree="eza --tree --icons"
    else
        alias ls="ls --color=auto"
        alias ll="ls -lah --color=auto"
    end

    if command -q bat
        alias cat="bat --paging=never"
    end

    if command -q lazygit
        alias lg="lazygit"
    end

    if command -q fastfetch
        alias ff="fastfetch"
    end

    # FZF Integration & Keybindings (Ctrl+T for file search, Ctrl+R for history, Alt+C for cd)
    if command -q fzf
        fzf --fish | source
        if command -q fd
            set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
            set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git"
        end
        if command -q bat
            set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}'"
        end
    end
end
