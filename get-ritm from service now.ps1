
$ritmNumber = "RITM1105541"              # ERSÄTT med det specifika RITM-numret du söker



$userName = "api_db"         # ERSÄTT med ditt ServiceNow-användarnamn
$uri = " https://sweco.service-now.com/api/now/table/"

# Ber användaren om lösenordet säkert
$credential = Get-Credential -UserName $userName -Message "Ange ditt ServiceNow-lösenord"

# --- Skriptet börjar här ---

try {

    # --- Steg 1: Hämta RITM Sys_ID ---
    $table = "sc_req_item"
    $uriRitm = "$uri$($table)?sysparm_query=number=$ritmNumber"
    Write-Host "Steg 1 URI: $uriRitm"

    $ritmResponse = Invoke-RestMethod -Uri $uriRitm -Method Get -Credential $credential -ContentType "application/json"
    $ritmSysId = $ritmResponse.result.sys_id
    $ritmResponse.result | Select-Object number, sys_id, short_description, sys_updated_on, sys_created_by | Format-List

    if (-not $ritmSysId) {
        Write-Host "Kunde inte hitta SysID." -ForegroundColor Red; exit
    }
    Write-Host "RITM SysID hittades: $ritmSysId" -ForegroundColor Green

    # --- Steg 2: Hämta ALLA variabler med hjälp av Sys_ID ---

    # !! KORREKT TABELLNAMN ÄR sc_item_option_mtom !!
    $table = "sc_item_option_mtom"
    $uriVars = "$uri$($table)"
    
    $queryVars = "request_item=$($ritmSysId)"
    $fieldsVars = "sc_item_option.item_option_new.name,sc_item_option.value,sc_item_option.item_option_new.question_text"

    # Hela URI:n för steg 2 sätts nu ihop korrekt
    $uriVarsWithParams = "$($uriVars)?sysparm_query=$queryVars&sysparm_fields=$fieldsVars"
    
    Write-Host "`nSteg 2 URI: $uriVarsWithParams" -ForegroundColor Cyan

    $varsResponse = Invoke-RestMethod -Uri $uriVarsWithParams -Method Get -Credential $credential -ContentType "application/json"

    Write-Host "`n--- Variabler för $ritmNumber ---" -ForegroundColor Green
    foreach ($var in $varsResponse.result) {
        $var
    }

} catch {
    # ... felhantering ...
}

