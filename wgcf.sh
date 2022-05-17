#!/bin/bash

last_updated_ver="v2.2.14"
repo_last_ver=$(curl -Ls "https://api.github.com/repos/ViRb3/wgcf/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

wget -N https://github.com/ViRb3/wgcf/releases/download/$repo_last_ver/wgcf_2.2.14_linux_amd64 -O ${GITHUB_WORKSPACE}/files/wgcf-latest-amd64