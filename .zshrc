# ~/.zshrc


# Node (direct path)
export NVM_DIR=~/.nvm
export PATH="$NVM_DIR/versions/node/v20.19.0/bin:$PATH"

# Android Studio paths
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Pyenv (minimal - no eval)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# ===== INTERACTIVE-ONLY SETUP =====
# Everything below only runs for manual/interactive terminals

# zsh-autosuggestion
source $HOME/Tools/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load Git completion
autoload -Uz compinit && compinit
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

# Powerlevel10k
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM (full initialization with auto-switching)
source $(brew --prefix nvm)/nvm.sh
nvm use 20.19.0

# Pyenv (full initialization with shims)
eval "$(pyenv init --path)"

# Aliases (available everywhere)
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alh'
alias gs='git status'
alias ga='git add .'
alias gcm='git commit -m'
alias grh='git reset --hard'
alias gcfd='git clean -fd'
alias gcb='git checkout -b'
alias gc='git checkout'
alias gpl='git pull'
alias gps='git push'

