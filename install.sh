#!/usr/bin/env bash
# =============================================================================
#  install.sh — installs (or updates) the create_latex command for this user
#
#    ./install.sh        (or: bash install.sh)
#
#  Nothing is written outside your home folder; no sudo needed. Running it again
#  updates the command and the built-in templates, and keeps your config and the
#  templates you added yourself.
# =============================================================================
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

BIN_DIR="$HOME/.local/bin"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/create_latex"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/create_latex"
COMPL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "1/5  Checking LaTeX tools"
missing=()
for t in pdflatex bibtex biber kpsewhich latexmk makeglossaries epstopdf unzip; do
  if command -v "$t" >/dev/null; then printf '  ok       %s\n' "$t"
  else printf '  MISSING  %s\n' "$t"; missing+=("$t"); fi
done
if (( ${#missing[@]} )); then
  echo "  -> suggested (Debian/Ubuntu):"
  echo "     sudo apt install texlive-latex-extra texlive-publishers texlive-science \\"
  echo "                      texlive-bibtex-extra biber latexmk texlive-font-utils unzip"
  command -v kpsewhich >/dev/null || { echo "  LaTeX itself is missing, aborting."; exit 1; }
fi
echo "  TEXMFHOME = $(kpsewhich -var-value TEXMFHOME)"

step "2/5  Command -> $BIN_DIR/create_latex"
mkdir -p "$BIN_DIR"
install -m 755 "$HERE/create_latex" "$BIN_DIR/create_latex"

step "3/5  Built-in templates -> $DATA_DIR/templates"
mkdir -p "$DATA_DIR/templates"
for d in "$HERE"/templates/*/; do           # built-in templates are refreshed,
  name=$(basename "$d")                      # the ones you added are kept
  rm -rf "${DATA_DIR:?}/templates/$name"
  cp -r "$d" "$DATA_DIR/templates/$name"
  echo "  $name"
done
chmod +x "$DATA_DIR/templates/_common/build.sh"

step "4/5  Your details -> $CONF_DIR/config"
mkdir -p "$CONF_DIR"
CONF="$CONF_DIR/config"

write_config() {   # author orcid extra_default_line profile affiliation email
  cat >"$CONF" <<EOF
# ~/.config/create_latex/config  (see config.example in the repository)
# [defaults] is shared by every profile; each [profile <name>] overrides it.
# Use a profile with:  create_latex -p <name> <project> <template>
# Every key is a template placeholder: student_number -> @@STUDENT_NUMBER@@

[defaults]
author          = $1
orcid           = $2
default_profile = $4
$3

[profile $4]
affiliation       = $5
affiliation_short = ${5%%,*}
email             = $6

# Another affiliation, e.g. as a student (see config.example for all keys):
# [profile university]
# affiliation       = School of Engineering, University, City, Country
# affiliation_short = University
# email             = 1234567@university.edu
# role              = Student
# student_number    = 1234567
# course            = Doctoral Programme in Engineering
# supervisor        = Jane Roe, Richard Roe
EOF
}

if [[ -f $CONF ]] && grep -q '^[[:space:]]*AUTHOR=' "$CONF" && ! grep -q '^[[:space:]]*\[' "$CONF"; then
  # old one-person format (AUTHOR="...") -> profiles format
  cp "$CONF" "$CONF.bak"
  # shellcheck disable=SC1090
  ( AUTHOR="" ORCID="" MDPI_JOURNAL="" AFFILIATION="" EMAIL=""; source "$CONF.bak"
    write_config "$AUTHOR" "${ORCID:-XXXX-XXXX-XXXX-XXXX}" "${MDPI_JOURNAL:+mdpi_journal    = $MDPI_JOURNAL}" main \
                 "$AFFILIATION" "$EMAIL" )
  echo "  converted your config to the profiles format (old one saved as config.bak)"
elif [[ -f $CONF ]]; then
  echo "  kept existing config"
elif [[ -t 0 ]]; then                         # ask only when run from a terminal
  name=$(git config --global user.name 2>/dev/null || true); name=${name:-John Doe}
  email=$(git config --global user.email 2>/dev/null || true); email=${email:-john.doe@institute.org}
  orcid="XXXX-XXXX-XXXX-XXXX"; prof="institute"; affil="Research Institute, City, Country"
  read -r -p "  Your name                   [$name]: " a && name=${a:-$name}
  read -r -p "  ORCID                       [$orcid]: " a && orcid=${a:-$orcid}
  echo "  Profiles are one per affiliation (add more later in the config file)."
  read -r -p "  First affiliation (short id) [$prof]: " a && prof=${a:-$prof}
  read -r -p "  Affiliation for '$prof'     [$affil]: " a && affil=${a:-$affil}
  read -r -p "  E-mail for '$prof'          [$email]: " a && email=${a:-$email}
  write_config "$name" "$orcid" "" "${prof,,}" "$affil" "$email"
  echo "  created; add more profiles any time: nano $CONF"
else
  cp "$HERE/config.example" "$CONF"
  echo "  created from config.example (edit: nano $CONF)"
fi

step "5/5  Tab completion and PATH"
mkdir -p "$COMPL_DIR"
cp "$HERE/completion.bash" "$COMPL_DIR/create_latex"
if ! grep -q 'create_latex' "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ''
    echo '# create_latex: command + tab completion'
    echo 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
    echo '[ -f "$HOME/.local/share/bash-completion/completions/create_latex" ] && . "$HOME/.local/share/bash-completion/completions/create_latex"'
  } >>"$HOME/.bashrc"
  echo "  added PATH + completion lines to ~/.bashrc"
else
  echo "  ~/.bashrc already configured"
fi

step "Done"
"$BIN_DIR/create_latex" --list
cat <<EOF

Only generic example templates are bundled (article, report, beamer).
Add journal/university templates with --add-template: see "Installing new
templates" in README.md.

Open a NEW terminal (or run:  source ~/.bashrc), then try:
  create_latex test_paper article && cd test_paper && ./build.sh
EOF
