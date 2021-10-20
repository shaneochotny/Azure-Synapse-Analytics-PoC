# Import Sql scripts to workspace
# Change hardcoded version of <workspace-name> and replace during setup 
# $workspaceName = '<workspace-name>'
$workspaceName = 'pocsynapseanalytics-bo9'
$sqlScriptFileFolder = './artifacts/synapse_data_security/'

# Get token for data plane
$token = Get-AzAccessToken -ResourceUrl https://dev.azuresynapse.net
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
 
# Read sql script file and save content to body variable
Get-ChildItem $sqlScriptFileFolder | ForEach-Object -Process {
    $body = '{"name":"<sql-script-name>","properties":{"folder":{"name":"Synapse Data Security"},"content":{"query":"<sql-script>","metadata":{"language":"sql"},"currentConnection":{"databaseName":"master","poolName":"Built-in"},"resultLimit":5000},"type":"SqlQuery"}}'
    $sqlScriptName = $_.BaseName
    $body = $body -replace '<sql-script-name>', $sqlScriptName
    $script = Get-Content -Raw $_
    $body = $body -replace '<sql-script>', $script

    # Send request to create SQL script in a workspace
    Invoke-RestMethod -Method PUT -Uri https://${workspaceName}.dev.azuresynapse.net/sqlscripts/${sqlScriptName}?api-version=2020-12-01 -Body $body -Headers $authHeader
}
