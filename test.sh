#!/bin/bash
base_uri="https://api.github.com"
repo="willdafoe/sophos.mdr.detection.lab.ansible"
artifacts_uri="$base_uri/repos/$repo/actions/artifacts"
token="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"

api_response=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $token" -H "X-GitHub-Api-Version: 2022-11-28" "$artifacts_uri")

sorted_artifacts=$(echo "$api_response" | jq --arg name "$1" '.artifacts | map(select(.name == $name)) | sort_by(.created_at) | reverse')

most_recent=$(echo "$sorted_artifacts" | jq -r 'first(.[])')

run_id=$(echo "$most_recent" | jq -r '.workflow_run.id')

echo "$run_id"

