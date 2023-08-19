#!/bin/bash
repo="$1"
token="$1"
artifact_name="$1"
#output_directory="$1"
scriptname=$0

function usage {
    echo " "
    echo " Checks if a GitHub Action artifact exists in the targeted repository "
    echo " "
    echo " usage: $scriptname --token string --repo string "
    echo " "
    echo "      --token string                      The Github Personal Access Token to use when making the API call. "
    echo "      --repo string                       The Github Repository in <OWNER>/<NAME> format"
    echo "      --artifact_name string              The name of the artifact file"
    echo " "
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

function getMostRecentArtifact(){
baseUri="https://api.github.com"
artifactUri="$baseUri/repos/$gh_repo/actions/artifacts"

response=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $gh_token" -H "X-GitHub-Api-Version: 2022-11-28" "$artifactUri")

    echo "$response"
    if  [ -n "$response" ]; then
        most_recent_artifact=$(echo "$response" | jq --arg name "$artifact_name" '.artifacts[] | map(select(.name == "'$artifact_name'")) | sort_by(.created_at) | reverse')
        archive_download_url=$(echo "$most_recent_artifact" | jq -r 'first(.[] | .archive_download_url)')
        echo "Most recent artifact_download_url is: $archive_download_url"
    else
        echo "No artifacts were found."
        exit 0
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

artifact=$(getMostRecentArtifact)
echo "$artifact"