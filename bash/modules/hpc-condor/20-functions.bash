#!/usr/bin/env bash

_condor_has() {
  command -v "$1" >/dev/null 2>&1
}

_condor_require() {
  if ! _condor_has "$1"; then
    echo "Comando nao encontrado: $1"
    echo "Este modulo requer cliente HTCondor instalado no HPC."
    return 1
  fi
}

csub() {
  _condor_require condor_submit || return 1

  local submit_file
  if [[ -n "${1:-}" && -f "$1" ]]; then
    submit_file="$1"
    shift
  else
    local matches=(*.sub)
    if [[ ${#matches[@]} -eq 1 && -f "${matches[0]}" ]]; then
      submit_file="${matches[0]}"
    elif [[ ${#matches[@]} -gt 1 ]]; then
      echo "Mais de um arquivo .sub encontrado. Informe explicitamente: csub arquivo.sub"
      printf ' - %s\n' "${matches[@]}"
      return 2
    else
      echo "Nenhum arquivo .sub encontrado no diretorio atual."
      return 2
    fi
  fi

  condor_submit "$submit_file" "$@"
}

cq() {
  _condor_require condor_q || return 1
  condor_q "${1:-$USER}" -nobatch
}

cqi() {
  _condor_require condor_q || return 1
  if [[ -z "${1:-}" ]]; then
    echo "Uso: cqi <cluster[.proc]>"
    return 1
  fi
  condor_q "$1" -long
}

chist() {
  _condor_require condor_history || return 1
  local owner="${1:-$USER}"
  local limit="${2:-20}"
  condor_history "$owner" -limit "$limit"
}

crm() {
  _condor_require condor_rm || return 1
  if [[ $# -eq 0 ]]; then
    echo "Uso: crm <cluster[.proc]|constraint> [...]"
    return 1
  fi
  condor_rm "$@"
}

chold() {
  _condor_require condor_hold || return 1
  if [[ $# -eq 0 ]]; then
    echo "Uso: chold <cluster[.proc]|constraint> [...]"
    return 1
  fi
  condor_hold "$@"
}

chrel() {
  _condor_require condor_release || return 1
  if [[ $# -eq 0 ]]; then
    echo "Uso: chrel <cluster[.proc]|constraint> [...]"
    return 1
  fi
  condor_release "$@"
}

cwatch() {
  _condor_require condor_q || return 1
  local owner="${1:-$USER}"
  local interval="${2:-5}"

  if _condor_has watch; then
    watch -n "$interval" "condor_q '$owner' -nobatch"
    return $?
  fi

  while true; do
    clear
    date
    echo ""
    condor_q "$owner" -nobatch
    sleep "$interval"
  done
}

cjobpaths() {
  _condor_require condor_q || return 1
  if [[ -z "${1:-}" ]]; then
    echo "Uso: cjobpaths <cluster[.proc]>"
    return 1
  fi

  condor_q "$1" -long | awk -F ' = ' '
    /^Iwd = / {print "Iwd:     " $2}
    /^Cmd = / {print "Cmd:     " $2}
    /^Args = / {print "Args:    " $2}
    /^Out = / {print "Out:     " $2}
    /^Err = / {print "Err:     " $2}
    /^UserLog = / {print "UserLog: " $2}
  '
}

crmheld() {
  _condor_require condor_rm || return 1
  _condor_require condor_q || return 1

  local nheld

  nheld=$(condor_q -constraint "Owner == \"$USER\" && JobStatus == 5" -autoformat ClusterId | wc -l)

  if [[ "$nheld" -eq 0 ]]; then
    echo "Nenhum job HELD encontrado para $USER."
    return 0
  fi

  echo "Encontrados $nheld jobs HELD para $USER."
  read -rp "Deseja removê-los? [y/N] " ans

  case "$ans" in
    y|Y|yes|YES)
      condor_rm -constraint "Owner == \"$USER\" && JobStatus == 5"
      ;;
    *)
      echo "Operação cancelada."
      ;;
  esac
}

cheld() {
  _condor_require condor_q || return 1

  if [[ -z "${1:-}" ]]; then
    echo "Uso: cheld <cluster[.proc]>"
    return 1
  fi

  condor_q "$1" -af \
    ClusterId \
    ProcId \
    JobStatus \
    HoldReason \
    HoldReasonCode \
    HoldReasonSubCode
}

cmemory() {
  _condor_require condor_q || return 1

  if [[ $# -eq 0 ]]; then
    echo "Uso: cmemory <cluster[.proc]> [cluster[.proc] ...]"
    return 1
  fi

  local job
  for job in "$@"; do
    echo "== Job $job =="
    condor_q "$job" -run -af \
      ClusterId \
      ProcId \
      MemoryUsage \
      ImageSize \
      RequestMemory \
      Machine
    echo ""
  done
}