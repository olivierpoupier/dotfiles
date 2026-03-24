# RVM settings
if [[ -s ~/.rvm/scripts/rvm ]] ; then
  RPS1="%{$fg[yellow]%}rvm:%{$reset_color%}%{$fg[red]%}\$(~/.rvm/bin/rvm-prompt)%{$reset_color%} $EPS1"
else
  if which rbenv &> /dev/null; then
    RPS1="%{$fg[yellow]%}rbenv:%{$reset_color%}%{$fg[red]%}\$(rbenv version | sed -e 's/ (set.*$//')%{$reset_color%} $EPS1"
  fi
fi
ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%} 🌿 ["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=" "

git_custom_status() {
  local cb=$(git_current_branch)
  if [ -n "$cb" ]; then
    local git_status="$(git_prompt_status)"
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      echo "$ZSH_THEME_GIT_PROMPT_PREFIX$cb$ZSH_THEME_GIT_PROMPT_SUFFIX$ZSH_THEME_GIT_PROMPT_DIRTY"
    else
      echo "$ZSH_THEME_GIT_PROMPT_PREFIX$cb$ZSH_THEME_GIT_PROMPT_SUFFIX$ZSH_THEME_GIT_PROMPT_CLEAN"
    fi
  fi
}
PROMPT='%{$fg[cyan]%}[%~% ]%{$reset_color%}$(git_custom_status)%B$%b '