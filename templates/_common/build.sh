#!/usr/bin/env bash
# =============================================================================
#  build.sh — compile this LaTeX project. Everything is written to ./build
#
#    ./build.sh          compile (LaTeX + BibTeX/Biber + glossaries, as needed)
#    ./build.sh watch    recompile automatically every time you save
#    ./build.sh open     open the PDF
#    ./build.sh clean    empty ./build
# =============================================================================
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

MAIN="main"            # main file, without .tex
OUT="build"            # output folder
ENGINE="pdflatex"      # pdflatex | xelatex | lualatex

PDF="$OUT/$MAIN.pdf"
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
  local log="$OUT/$MAIN.log"
  echo -e "\033[31mBuild failed.\033[0m First errors from $log:"
  [[ -f $log ]] && grep -E -A4 '^(\./|/)?[^ ]+\.tex:[0-9]+: |^! ' "$log" | head -n 30
  [[ -f "$OUT/$MAIN.blg" ]] && grep -E '^(I |Warning--|---|ERROR)' "$OUT/$MAIN.blg" | head -n 10 || true
  exit 1
}

summary() {
  local log="$OUT/$MAIN.log" w
  w=$(grep -cE 'LaTeX Warning: (Citation|Reference).*undefined' "$log" 2>/dev/null || true)
  echo -e "\033[32mOK\033[0m -> $PDF ($(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages/{print $2" pages"}'))"
  [[ ${w:-0} -gt 0 ]] && echo -e "\033[33m$w undefined citation/reference warnings (see $log)\033[0m" || true
}

build_latexmk() {      # rules for glossaries live in .latexmkrc
  latexmk "$LMK_ENGINE" "${LATEX_OPTS[@]}" -outdir="$OUT" -silent "$MAIN.tex" >/dev/null 2>&1 || show_errors
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
    summary ;;
  watch)
    command -v latexmk >/dev/null || { echo "watch needs latexmk: sudo apt install latexmk"; exit 1; }
    prepare_out
    latexmk "$LMK_ENGINE" -interaction=nonstopmode -file-line-error -synctex=1 \
            -outdir="$OUT" -pvc -view=none "$MAIN.tex" ;;
  open)
    [[ -f $PDF ]] || "$0" build
    xdg-open "$PDF" >/dev/null 2>&1 & ;;
  clean)
    rm -rf "${OUT:?}"/* && echo "cleaned $OUT/" ;;
  *)
    sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//' ; exit 1 ;;
esac
