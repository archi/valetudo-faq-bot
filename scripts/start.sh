#!/usr/bin/env bash

set -eu

base=$(realpath "$(dirname "$(realpath "$0")")/..")
program="$base/simple-tg-faq-bot/faqbot.py"
bot="$base/valetudobot"
token="$base/token.txt"

exec /usr/bin/env python "$program" -b "$bot" -t "$token"
