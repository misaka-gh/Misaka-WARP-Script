#!/bin/bash

last_updated_ver="v2.2.14"
repo_last_ver=$(curl -Ls "https://api.github.com/repos/ViRb3/wgcf/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
repo_ver_name=$(curl -Ls "https://api.github.com/repos/ViRb3/wgcf/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed "s/v//g")

if [[ $last_updated_ver == $repo_last_ver ]]; then
    echo "wgcf is up to date"
else
    wget -N https://github.com/ViRb3/wgcf/releases/download/$repo_last_ver/wgcf_"$repo_ver_name"_linux_amd64 -O ${GITHUB_WORKSPACE}/files/wgcf_latest_linux_amd64
    wget -N https://github.com/ViRb3/wgcf/releases/download/$repo_last_ver/wgcf_"$repo_ver_name"_linux_arm64 -O ${GITHUB_WORKSPACE}/files/wgcf_latest_linux_arm64
    wget -N https://github.com/ViRb3/wgcf/releases/download/$repo_last_ver/wgcf_"$repo_ver_name"_linux_s390x -O ${GITHUB_WORKSPACE}/files/wgcf_latest_linux_s390x
fi