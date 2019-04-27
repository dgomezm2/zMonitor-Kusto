[CmdletBinding()]
Param(
    [Parameter (Mandatory = $true, Position = 1)]
    [string]$reportname,

    [Parameter (Mandatory = $true, Position = 2)]
    [string]$dynamicQuery
)

#Use the local AzureRunAsConnection account for actions within the tenant
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
write-output $dynamicQuery
# Set service provider Azure storage account and get the context
$StorageAccountName = "zmonitorcentralservice"
$StorageContainerName = "csvlogs"
$StorageAccountKey = "JIeuCwZHdX6xBC9/wF3NgUt/h0aYl0yXoR28OcrImLOu79AGgzt5PFvvRNnmCbne6GCP2teNAi9oLyYoHOU6rg=="
$Ctx = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey

$workspace = Get-AutomationVariable -Name 'OMSResourceGroupName'
$date = Get-Date -f yyyyMMddHHmm
# Run the OMS Query Search
# NOTE : Results are limited to 5000 results by the API
$TenantId = $Conn.TenantID 
$ClientID = "b35d8cb4-644f-49e9-8359-e330dc52972d"      
$ClientSecret = "jrT{G2F:Uuf6sY}|;H+tF/yhL(wTC@3)11Sjx@v*5iw3D4ST^drq+OAJD&WNh"  
$resource = "https://api.loganalytics.io"   
$loginURL = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = @{grant_type = "client_credentials"; resource = $resource; client_id = $ClientID; client_secret = $ClientSecret }
$oauth = Invoke-RestMethod -Method Post -Uri $loginURL -Body $body
$headerParams = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
$WorkspaceID = Get-AutomationVariable -Name 'OMSWorkspaceId'
$url = "https://api.loganalytics.io/v1/workspaces/$WorkspaceID/query"
write-output $url
$body = @{query = $dynamicQuery } | ConvertTo-Json
$result = Invoke-RestMethod -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -Body $body -ContentType "application/json"
if ($result.tables[0].rows.count -gt 0) {
    # Process the report if it contains data
    $result.tables[0].rows | ForEach-Object { $_ -join ',' | ConvertFrom-Csv -Header $result.tables[0].columns.name | Export-Csv -NoTypeInformation $env:TEMP\"zMonitorOMS"-$($reportname)-$($date)-temp.csv -Force -Append }
    Import-Csv $env:TEMP\"zMonitorOMS"-$($reportname)-$($date)-temp.csv | 
    Select-Object *, @{Name = 'tenantworkspace'; Expression = { $($workspace) } }, @{Name = 'reportname'; Expression = { $($reportname) } } | 
    Export-Csv -NoTypeInformation $env:TEMP\$($workspace)-$($reportname)-$($date).csv
    Write-Output "Moving CSV Results File to Azure Blob Storage."
    Set-AzureStorageBlobContent -Context $Ctx -File $env:TEMP\$($workspace)-$($reportname)-$($date).csv -Container $StorageContainerName -Force | Out-Null
    
}