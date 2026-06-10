#!/usr/bin/env bash

# clone [ORG]
#
# Clona automaticamente todos os repositórios
# de uma organização GitHub.
#
# Uso:
#
#   clone OpenAI
#
# ou:
#
#   mkdir OpenAI
#   cd OpenAI
#   clone
#
# Se nenhum argumento for passado,
# o nome da pasta atual será usado
# como nome da organização.

release_results() {
    if [[ $# -ne 1 ]]; then
        echo "Uso: release_results <diretorio>"
        return 1
    fi

    local source_dir="$1"

    if [[ ! -d "$source_dir" ]]; then
        echo "Erro: diretório não encontrado: $source_dir"
        return 1
    fi

    local system
    local analysis

    system=$(basename "$(dirname "$source_dir")")
    analysis=$(basename "$source_dir")

    local prefix="${system}_${analysis}"

    local latest
    latest=$(
        gh release list --limit 200 \
        | awk '{print $1}' \
        | grep "^${prefix}-v0\." \
        | sed 's/.*-v0\.//' \
        | sort -n \
        | tail -1
    )

    local next=1

    if [[ -n "$latest" ]]; then
        next=$((latest + 1))
    fi

    local release_name="${prefix}-v0.${next}"

    echo "Release: $release_name"

    local tmp_dir
    tmp_dir=$(mktemp -d "/tmp/${release_name}.XXXXXX") || return 1

    trap 'rm -rf "$tmp_dir"' RETURN

    local tmp_zip="$tmp_dir/${release_name}.zip"

    local includes=()

    for subdir in logs plots results; do
        if [[ -d "$source_dir/$subdir" ]]; then
            includes+=("$subdir")
        fi
    done

    if [[ ${#includes[@]} -eq 0 ]]; then
        echo "Erro: nenhuma subpasta logs/, plots/ ou results/ encontrada."
        return 1
    fi

    echo "Incluindo: ${includes[*]}"

    (
        cd "$source_dir" || exit 1
        zip -qr "$tmp_zip" "${includes[@]}"
    ) || return 1

    gh release create "$release_name" \
        "$tmp_zip" \
        --title "$release_name" \
        --generate-notes
}

tag() {
  if [[ -z "${1:-}" ]]; then
    echo "Uso: tag <tag>"
    return 1
  fi
  git tag -f "$1" && git push -f origin "$1"
}


clone() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI nao encontrado."
    return 1
  fi

  local org

  if [[ -n "$1" ]]; then
    org="$1"
  else
    org="$(basename "$PWD")"
  fi

  echo "[info] Org detectada: $org"
  echo "[info] Destino: $PWD"

  gh repo list "$org" \
    --limit 1000 \
    --json name,sshUrl \
    -q '.[] | [.name, .sshUrl] | @tsv' |
  while IFS=$'\t' read -r name ssh; do
    if [[ -d "${name}/.git" ]]; then
      echo "[skip] ${name} ja existe"
    else
      echo "[clone] ${ssh}"
      git clone "${ssh}"
    fi
  done

  echo "[ok] Concluido."
}