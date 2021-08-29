#!/usr/bin/env bash

_pkgname="ncspot"
_usrname="hrkfdn"

mkdir tmp
url="https://github.com/${_usrname}/${_pkgname}"
_pkgver=$(git ls-remote --tags --sort="version:refname" https://github.com/${_usrname}/${_pkgname} | cut -d "/" -f 3 | grep "[0-9]\+\.[0-9]\+\.[0-9]\+" | tail -1 | sed -e "s/[^0-9.]//g" | tr -d '\n')
# Auto generate source files:
eval "$(grep -Pzo "(?s)source=.*?\)" PKGBUILD | sed -e "s/\([^_]\)pkgname/\1_pkgname/g" -e "s/pkgver/_pkgver/g" -e "/^[ \t]*#/d" | tr -d '\0')"
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }

IFS="::"
i=1
regex='(.*)::(.*)'
shasums=()
for s in "${source[@]}"; do
  [[ $s =~ $regex ]] || continue
  out=${BASH_REMATCH[1]}
  url=${BASH_REMATCH[2]}
  curl -sLo "tmp/$out" "$url"
  shasums[${#shasums[@]}]="$(shasum -a 256 "tmp/$out" | cut -d " " -f1)"
  ((i = i + 1))
done
echo "$_pkgver"
sha256sums=$(join_by "\n" "${shasums[@]}")
sed -e "s/sha256sums=()/sha256sums=(${sha256sums})/g" -e "s/VERSION/${_pkgver}/g" < PKGBUILD.template > PKGBUILD
makepkg --printsrcinfo > .SRCINFO
rm -rf tmp
git add .
git commit -m "$_pkgver"
commit="$(git rev-parse HEAD)"
git push -u
git checkout main
git cherry-pick "$commit"
git push -u
