#!/bin/bash
root=$(git rev-parse --show-toplevel)
git status --porcelain | while IFS= read -r line; do
  s="${line:0:2}"
  f="${line:3}"
  f="${f//\"/}"
  abs="${root}/${f}"
  case "$s" in
    [MADRC]" ") printf '\033[32m%s\033[0m\n' "$abs" ;;
    " "[MD])    printf '\033[31m%s\033[0m\n' "$abs" ;;
    "??")       printf '\033[35m%s\033[0m\n' "$abs" ;;
    *)          printf '\033[33m%s\033[0m\n' "$abs" ;;
  esac
done
