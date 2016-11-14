<#
    .NAME
            New-UwGsGroup.ps1

    .DESCRIPTION
            Creates a UW Groups Service group using the GWS API.

    .SYNTAX
            New-UwGsGroup -groupID <Group-Name> -description <description> -certSubject <GWS-auth-cert-subject> -admin <group-admin>

    .PARAMETER groupID
            The name of the new group

    .PARAMETER description
            A textual description of the group

    .PARAMETER certSubject
            The DNS subject name of a certificate that has admin rights on the group stem. The certificate with private key
            must be in your local machine cert store with the key accessible by the account running this script.

    .PARAMETER admin
            A user or group that will be added as an administrator of the new group. The cert subject is also
            added as a group admin so that PS can be used to update the group or add members.

    .NOTES
            Author  : Eric Kool-Brown - kool@uw.edu
            Created : 11/04/2016

            The code to update a group is similar except that you need to first make a GET call on the group,
            make whatever changes you wish to the XHTML, then PUT the result.

    .LINK
            https://wiki.cac.washington.edu/display/infra/Groups+Web+Service+REST+API  
#>
Param ([string]$groupID,
       [string]$description,
       [string]$certSubject,
       [string]$admin)

$serviceEndPoint = "https://iam-ws.u.washington.edu:7443/group_sws/v2/"
$uri = $serviceEndPoint + "group/" + $groupID

# attempt to create the group
Write-Host "About to create group $groupID"
Write-Host "Using URL: $uri"

# Create a resource representation
$xhtml = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"> 
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
  </head>
  <body>
    <div class="group">
      <span class="description">$description</span>
      <ul class="names">
        <li class="name">$groupID</li>
      </ul>
      <ul class="admins">
        <li class="admin">$admin</li>
        <li class="admin">$certSubject</li>
      </ul> 
    </div>
  </body>
</html>
"@

#Write-Host "Sending this XML as the PUT body:"
#Write-Host $xhtml

try {
    $response = Invoke-WebRequest -Method PUT -uri $uri -body $xhtml -certificate $cert -contentType "text/plain;charset=utf-8"
    Write-Host "Result of group creation: $($response.StatusCode)"
}
catch {
    # if the certificate is not authorized on the stem/group, a 401 Unauthorized error will be returned in the WebException
    # if the group already exists a 412 Precondition failed error will be returned in the WebException
    Write-Error "Group creation call failed with error: $($_.Exception)"
    return
}

# on success it returns a 201 Created
$response
$response.Content
