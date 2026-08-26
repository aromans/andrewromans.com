#!/usr/bin/env bash
# Generate the compilable resume.tex from data/*.yaml + content/resume/_index.md.
#
# assets/resume.tex is a Hugo TEMPLATE and will not compile on its own. This
# script renders it and drops the result at build/resume.tex, which is the file
# to upload to Overleaf (alongside awesome-cv.cls and fonts/).
#
# Usage: ./build-resume.sh

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v hugo >/dev/null 2>&1; then
  echo "error: hugo is not installed." >&2
  echo "Install the extended build (the site needs it for SCSS):" >&2
  echo "  https://github.com/gohugoio/hugo/releases" >&2
  exit 1
fi

if ! hugo version | grep -q extended; then
  echo "warning: this hugo is not the 'extended' build; SCSS compilation may fail." >&2
fi

hugo --quiet --destination public --cleanDestinationDir

mkdir -p build
cp public/resume.tex build/resume.tex

# Fail loudly if template syntax leaked through, which would break the compile.
if grep -q '{{' build/resume.tex; then
  echo "error: build/resume.tex still contains Hugo template syntax." >&2
  exit 1
fi

echo "wrote build/resume.tex  ($(wc -l < build/resume.tex) lines)"
echo "Upload that file to Overleaf, then save the PDF to content/resume.pdf"
