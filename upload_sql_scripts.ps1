# Import Sql scripts to workspace
$workspaceName = 'REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME'

# Get token for data plane
$token = Get-AzAccessToken -ResourceUrl https://dev.azuresynapse.net
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
 
# Read sql script file and save content to body variable
$sqlScriptFileFolder = './artifacts/synapse_data_security/'
Get-ChildItem $sqlScriptFileFolder | ForEach-Object -Process {
    $body = '{"name":"<sql-script-name>","properties":{"folder":{"name":"<script folder name>"},"content":{"query":"<sql-script>","metadata":{"language":"sql"},"currentConnection":{"databaseName":"master","poolName":"Built-in"},"resultLimit":5000},"type":"SqlQuery"}}'
    $folderName = 'Synapse Data Security'
    $body = $body -replace '<script folder name>', $folderName
    $sqlScriptName = $_.BaseName
    $body = $body -replace '<sql-script-name>', $sqlScriptName
    $script = Get-Content -Raw $_
    $body = $body -replace '<sql-script>', $script

    # Send request to create SQL script in a workspace
    Invoke-RestMethod -Method PUT -Uri https://${workspaceName}.dev.azuresynapse.net/sqlscripts/${sqlScriptName}?api-version=2020-12-01 -Body $body -Headers $authHeader
}

$sqlScriptFileFolder = './artifacts/synapse_serverless/'
Get-ChildItem $sqlScriptFileFolder | ForEach-Object -Process {
    $body = '{"name":"<sql-script-name>","properties":{"folder":{"name":"<script folder name>"},"content":{"query":"<sql-script>","metadata":{"language":"sql"},"currentConnection":{"databaseName":"master","poolName":"Built-in"},"resultLimit":5000},"type":"SqlQuery"}}'
    $folderName = 'Synapse Serverless'
    $body = $body -replace '<script folder name>', $folderName
    $sqlScriptName = $_.BaseName
    $body = $body -replace '<sql-script-name>', $sqlScriptName
    $script = Get-Content -Raw $_
    $body = $body -replace '<sql-script>', $script

    # Send request to create SQL script in a workspace
    Invoke-RestMethod -Method PUT -Uri https://${workspaceName}.dev.azuresynapse.net/sqlscripts/${sqlScriptName}?api-version=2020-12-01 -Body $body -Headers $authHeader
}

$sqlScriptFileFolder = './artifacts/synapse_stored_procedures/'
Get-ChildItem $sqlScriptFileFolder | ForEach-Object -Process {
    $body = '{"name":"<sql-script-name>","properties":{"folder":{"name":"<script folder name>"},"content":{"query":"<sql-script>","metadata":{"language":"sql"},"currentConnection":{"databaseName":"master","poolName":"Built-in"},"resultLimit":5000},"type":"SqlQuery"}}'
    $folderName = 'Synapse Stored Procedures'
    $body = $body -replace '<script folder name>', $folderName
    $sqlScriptName = $_.BaseName
    $body = $body -replace '<sql-script-name>', $sqlScriptName
    $script = Get-Content -Raw $_
    $body = $body -replace '<sql-script>', $script

    # Send request to create SQL script in a workspace
    Invoke-RestMethod -Method PUT -Uri https://${workspaceName}.dev.azuresynapse.net/sqlscripts/${sqlScriptName}?api-version=2020-12-01 -Body $body -Headers $authHeader
}
