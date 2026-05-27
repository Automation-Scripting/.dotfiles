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