function Encrypt-GitHubArtifact {
    <#
    .SYNOPSIS
    Takes an input GitHub Actions artifact run during a workflow and encrypts the file to be stored securely as a GitHub Actions Artifact.
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            ValueFromPipelineByPropertyName=$true,
            ValueFromPipeline=$true)]
        [Alias("File")]
        [String[]]$input_file,
        [Parameter()]
        [string]$repository,
        [Parameter()]
        [System.IO.FileInfo]$output_file,
        [Parameter()]
        [string]$artifact,
        [Parameter()]
        [string]$token

    )
    function GitHubApi($token,$repository){
        $repo = $repository
        $baseuri = "https://api.github.com"
        $artifacturi = "$baseuri/repos/$repo/actions/artifacts"
        $response = Invoke-RestMethod -Authentication Bearer -Uri $artifacturi -Token $token
        $data = $response.data
        return $data
    }
    $restresponse=GitHubApi
    Write-Host $restresponse
}