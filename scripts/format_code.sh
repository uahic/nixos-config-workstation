#!/usr/bin/env bash
alejandra "$@" || true
git add "$@"
