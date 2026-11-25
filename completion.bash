# bash tab-completion for create_latex
_create_latex_profiles() {
  local conf="${CREATE_LATEX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/create_latex/config}"
  sed -n 's/^[[:space:]]*\[[[:space:]]*profile[[:space:]]\+\([A-Za-z0-9_.-]*\)[[:space:]]*\].*/\1/p' "$conf" 2>/dev/null
}

_create_latex() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local tdir="${CREATE_LATEX_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/create_latex}/templates"
  local first=${COMP_WORDS[1]:-}
  local templates
  templates=$(ls "$tdir" 2>/dev/null | grep -v '^_')

  case $first in
    --install-class|--add-template)
      (( COMP_CWORD >= 3 )) && COMPREPLY=($(compgen -f -- "$cur"))
      return ;;
    --remove-template)
      (( COMP_CWORD == 2 )) && COMPREPLY=($(compgen -W "$templates" -- "$cur"))
      return ;;
  esac

  if [[ $prev == -p || $prev == --profile ]]; then
    COMPREPLY=($(compgen -W "$(_create_latex_profiles)" -- "$cur"))
    return
  fi

  if [[ $cur == -* ]]; then
    COMPREPLY=($(compgen -W "--profile --local --list --profiles --install-class --add-template --remove-template --help --version" -- "$cur"))
    return
  fi

  # template name = 2nd positional argument (option values are skipped)
  local pos=0 i w
  for (( i = 1; i < COMP_CWORD; i++ )); do
    w=${COMP_WORDS[i]}
    if [[ $w == -p || $w == --profile ]]; then (( i++ )); continue; fi
    [[ $w == -* ]] || pos=$((pos + 1))
  done
  (( pos == 1 )) && COMPREPLY=($(compgen -W "$templates" -- "$cur"))
}
complete -F _create_latex create_latex
