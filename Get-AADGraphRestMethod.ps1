<#
.NAME
	Get-AADGraphRestMethod.ps1
	
.DESCRIPTION
    Example of calling the Azure Graph API using Invoke-RestMethod
    This commandlet can return any of the following object types depending on
    its ability to parse the response body:
    - PSCustomObject - if the response is valid JSON; the Azure Graph returns JSON
    - XmlDocument - if the response is valid XML
    - HtmlWebResponseObject - if the response is an HTML form; non-form HTML is not parsed
    - String - presumably if none of the above

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

#Write-Output "Returned OAuth object has type $($oauth.GetType().Name)"
#Write-Output $oauth

if ($oauth.access_token -ne $null) {
    # the header values contain the OAuth access token and the content type
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"; "Content-Type"="application/xml"}

    # using the 'ge' comparison operator doesn't work quite like a wildcard, instead finding all values that
    # are lexically greater
    #$url = "https://graph.windows.net/$tenantdomain/groups?api-version=1.6&`$filter=displayName+ge+'u_kool_pstest'"
    # so instead use the startswith filter expression
    $url = "https://graph.windows.net/$tenantdomain/groups?api-version=1.6&`$filter=startswith(displayName,'u_kool_pstest')"

    Write-Output "Fetching data using Uri: $url"

    $groupInfo = Invoke-RestMethod -Method Get -Headers $headerParams -Uri $url

    Write-Output "Returned group info object has type $($groupInfo.GetType().Name) with JSON name/value pairs:"
    $groupInfo | Get-Member -MemberType NoteProperty | select -Property Name,Definition | ft
    Write-Output "Number of groups found = $($groupInfo.value.Count)"
    Write-Output "The values for the first group are:"
    Write-Output $groupInfo.value[0]
    #Write-Output "Converting to JSON yields:"
    #$groupInfo | ConvertTo-Json
} else {
    Write-Host "ERROR: No Access Token"
}
