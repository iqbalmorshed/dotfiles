#n zsh-autosuggestion
source $HOME/Tools/zsh-autosuggestions/zsh-autosuggestions.zsh

#Android Studo paths
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools

#Load Git completion
autoload -Uz compinit && compinit
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

# load ruby path
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

#powerlevel10k
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PATH="/usr/local/opt/node@12/bin:$PATH"

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
nvm use 18.19.0

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alh'
alias gs='git status'
alias ga='git add .'
alias gcm='git commit -m'
alias grh='git reset --hard'
alias gc='git clean -fd'
alias gcb='git checkout -b'
alias gc='git checkout'
alias gcfd='git clean -fd'
