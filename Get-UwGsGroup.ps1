<#
.NAME
	Get-UwGsGroup.ps1
	
.DESCRIPTION
    Get a group from the UW Groups Service	

.NOTES
    Author: Eric Kool-Brown
    Created: 2016-11-04
	
	Permissions required to run this script:
    - A certificate permitted to write to the Groups Service and set as admin on the u_windowsinfrastructure stem
    - Permission for the task running the script to access the certificate private key
#>

Param([string]$group,
      [string]$certName)

$serviceHost = "https://iam-ws.u.washington.edu:7443"
$serviceEndPoint = $serviceHost + "/group_sws/v2/"
$uri = $serviceEndPoint + "group/" + $group

# locate the certificate that will be used to authenticate the GWS call
$certSubjectMatch = 'CN=' + $certName + '*'
$cert = dir Cert:\LocalMachine\My | Where {$_.Subject -like $certSubjectMatch}
if ($cert -eq $null) {
    Write-Error "Cannot find appropriate machine cert for making GWS calls"
    return
}
Write-Host "Making GWS call using certificate: $($cert.Subject)"
Write-Host "Making call using URI: $uri"

try {
    $resp = Invoke-WebRequest -Method GET -uri $uri -certificate $cert -contentType "text/xml"
}
catch {
    Write-Error "Web request failed error: $($_.Exception)"
    return
}

Write-Host "Web request returned status code: $($resp.StatusCode) $($resp.StatusDescription)"

Write-Host "Object type returned:" $resp.GetType().Name

Write-Host "Result payload:"
$resp
Write-Host "Headers:"
$resp.Headers | ft
Write-Host "XHTML content:"
$resp.Content

# cast the content to an XML object
[XML]$xml = $resp.Content
# The are two XHTML child nodes, head and body; we want the body:
$xml1 = $xml.ChildNodes[1] # can do dotted sub-nodes or pass to Select-XML for XPath queries

# Select-Xml returns an object of type SelectXmlInfo; the results of the
# select -expand node is an XmlElement object
$emailenabled = Select-Xml -Xml $xml1 -XPath "//*[@class='emailenabled']" | select -expand node
Write-Output "EmailEnabled: $($emailenabled.InnerText)"

# The members must be fetched using the href
$memberElement = Select-Xml -Xml $xml1 -XPath "//*[@rel='members']" | select -expand node
#$memberElement.href
$memberUri = $serviceHost + $memberElement.href
Write-Host "Fetching membership using URI:" $memberUri
$resp = Invoke-WebRequest -Method GET -uri $memberUri -certificate $cert -contentType "text/xml"
if ($resp.StatusCode -eq 200) {
    $xml = $resp.Content
    $xml1 = $xml.ChildNodes[1]
    $members = Select-Xml -Xml $xml1 -XPath "//*[@class='members']" | select -expand node
    Write-Host "Group members:"
    $members.ChildNodes | % {
        $_.InnerText
    }
}
