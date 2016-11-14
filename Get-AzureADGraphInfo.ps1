<#
.NAME
	Get-AzureADGraphInfo.ps1
	
.DESCRIPTION
    Example of calling the Azure Graph API using Invoke-WebRequest.
    The data is returned as an HtmlWebResponseObject

.NOTES
    Author : Eric Kool-Brown
    Created: 2016-11-04
	
	Permissions required to run this script:
    - A Web Application with proper permissions must be set up in Azure Active Directory
#>

# AAD app client ID
$ClientID       = "<app id>"
# AAD app secret key
$ClientSecret   = Get-Content -Path "prod_secret.txt"
 
$loginURL       = "https://login.windows.net/"
$tenantdomain   = "uw.edu"

# Get an Oauth 2 access token based on client id and secret key
$body = @{grant_type="client_credentials";client_id=$ClientID;client_secret=$ClientSecret}

$oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

if ($oauth.access_token -ne $null) {
    # the header values contain the OAuth access token and the content type
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"; "Content-Type"="application/json"}

    # to find a specific group you can do an exact match filter, note the back-tick in front of the dollar sign
    $url = "https://graph.windows.net/$tenantdomain/groups?api-version=1.6&`$filter=displayName+eq+'u_kool_test1'"
    # to find groups that start with a certain prefix use the startswith expression:
    $url = "https://graph.windows.net/$tenantdomain/groups?api-version=1.6&`$filter=startswith(displayName,'u_kool_test')"

    Write-Output "Fetching data using Uri: $url"

    $groupInfo = Invoke-WebRequest -Headers $headerParams -Uri $url

    Write-Output "Returned object has type $($groupInfo.GetType().Name)"
    # trick to format JSON string from single line to indented, multi-line
    $prettyJson = $groupInfo.Content | ConvertFrom-Json | ConvertTo-Json
    Write-Output $prettyJson
    # Use ConvertFrom-Json to access the data as a PS object
    $groupObj = $groupInfo.Content | ConvertFrom-Json
    Write-Output "Converted JSON object has type $($groupObj.GetType())"

    # show the JSON root elements converted to NoteProperties:
    $groupObj | Get-Member -MemberType NoteProperty | select -Property Name,Definition | ft

    Write-Output "Number of groups found = $($groupObj.value.Count)"
    Write-Output "The values for the first group are:"
    Write-Output $groupObj.value[0]

} else {
    Write-Host "ERROR: No Access Token"
}
