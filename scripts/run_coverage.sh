#!/bin/bash
# Script para executar testes com cobertura e gerar relatório
# Uso: bash scripts/run_coverage.sh

set -e

echo "=== Executando testes com cobertura ==="
flutter test --coverage

echo ""
echo "=== Resumo da cobertura ==="
if command -v lcov &> /dev/null; then
  lcov --summary coverage/lcov.info
  echo ""
  echo "=== Gerando relatório HTML ==="
  genhtml coverage/lcov.info -o coverage/html
  echo "Relatório gerado em: coverage/html/index.html"
else
  echo "lcov não encontrado. Resumo do arquivo lcov.info:"
  echo ""
  
  # Parse manual do lcov.info para extrair métricas
  total_lines=0
  covered_lines=0
  
  while IFS= read -r line; do
    if [[ "$line" == LF:* ]]; then
      total_lines=$((total_lines + 1))
      count="${line#*:*:}"
      if [[ "$count" -gt 0 ]]; then
        covered_lines=$((covered_lines + 1))
      fi
    fi
  done < coverage/lcov.info
  
  if [[ $total_lines -gt 0 ]]; then
    percent=$((covered_lines * 100 / total_lines))
    echo "Linhas totais instrumentadas: $total_lines"
    echo "Linhas cobertas: $covered_lines"
    echo "Cobertura: ${percent}%"
  else
    echo "Nenhuma métrica encontrada no lcov.info"
  fi
fi

echo ""
echo "=== Arquivos no relatório ==="
grep "^SF:" coverage/lcov.info | sed 's/SF://' | sort
