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
    if [[ $# -ne 2 ]]; then
        echo "Uso: release_results <release> <diretorio>"
        return 1
    fi

    local release_name="$1"
    local source_dir="$2"

    if [[ ! -d "$source_dir" ]]; then
        echo "Erro: diretório não encontrado: $source_dir"
        return 1
    fi

    local tmp_zip
    tmp_zip=$(mktemp "/tmp/${release_name}.XXXXXX.zip") || return 1

    trap 'rm -f "$tmp_zip"' RETURN

    local includes=()

    for subdir in logs plots results; do
        if [[ -d "$source_dir/$subdir" ]]; then
            includes+=("$subdir")
        fi
    done

    if [[ ${#includes[@]} -eq 0 ]]; then
        echo "Erro: nenhuma subpasta logs/, plots/ ou results/ encontrada em $source_dir"
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