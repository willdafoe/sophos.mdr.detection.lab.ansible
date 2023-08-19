#!/bin/bash
repo="${repo:-default ""}"
token="${token:-default ""}"
artifact_name="${artifact_name:-default ""}"
output_directory="$1"
scriptname=$0

function usage {
    echo " "
    echo " Checks if a GitHub Action artifact exists in the targeted repository "
    echo " "
    echo " usage: $scriptname --token string --repo string "
    echo " "
    echo "      --token string                     The Github Personal Access Token to use when making the API call. "
    echo "      --repo string                       The Github Repository in <OWNER>/<NAME> format"
    echo "      --artifact_name string          The name of the artifact file"
    echo " "
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

function makeApiCall(){
    local url="$1"
    local headers=("${@:2}")
    local options="${@:2}"
    local headers_args=()
    for header in "${headers[@]}"; do
        headers_args+=("-H" "$header")
    done
    local response=$(curl -s -L "${headers_args[@]}" $options "$url")
    echo "$response"
}

function getMostRecentArtifact(){
    base_url="https://api.github.com"
    artifact_url="$base_url/repos/$repo/actions/artifacts"
    github_headers=("Accept: application/vnd.github+json" "Authorization: Bearer $token" "X-GitHub-Api-Version: 2022-11-28")
    response=$(makeApiCall "${github_headers[@]}" "$artifact_url")

    if  [ -n "$response" ]; then
        most_recent_artifact=$( echo "$response" | jq --arg name "$artifact_name" '.artifacts | map(select(.name == "'$artifact_name'")) | sort_by(.created_at) | reverse')
        archive_download_url=$(echo "$most_recent_artifact" | jq -r 'first(.[] | .archive_download_url)')
    else
        echo "No artifacts were found."
        exit 0
    fi
    if [[ $output_directory ]]; then
        curl -L -H "Authorization: Bearer $token"  "$archive_download_url" -o "$output_directory/$artifact_name.zip"
        unzip "$artifact_name.zip"
        rm -rf "$output_directory/$artifact_name.zip"
    elif [[ -z $output_directory ]]; then
        curl -L -H "Authorization: Bearer $token"  "$archive_download_url" -o "$(pwd)/$artifact_name.zip"
        unzip "$artifact_name.zip"
        rm -rf "$artifact_name.zip"
    else
        :
    fi    
}

if [[ -z $token ]]; then
    usage
    die "Missing parameter --token"
elif [[ -z $repo ]]; then
    usage
    die "Missing parameter --repo"
elif [[ -z $artifact_name ]]; then
    usage
    die "Missing parameter --artifact_name"
fi

while [ $# -gt 0 ]; do
    if [[ $1 == "--help" ]]; then
        usage
        exit 0
    elif [[ $1 == "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

getMostRecentArtifact