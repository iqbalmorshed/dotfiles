# Powerlevel10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zsh-autocomplete
# source $HOME/Tools/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# zsh-autosuggestion
source $HOME/Tools/zsh-autosuggestions/zsh-autosuggestions.zsh

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

# Load Git completion
autoload -Uz compinit && compinit
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

ZSH_THEME="powerlevel10k/powerlevel10k"

source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alh'
export PATH="/usr/local/opt/node@12/bin:$PATH"

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
export PATH="$PATH:/Users/iqbalmorshed/.dotnet/tools"