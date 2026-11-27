#!/usr/bin/env bash
# =============================================================================
#  build.sh — compile this LaTeX project. Work files go to ./build; after every
#  successful build the PDF is copied next to main.tex (./main.pdf)
#
#    ./build.sh          compile (LaTeX + BibTeX/Biber + glossaries, as needed)
#    ./build.sh watch    recompile automatically every time you save
#    ./build.sh open     open the PDF
#    ./build.sh clean    empty ./build (./main.pdf is kept)
# =============================================================================
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

MAIN="main"            # main file, without .tex
OUT="build"            # output folder
ENGINE="pdflatex"      # pdflatex | xelatex | lualatex

PDF="$OUT/$MAIN.pdf"   # written by LaTeX
FINAL="$MAIN.pdf"      # the copy in the project folder
LATEX_OPTS=(-interaction=nonstopmode -halt-on-error -file-line-error -synctex=1)
case $ENGINE in
  pdflatex) LMK_ENGINE=-pdf ;;
  xelatex)  LMK_ENGINE=-xelatex ;;
  lualatex) LMK_ENGINE=-lualatex ;;
  *) echo "unknown ENGINE '$ENGINE'"; exit 1 ;;
esac

# \include{chapters/x} writes build/chapters/x.aux, so the folder tree is mirrored
prepare_out() {
  mkdir -p "$OUT"
  find . -mindepth 1 -type d \( -name "$OUT" -o -name '.*' \) -prune -o -type d -print |
    while IFS= read -r d; do mkdir -p "$OUT/${d#./}"; done
}

show_errors() {
  local log="$OUT/$MAIN.log" e b
  echo -e "\033[31mBuild failed.\033[0m"
  e=$( { grep -E -A4 '^(\./|/)?[^ ]+\.tex:[0-9]+: |^! ' "$log" 2>/dev/null || true; } | head -n 30)
  [[ -n $e ]] && printf 'First LaTeX errors (%s):\n%s\n' "$log" "$e"
  b=$(bib_problems)
  [[ -n $b ]] && printf '\033[33mBibliography:\033[0m\n  %s\n' "${b//$'\n'/$'\n'  }"
  exit 1
}

bib_problems() {      # bibliography errors that latexmk does not stop on
  local aux="$OUT/$MAIN.aux" bcf="$OUT/$MAIN.bcf" blg="$OUT/$MAIN.blg" f
  found() { [[ -f $1 ]] || kpsewhich "$1" >/dev/null 2>&1; }
  if [[ -f $aux ]]; then                                    # BibTeX
    for f in $(sed -n 's/^\\bibdata{\(.*\)}$/\1/p' "$aux" | tr ',' ' '); do
      found "${f%.bib}.bib" || echo "missing .bib file: ${f%.bib}.bib   (\\bibliography{$f})"
    done
    for f in $(sed -n 's/^\\bibstyle{\(.*\)}$/\1/p' "$aux"); do
      found "$f.bst" || { echo "missing style: $f.bst   (\\bibliographystyle{$f}) - not part of TeX Live."
                          echo "  install it once for all projects:  create_latex --install-class bibstyles <path>/$f.bst"; }
    done
  fi
  if [[ -f $bcf ]]; then                                    # biblatex + Biber
    for f in $(grep -o '<bcf:datasource[^>]*>[^<]*' "$bcf" | sed 's/.*>//'); do
      found "$f" || echo "missing .bib file: $f   (\\addbibresource{$f})"
    done
  fi
  [[ -f $blg ]] && grep -E "^I couldn't open|^I found no|^ERROR" "$blg" | sort -u | head -n 5
  return 0
}

publish() {            # copy the PDF to the project folder (atomic, so open viewers reload cleanly)
  cp "$PDF" "$FINAL.tmp" && mv -f "$FINAL.tmp" "$FINAL"
}

summary() {
  local log="$OUT/$MAIN.log" w b
  w=$(grep -cE 'LaTeX Warning: (Citation|Reference).*undefined' "$log" 2>/dev/null || true)
  b=$(bib_problems)
  echo -e "\033[32mOK\033[0m -> $FINAL ($(pdfinfo "$FINAL" 2>/dev/null | awk '/^Pages/{print $2" pages"}'))"
  if [[ -n $b ]]; then
    echo -e "\033[33mBibliography not built:\033[0m"
    printf '  %s\n' "${b//$'\n'/$'\n'  }"
  fi
  [[ ${w:-0} -gt 0 ]] && echo -e "\033[33m$w undefined citation/reference warnings (see $log)\033[0m" || true
}

build_latexmk() {      # rules for glossaries live in .latexmkrc
  local force=()
  # the last build had bibliography errors: rebuild everything, so a .bib/.bst
  # that has since been added or installed is picked up
  [[ -n $(bib_problems) ]] && force=(-g)
  latexmk "$LMK_ENGINE" "${LATEX_OPTS[@]}" "${force[@]}" -outdir="$OUT" -silent "$MAIN.tex" >/dev/null 2>&1 || show_errors
}

build_manual() {       # used only when latexmk is not installed
  local pass
  run() { "$ENGINE" "${LATEX_OPTS[@]}" -output-directory="$OUT" "$MAIN.tex" >/dev/null 2>&1 || show_errors; }
  run
  if [[ -f "$OUT/$MAIN.bcf" ]]; then
    biber --input-directory="$OUT" --output-directory="$OUT" "$MAIN" >/dev/null 2>&1 || true
  elif grep -q '\\bibdata' "$OUT/$MAIN.aux"; then
    bibtex "$OUT/$MAIN" >/dev/null 2>&1 || true
  fi
  if compgen -G "$OUT/$MAIN.glo" >/dev/null || compgen -G "$OUT/$MAIN.acn" >/dev/null; then
    makeglossaries -q -d "$OUT" "$MAIN" >/dev/null 2>&1 || true
  fi
  for pass in 1 2 3; do
    run
    grep -q 'Rerun to get' "$OUT/$MAIN.log" || break
  done
}

case "${1:-build}" in
  build)
    prepare_out
    if command -v latexmk >/dev/null; then build_latexmk; else build_manual; fi
    publish
    summary ;;
  watch)
    command -v latexmk >/dev/null || { echo "watch needs latexmk: sudo apt install latexmk"; exit 1; }
    prepare_out
    latexmk "$LMK_ENGINE" -interaction=nonstopmode -file-line-error -synctex=1 \
            -outdir="$OUT" -pvc -view=none \
            -e "\$success_cmd = q(cp $PDF $FINAL.tmp && mv -f $FINAL.tmp $FINAL);" "$MAIN.tex" ;;
  open)
    [[ -f $FINAL ]] || "$0" build
    xdg-open "$FINAL" >/dev/null 2>&1 & ;;
  clean)
    rm -rf "${OUT:?}"/* && echo "cleaned $OUT/" ;;
  *)
    sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//' ; exit 1 ;;
esac
