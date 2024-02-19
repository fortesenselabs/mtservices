#!/usr/bin/env bash

export GOPRIVATE=github.com/FortesenseLabs/wisefinance-mtservices
export GONOPROXY=localhost
export GITHUB_ACCESS_TOKEN=<your-token>

git config url."https://$GITHUB_ACCESS_TOKEN:x-oauth-basic@github.com/".insteadOf "https://github.com/"