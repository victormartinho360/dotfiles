# ==============================================================================
# ZSH CONFIGURATION - Minimalist Tokyo Night + Hybrid Vi-Mode + FZF-Tab
# ==============================================================================

# Se não for interativo, encerra imediatamente
[[ -o interactive ]] || return

# ------------------------------------------------------------------------------
# 1. VARIÁVEIS DE AMBIENTE E PATH
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export KEYTIMEOUT=1

# Homebrew (Linuxbrew) - inline para startup em 0ms
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
  export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
  fpath=("/home/linuxbrew/.linuxbrew/share/zsh/site-functions" $fpath)
  export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
fi

# Cargo / Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Deduplica o PATH automaticamente no Zsh
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/bob/nvim-bin"
  "$HOME/go/bin"
  "$HOME/.cargo/bin"
  "/home/linuxbrew/.linuxbrew/bin"
  "/home/linuxbrew/.linuxbrew/sbin"
  $path
  "$HOME/anaconda3/bin"
)
export PATH

# ------------------------------------------------------------------------------
# 2. LAZY-LOAD: CONDA (STARTUP INSTANTÂNEO)
# ------------------------------------------------------------------------------
# Conda é carregado apenas quando você chama `conda` pela primeira vez
_lazy_conda_init() {
  unfunction conda mamba 2>/dev/null
  local __conda_setup
  __conda_setup="$("$HOME/anaconda3/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  elif [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
  fi
}
conda() { _lazy_conda_init && conda "$@"; }
mamba() { _lazy_conda_init && mamba "$@"; }

# ------------------------------------------------------------------------------
# 3. OPÇÕES DO ZSH & HISTÓRICO INTELIGENTE
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Salva timestamp no histórico
setopt SHARE_HISTORY             # Compartilha histórico em tempo real entre abas do Tmux
setopt HIST_EXPIRE_DUPS_FIRST    # Remove duplicados primeiro ao atingir limite
setopt HIST_IGNORE_DUPS          # Não grava comando repetido em sequência
setopt HIST_IGNORE_ALL_DUPS      # Remove ocorrências antigas do mesmo comando
setopt HIST_FIND_NO_DUPS         # Não exibe duplicatas na busca
setopt HIST_IGNORE_SPACE         # Comandos iniciados com espaço não vão pro histórico
setopt HIST_REDUCE_BLANKS        # Remove espaços extras
setopt HIST_VERIFY               # Permite revisar expansões de histórico (!!) antes de rodar

setopt AUTO_CD                   # Digitar nome de pasta faz cd automaticamente
setopt AUTO_PUSHD                # cd empilha diretórios automaticamente (use `dirs -v`)
setopt PUSHD_IGNORE_DUPS         # Não empilha diretórios repetidos
setopt PUSHD_SILENT              # Não imprime a pilha a cada cd
setopt INTERACTIVE_COMMENTS      # Permite comentários (#) no prompt interativo
setopt EXTENDED_GLOB             # Globbing avançado do Zsh
setopt NO_BEEP                   # Sem beep sonoro

# Cores de listagem (dircolors)
if [[ -x /usr/bin/dircolors ]]; then
  [[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ------------------------------------------------------------------------------
# 4. PLUGINS & AUTOCOMPLETE (FZF-TAB + AUTOSUGGESTIONS + SYNTAX + SUBSTRING)
# ------------------------------------------------------------------------------
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# Auto-instala plugins caso rode em uma máquina nova
_ensure_zsh_plugin() {
  local repo="$1"
  local name="${repo#*/}"
  if [[ ! -d "$ZSH_PLUGIN_DIR/$name" ]]; then
    mkdir -p "$ZSH_PLUGIN_DIR"
    git clone --depth=1 "https://github.com/$repo.git" "$ZSH_PLUGIN_DIR/$name" >/dev/null 2>&1
  fi
}

_ensure_zsh_plugin "zsh-users/zsh-completions"
_ensure_zsh_plugin "Aloxaf/fzf-tab"
_ensure_zsh_plugin "marlonrichert/zsh-autocomplete"
_ensure_zsh_plugin "zsh-users/zsh-autosuggestions"
_ensure_zsh_plugin "zdharma-continuum/fast-syntax-highlighting"
_ensure_zsh_plugin "zsh-users/zsh-history-substring-search"

# Adiciona zsh-completions ao fpath antes do compinit
fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)

# Inicializa o sistema de completion com cache diário (rápido)
autoload -Uz compinit
if [[ -n "$ZSH_CACHE_DIR/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$ZSH_CACHE_DIR/zcompdump"
else
  compinit -C -d "$ZSH_CACHE_DIR/zcompdump"
fi

# Configurações do Completion nativo
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Ativa o keymap Vi antes dos plugins para todos registrarem atalhos em `viins`
bindkey -v

# FZF base (carregado ANTES do fzf-tab para que o Tab continue com o fzf-tab-complete)
export FZF_DEFAULT_OPTS=" \
  --height=60% \
  --layout=reverse \
  --border=rounded \
  --info=inline-right \
  --pointer='󰅂' \
  --marker='✓' \
  --color=bg+:#283457,bg:#16161e,spinner:#7dcfff,hl:#bb9af7 \
  --color=fg:#c0caf5,header:#7aa2f7,info:#e0af68,pointer:#bb9af7 \
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff,border:#3b4261"

if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Modo 1 (Padrão): fzf-tab (popup fuzzy no Tab com preview)
# Modo 2 (Opcional): zsh-autocomplete (menu dropdown automático ao digitar, ative com `autocomplete-live`)
if [[ "${ZSH_LIVE_AUTOCOMPLETE:-0}" == "1" ]] && [[ -f "$ZSH_PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
elif [[ -f "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
  bindkey -M viins '^I' fzf-tab-complete

  # Estilo Tokyo Night e Previews no fzf-tab
  zstyle ':fzf-tab:*' fzf-flags \
    --height=55% \
    --layout=reverse \
    --border=rounded \
    --info=inline-right \
    --pointer='󰅂' \
    --marker='✓' \
    --color='bg+:#283457,bg:#16161e,spinner:#7dcfff,hl:#bb9af7' \
    --color='fg:#c0caf5,header:#7aa2f7,info:#e0af68,pointer:#bb9af7' \
    --color='marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff,border:#3b4261'
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -la --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:(nvim|vim|cat|less|head|tail):*' fzf-preview \
    '[[ -d $realpath ]] && ls -la --color=always $realpath || head -n 100 $realpath 2>/dev/null'
fi

# Funções para alternar na hora entre fzf-tab e zsh-autocomplete live dropdown
autocomplete-live() { export ZSH_LIVE_AUTOCOMPLETE=1 && exec zsh; }
autocomplete-fzf()  { export ZSH_LIVE_AUTOCOMPLETE=0 && exec zsh; }

# Carrega zsh-autosuggestions (sugestões em tempo real baseadas em histórico + completion)
if [[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Carrega fast-syntax-highlighting
if [[ -f "$ZSH_PLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

# Carrega zsh-history-substring-search
if [[ -f "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=#283457,fg=#7dcfff,bold"
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="bg=#f7768e,fg=#16161e,bold"
  HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS="i"
fi

# ------------------------------------------------------------------------------
# 5. VI-MODE HÍBRIDO + ATALHOS DE TECLADO
# ------------------------------------------------------------------------------
bindkey -v

# Editar comando atual diretamente no Neovim (Ctrl+X Ctrl+E no Insert ou `v` no Normal)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^X^E' edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Muda a forma do cursor conforme o modo Vi (Barra no Insert, Bloco no Normal)
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 == 'block' ]]; then
    echo -ne '\e[1 q'
  else
    echo -ne '\e[5 q'
  fi
  zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-init {
  zle -K viins
  echo -ne '\e[5 q'
}
zle -N zle-line-init

# Mantém atalhos clássicos de terminal funcionando dentro do modo Insert (Vi-Mode Híbrido)
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^F' forward-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^L' clear-screen
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '\ef' forward-word
bindkey -M viins '\eb' backward-word

# Teclas especiais (Home, End, Delete, Ctrl+Setas)
bindkey -M viins '^[[H'  beginning-of-line
bindkey -M viins '^[[F'  end-of-line
bindkey -M viins '^[[3~' delete-char
bindkey -M vicmd '^[[3~' delete-char
bindkey -M viins '^[[1;5C' forward-word
bindkey -M viins '^[[1;5D' backward-word

# History Substring Search nas setas ↑/↓, Ctrl+P/N e k/j no modo Normal
if (( $+functions[history-substring-search-up] )); then
  bindkey -M viins '^[[A' history-substring-search-up
  bindkey -M viins '^[[B' history-substring-search-down
  bindkey -M viins '^[OA' history-substring-search-up
  bindkey -M viins '^[OB' history-substring-search-down
  bindkey -M viins '^P'   history-substring-search-up
  bindkey -M viins '^N'   history-substring-search-down
  bindkey -M vicmd 'k'    history-substring-search-up
  bindkey -M vicmd 'j'    history-substring-search-down
fi

# (FZF e Zoxide já inicializados na seção 4 antes do fzf-tab)

# ------------------------------------------------------------------------------
# 7. PROMPT TOKYO NIGHT MINIMALISTA (1 LINHA)
# ------------------------------------------------------------------------------
setopt PROMPT_SUBST

# Mede o tempo de execução dos comandos
zmodload zsh/datetime
preexec() {
  _cmd_start_time=$EPOCHREALTIME
}

precmd() {
  local exit_code=$?
  # Tempo de execução se >= 2s
  if [[ -n $_cmd_start_time ]]; then
    local elapsed=$(( EPOCHREALTIME - _cmd_start_time ))
    local secs=${elapsed%.*}
    if (( secs >= 2 )); then
      if (( secs >= 60 )); then
        _prompt_cmd_time="%F{#e0af68}󱎫 $((secs / 60))m$((secs % 60))s%f "
      else
        _prompt_cmd_time="%F{#e0af68}󱎫 ${secs}s%f "
      fi
    else
      _prompt_cmd_time=""
    fi
    unset _cmd_start_time
  else
    _prompt_cmd_time=""
  fi

  # Status Git rápido
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if [[ -n "$(git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)" ]]; then
      _prompt_git=" %F{#bb9af7}󰊢 ${branch}%f%F{#e0af68}*%f"
    else
      _prompt_git=" %F{#bb9af7}󰊢 ${branch}%f"
    fi
  else
    _prompt_git=""
  fi
}

_prompt_vi_symbol() {
  if [[ "${KEYMAP}" == "vicmd" ]]; then
    echo "%B%F{#bb9af7}❮%f%b"
  else
    echo "%(?.%B%F{#7dcfff}❯%f%b.%B%F{#f7768e}❯%f%b)"
  fi
}

_prompt_env_badge() {
  local badge=""
  [[ -n "$CONDA_DEFAULT_ENV" ]] && badge+="%F{#9ece6a}(${CONDA_DEFAULT_ENV})%f "
  [[ -n "$VIRTUAL_ENV" ]] && badge+="%F{#9ece6a}(${VIRTUAL_ENV:t})%f "
  echo "$badge"
}

PROMPT='$(_prompt_env_badge)%B%F{#7aa2f7}%2~%f%b${_prompt_git} $(_prompt_vi_symbol) '
RPROMPT='${_prompt_cmd_time}'

# ------------------------------------------------------------------------------
# 8. ALIASES & FUNÇÕES ÚTEIS
# ------------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -alFh --color=auto'
alias la='ls -AF --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias v='nvim'
alias lg='lazygit'
alias ff='fastfetch'
alias c='clear'
alias reload='source ~/.zshrc && echo "󰑓 ~/.zshrc recarregado!"'

# Git rápidos
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -n 20'

# Cria diretório e já entra nele
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ------------------------------------------------------------------------------
# 9. AUTO-FASTFETCH NO STARTUP (APENAS EM PAINÉIS COM ESPAÇO SUFICIENTE)
# ------------------------------------------------------------------------------
if command -v fastfetch >/dev/null 2>&1 && [[ -z "$FASTFETCH_SHOWN" ]]; then
  export FASTFETCH_SHOWN=1
  if (( COLUMNS >= 80 && LINES >= 18 )); then
    fastfetch
  fi
fi
