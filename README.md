# create_latex

Start a LaTeX project from a template with one command, and compile it with one
more. Bash, Linux, TeX Live. No sudo.

```bash
create_latex <project_name> report
cd <project_name> && ./build.sh          # -> build/main.pdf
```

Every project gets the same layout:

```
<project_name>/
├── main.tex          the template's main file, your name/affiliation filled in
├── references.bib    (only if the template has no .bib of its own)
├── figures/          \graphicspath points here
├── build/            aux files and build/main.pdf, nothing else in the root
├── build.sh          ./build.sh | ./build.sh watch | ./build.sh open | ./build.sh clean
├── .latexmkrc        build/ as output dir, glossaries, \include{} subfolders
├── .gitignore
└── .vscode/settings.json   LaTeX Workshop writes to build/ too
```

`build.sh` uses `latexmk` (BibTeX or Biber, glossaries, reruns) and falls back to
plain `pdflatex` passes when `latexmk` is missing. On failure it prints the first
LaTeX errors instead of the whole log.

**This repository ships only three generic example templates** (`article`,
`report`, `beamer`) that need nothing but TeX Live. Journal, conference and
university templates are not redistributed here: you download them from their
publishers and install them in one command, see
[Installing new templates](#installing-new-templates).

---

## Install

```bash
# 1. LaTeX (Debian/Ubuntu)
sudo apt install texlive-latex-extra texlive-publishers texlive-science \
                 texlive-bibtex-extra biber latexmk texlive-font-utils unzip

# 2. this tool
git clone https://github.com/n0t1cs/create_latex.git
cd create_latex
./install.sh            # asks for your name, ORCID and a first affiliation profile
source ~/.bashrc        # or open a new terminal
```

Re-run `./install.sh` after `git pull` to update. Your config and the templates
you installed are kept.

| what              | where |
|-------------------|-------|
| command           | `~/.local/bin/create_latex` |
| templates         | `~/.local/share/create_latex/templates/<name>/` |
| your details      | `~/.config/create_latex/config` |
| installed classes | `~/texmf/tex/latex/<name>/`, `~/texmf/bibtex/bst/<name>/`, `~/texmf/fonts/*/<name>/` |

## Usage

```bash
create_latex <project_name> <template>               # new project in the current folder
create_latex -p <profile> <project_name> <template>  # with a specific author profile
create_latex --local <project_name> <template>       # + copy of shared class files (submission / Overleaf)
create_latex --list                                  # templates, and what is missing
create_latex --profiles                              # your author profiles
create_latex --add-template <name> <folder|zip> [main.tex]
create_latex --install-class <name> <folder|zip>
create_latex --remove-template <name>
```

Tab completion works for options, template names and profile names.

## Example templates

| name      | document |
|-----------|----------|
| `article` | article, A4, natbib numeric, cleveref, siunitx |
| `report`  | report: title page (with course/supervisor when your profile has them), abstract, TOC/LOF/LOT, chapters, appendix |
| `beamer`  | beamer 16:9, Madrid theme, outline per section, references frame |

They are starting points and examples of how a template is written; edit them
freely in `~/.local/share/create_latex/templates/`.

## Author profiles

`~/.config/create_latex/config` holds your details. One person often writes
under several affiliations (a research institute for papers, a university as a
student for the thesis and coursework), so the config has one **profile per
affiliation**. `[defaults]` says who you are; each profile says where you write
from. The annotated file is [`config.example`](config.example).

```ini
[defaults]
author          = John Doe
orcid           = XXXX-XXXX-XXXX-XXXX
default_profile = institute

# Research job: papers, project reports, conference talks
[profile institute]
affiliation       = Research Institute -- Full Name of the Institute, City, Country
affiliation_short = Research Institute
email             = john.doe@institute.org
role              = Researcher

# Student: thesis, coursework, defence slides
[profile university]
affiliation       = School of Engineering, University, City, Country
affiliation_short = University
email             = 1234567@university.edu
role              = Student
student_number    = 1234567
course            = Doctoral Programme in Engineering
supervisor        = Jane Roe, Richard Roe
```

```bash
create_latex paper_x article                    # institute profile (default_profile)
create_latex -p university phd_proposal report  # university (student) profile
create_latex --profiles                         # list them
```

Which profile is used: `-p` if given, else the template's preferred profile
(`PROFILE=` in its `template.conf`), else `default_profile`.

Every key is a placeholder in templates: `student_number` → `@@STUDENT_NUMBER@@`,
`course` → `@@COURSE@@`, and so on. Comments are whole lines starting with `#`.
A placeholder the profile does not define is left empty (create_latex tells you
which ones).

---

## Installing new templates

A template is a folder with a `main.tex` (plus anything else it needs: class
files, chapters, logos, a `.bib`). Installed templates live in
`~/.local/share/create_latex/templates/<name>/`, and `create_latex --list`
shows them.

### 1. Download the template

From **Overleaf**: open the template's page → **Open as Template** →
**Menu → Download → Source**. You get a `.zip`.
From a **publisher or university**: download their LaTeX package (usually a `.zip`).

Where to find common ones:

| template | where |
|----------|-------|
| MDPI journals | [mdpi.com/authors/latex](https://www.mdpi.com/authors/latex) · [Overleaf](https://www.overleaf.com/latex/templates/mdpi-article-template/fcpwsspfzsph) |
| IEEE Access | [ieeeaccess.ieee.org → Preparing your article](https://ieeeaccess.ieee.org/authors/preparing-your-article/) |
| IEEE conference | [Overleaf: IEEE Conference Template](https://www.overleaf.com/latex/templates/ieee-conference-template/grfzhhncsfqn) · [ieee.org conference templates](https://www.ieee.org/conferences/publishing/templates.html) |
| IEEE journals (IEEEtran) | [Overleaf: IEEE Official Templates](https://www.overleaf.com/gallery/tagged/ieee-official) (the class ships with TeX Live) |
| ISEP MEEC MSc thesis | [Overleaf](https://www.overleaf.com/latex/templates/isep-meec-msc-thesis-slash-dissertation-latex-template/zdyypsqypqnm) |
| ISEP DEE BSc report | [Overleaf](https://www.overleaf.com/latex/templates/isep-dee-bsc-latex-template/kqkmqnjbbpvj) |
| ISEP DEE beamer | [Overleaf](https://www.overleaf.com/latex/templates/isep-dee-beamer-presentation-template/phnvnnqhjzcn) |

### 2. Install it under a short name

```bash
create_latex --add-template mdpi            ~/Downloads/MDPI_template_ACS.zip
create_latex --add-template ieee_access     ~/Downloads/ACCESS_latex_template_20240429.zip
create_latex --add-template ieee_conference ~/Downloads/IEEE_Conference_Template.zip
```

The source can be a `.zip` or an unzipped folder. `--add-template`:

- unwraps a download that is just one folder inside another,
- finds the main file (the only top-level `.tex` with `\documentclass`) and
  renames it to `main.tex`. If there are several, name it:
  `create_latex --add-template thesis ~/Downloads/thesis_template main_en.tex`
- drops aux/log files, the compiled sample PDF, and class files identical to
  the ones TeX Live already has,
- writes a `template.conf` you can edit (step 4).

Then use it like any other template:

```bash
create_latex my_paper mdpi
cd my_paper && ./build.sh
```

### 3. Mark where your details go (optional)

Your details themselves are already in `~/.config/create_latex/config`; nothing
to change there. But a downloaded template has a sample author typed into its
`main.tex` (e.g. `First A. Author`), and create_latex cannot guess that this is
where your name belongs. So, once per template, open
`~/.local/share/create_latex/templates/<name>/main.tex` and replace the sample
data with placeholders. From then on every new project from that template gets
your details from the config (from the profile chosen with `-p`):

```latex
\author{@@AUTHOR@@}                                  % was: First A. Author
\address{@@AFFILIATION@@ (e-mail: @@EMAIL@@)}
\newcommand{\orcidauthorA}{@@ORCID@@}
\title{@@TITLE@@}                                    % the project name
```

| placeholder | value |
|-------------|-------|
| `@@AUTHOR@@ @@ORCID@@ @@AFFILIATION@@ @@AFFILIATION_SHORT@@ @@EMAIL@@` | your profile |
| `@@ANY_KEY@@` | any other key in your profile (`student_number`, `course`, ...) |
| `@@TITLE@@` | project name with `_`/`-` as spaces |
| `@@AUTHOR_UPPER@@`, `@@AUTHOR_SURNAME@@` | derived from `author` |
| `@@PROFILE@@`, `@@YEAR@@` | profile used, current year |

### 4. Describe it (optional)

`~/.local/share/create_latex/templates/<name>/template.conf`:

```bash
DESCRIPTION="IEEE Access article"        # shown by --list
REQUIRES="IEEEtran.cls"                  # files LaTeX must find; --list flags missing ones
HINT="sudo apt install texlive-publishers"   # shown when something is missing
SOURCE="https://ieeeaccess.ieee.org/authors/preparing-your-article/"
PROFILE="university"                     # preferred author profile for this template
BUNDLE=""                                # see step 5
```

### 5. Share class files between projects (optional, advanced)

`--add-template` keeps a copy of the class files in every project, which is the
simplest and what publishers expect at submission. For a journal you write for
often, you can instead install its class once into `~/texmf` and drop the copy
from the template:

```bash
create_latex --install-class mdpi ~/Downloads/MDPI_template_ACS     # class, .bst, logos -> ~/texmf
create_latex --add-template  mdpi ~/Downloads/MDPI_template_ACS
rm -r ~/.local/share/create_latex/templates/mdpi/Definitions         # use the shared copy
echo 'BUNDLE="mdpi"' >> ~/.local/share/create_latex/templates/mdpi/template.conf
```

`--install-class` sorts a bundle into the right `~/texmf` folders (`.cls/.sty`/logos
→ `tex/latex/<name>`, `.bst` → `bibtex/bst/<name>`, `.map/.tfm/.pfb` →
`fonts/...`), skips the sample document and files TeX Live already has, and
pre-converts EPS logos to PDF. With `BUNDLE` set,
`create_latex --local <project> mdpi` copies the class files back into a project
when you need to submit it or upload it to Overleaf.

### Update or remove a template

Edit its files in place, or remove it and add the new version:

```bash
create_latex --remove-template mdpi
create_latex --add-template mdpi ~/Downloads/MDPI_template_ACS_new.zip
```

`./install.sh` only refreshes the three example templates; the ones you added
are never touched.

---

## Uninstall

```bash
rm -rf ~/.local/bin/create_latex ~/.local/share/create_latex ~/.config/create_latex \
       ~/.local/share/bash-completion/completions/create_latex
# then delete the two "create_latex" lines at the end of ~/.bashrc
# installed classes: rm -rf ~/texmf/*/*/<name> ~/texmf/fonts/*/*/<name>
```

## License

MIT for the code in this repository (see `LICENSE`). Templates you download keep
their own licenses.
