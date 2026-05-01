# FNS RMM - ScreenConnect Data Fetcher
# Runs via GitHub Actions every 30 minutes
# Self-updating: discovers new machines automatically

param(
    [string]$SCUrl = $env:SC_URL,
    [string]$SCSecret = $env:SC_SECRET,
    [string]$SCOrigin = $env:SC_ORIGIN
)

$headers = @{
    "CTRLAuthHeader" = $SCSecret
    "Content-Type"   = "application/json"
    "Origin"         = $SCOrigin
}

$apiBase = "$SCUrl/App_Extensions/2d558935-686a-4bd0-9991-07539f5fe749/Service.ashx"

# ---------------------------------------------------------------
# KNOWN MACHINE LIST (373 machines - last exported 2026-05-01)
# New machines are discovered automatically via prefix scan below
# ---------------------------------------------------------------
$knownMachineNames = @(
    '4R-PC-2025',
    'AA-JESSICA-LPT',
    'AA-JESSICA-WK2',
    'AA-WK3',
    'AAZARM-LPT',
    'AC-NAS',
    'AC-WKS-1',
    'AIFG-WRK-1',
    'ANDREA-X1',
    'ANNIKA-LPT',
    'APOGEE-SVR',
    'AT-APP1  POS Server',
    'AT-DC1 Domain Controller',
    'AZARM-AD',
    'AZARM-DFS',
    'AZARM-DFS2',
    'Admins-Mac-mini-2',
    'BARB-LYON',
    'BDR-ACOLEMAN',
    'BDR-AD',
    'BDR-ADH',
    'BDR-ANTHONY',
    'BDR-BSTN-WK1',
    'BDR-BSTN-WK2',
    'BDR-BSTN-WK3',
    'BDR-BSTN-WKS5',
    'BDR-Billy-WK',
    'BDR-CLAUDIA',
    'BDR-CONF1',
    'BDR-CONF2',
    'BDR-DFS',
    'BDR-FRANK-LPT',
    'BDR-H-MDUBY',
    'BDR-H-WK2',
    'BDR-H-WK3',
    'BDR-HWKS1',
    'BDR-JAPPLEBY',
    'BDR-JBEATO',
    'BDR-JBEVILACQUA',
    'BDR-JFANELLI',
    'BDR-JNASH-WK',
    'BDR-JPETRIE',
    'BDR-LENNY-LPT',
    'BDR-MARIO-LPT',
    'BDR-MICHELE-WK',
    'BDR-MSANTOS',
    'BDR-NFLAHIVE-LT',
    'BDR-NICK-LPT',
    'BDR-RNESE',
    'BDR-SCOTT-WK',
    'BDR-SH-LPT2',
    'BDR-SH-SP1',
    'BDR-SPARE1',
    'BDR-SPARE2',
    'BDR-SPARE3',
    'BDR-TFULCO',
    'BDR-TGALLO-LPT',
    'BDR-TJ-WK',
    'BDR-WH-LPT1',
    'BDR-WH1-WK',
    'BDR-WSEBBEN',
    'BDRUCKENMILLER-',
    'BOS-AD',
    'BOS-DFS',
    'BOS-LPT1',
    'BOS-LPT2',
    'BOS-LPT3',
    'BOS-LPT3',
    'BOS-WKS10',
    'BOS-WKS11',
    'BOS-WKS12',
    'BPCP20010',
    'BWILLIAMS-PC',
    'CARRIE-PC',
    'CGRAZIANO-PC',
    'CHEANDMALCOLM',
    'CHRIS-RODE-LPT',
    'CMI-CANTOR-LPT',
    'CMI-EDUCATION',
    'CMI-JENNIFER-LT',
    'CMI-JODY-LPT',
    'CMI-LAP2020',
    'CMI-LIBRARY',
    'CMI-LIBRARY-WK2',
    'CMI-RABBIB-WKS',
    'CMI-SARAH-WKS',
    'CMI-SIERRA-LPT',
    'CMI-STREAM-WK',
    'CMI01',
    'CMIDESK-002',
    'CMILAP-001',
    'COMDEY-DELL',
    'CRS-SBEDFORD',
    'CSS-FILEDC',
    'CSS-KIM-LPT',
    'CSS-RABBI-LPT',
    'CSS-RABBIASSIST',
    'CSS-SDENYER-LPT',
    'CSS-SECURITY-PC',
    'CSS-SECURITY-WK',
    'CT-1501',
    'CT-1506',
    'CWEINSHEL-LPT',
    'DANJR-PC',
    'DAVIDFORSTER-PC',
    'DC-LPT1',
    'DD-BOB-WK2',
    'DENTAL-SVR',
    'DESKTOP-020SPBD',
    'DESKTOP-3J9HV1H',
    'DESKTOP-3K6L5CK',
    'DESKTOP-833VG0C',
    'DESKTOP-9809AT2',
    'DESKTOP-BFS6J2K',
    'DESKTOP-I5ADVNJ',
    'DESKTOP-IDV8LNT',
    'DESKTOP-JJD9JJ0',
    'DESKTOP-JTSM5MU',
    'DESKTOP-L4S96CJ',
    'DESKTOP-P7QCL12',
    'DESKTOP-QM5FRLL',
    'DESKTOP-RENTNEL',
    'DESKTOP-RK8UUI1',
    'DESKTOP-U6P2FJI',
    'DESMOND-PC',
    'DETOMAI-LPT',
    'DEVON-DELL',
    'DFLEJSZAR-HART',
    'DISPATCH',
    'DNT-FD-02',
    'DOCTOR_ROOM',
    'DR-01',
    'DR-02',
    'DR-03',
    'EMILY',
    'ESH-WKS',
    'FJP-CINDY-LPT',
    'FJP-DATA',
    'FJP-EDUYOUTH-MG',
    'FJP-EMISSARY',
    'FJP-GENNIFER-LT',
    'FJP-HPLPT-2',
    'FJP-HRC-WKS',
    'FJP-JANET-PC',
    'FJP-JWEISS-LPT',
    'FJP-KPARIS-WKS',
    'FJP-LBECKER-LT',
    'FJP-LISA-WKST',
    'FJP-LPT11',
    'FJP-PCD1',
    'FJP-PDC2',
    'FJP-PRISCILLA',
    'FJP-SHELLEY-LPT',
    'FJP-SKAMISAR-LT',
    'FJP-SP-LPT',
    'FJP-VEEAM',
    'FNS-AD',
    'FNS-AD2',
    'FNS-DELL-SP1',
    'FNS-GCLAUDIO-WK',
    'FNS-WK3',
    'FNS-WRK1',
    'FSCHUSTER-WK',
    'GEORGE',
    'GLICKENHAUS-NAZ',
    'H2T-LENOVO',
    'HULL-PCX',
    'I7',
    'I9',
    'ILANA-PC',
    'IMOSS-LPT',
    'INVEST-PC',
    'JACK-DELL',
    'JESS',
    'JP-ANNIE',
    'JP-DANA',
    'JP-HOWARD-WK',
    'JUSTER-SVR',
    'KEN',
    'KIRSTEN-DELL',
    'KJ-LPT',
    'KJENNINGS-TP-I7',
    'LAPTOP-5FA6VGO1',
    'LAPTOP-5HBMIEG8',
    'LAPTOP-GMGM2MGS',
    'LAPTOP-HKPCUKN8',
    'LAPTOP-KG156634',
    'LAPTOP-P2M6TOND',
    'LAPTOP-Q7TL3A9T',
    'LAPTOP-US3O2UGL',
    'LARRUDA0720',
    'LAURA-PC',
    'LENOVO-T15',
    'LERON-REMOTE',
    'LG-LPT',
    'LINDA-HP',
    'LOEB-HOME',
    'LOU',
    'LOUISDEMETR8F8D',
    'LRN-AD',
    'LRN-DFS',
    'LRN-RDP',
    'LRN-REESA-WKS',
    'MA-DELL-INSPIRO',
    'MAC-13098',
    'MAC-13907',
    'MAC-13909',
    'MAC-14865',
    'MAC-1503',
    'MAC-1504',
    'MAC-1505',
    'MAC-ACCOUNTANT',
    'MAC-ALEX',
    'MAC-AWOLFINGER',
    'MAC-BRENDEN',
    'MAC-BTHARIN',
    'MAC-CLAIRE-WK',
    'MAC-DC01',
    'MAC-DC02',
    'MAC-DEEDEE',
    'MAC-FS01',
    'MAC-JARCOMA',
    'MAC-LSTEELE-WK',
    'MAC-MAL',
    'MAC-MISSY-WK',
    'MAC-OGARRIGUE',
    'MAC-PETE',
    'MAC-RALPH',
    'MAC-SHELLY-WK',
    'MAC-SQL01',
    'MAC-TBASSETT-WK',
    'MAC-TONY-WK',
    'MAC-TSCIROCCO',
    'MADSVR',
    'MAINTENANCE-PC',
    'MARGIE-WKS-1',
    'MARGIEPETRO-PC',
    'MATT',
    'MATT',
    'MERKAZ-DELLWS2',
    'MIKE-HOMEPC',
    'MIKE-PC',
    'MISHKAN-OAS',
    'MISSY-LPT',
    'MLOEB-WK',
    'MMONTEIRO-LPT',
    'MMONTEIRO-PC',
    'MONICA-PC',
    'MYTRA-CATHERINE',
    'MYTRA-CC-LPT1',
    'MYTRA-CC-LPT2',
    'MYTRA-CC-LPT3',
    'MYTRA-CC-LPT4',
    'MYTRA-CC-LPT5',
    'MYTRA-CC-LPT6',
    'MYTRA-CC-LPT7',
    'MYTRA-CC-LPT8',
    'MYTRA-IBRAHIM',
    'NAZLI-LPT',
    'NEWDELL2014',
    'Nancy- DESKTOP-QTQMD64',
    'OZZIE-PC',
    'PAIGE',
    'PE-CRAIG-WK3',
    'PE-MIKE-WK',
    'PETRA-PC-24',
    'PMACDONALD-LPT',
    'PPT-AD1',
    'PPT-FRONTDESK',
    'PPT-LPT-1',
    'PPT-LPT-2',
    'PPT-SRVDB01',
    'PPT-SRVDFS01',
    'PPT-SRVDFS02',
    'PPT-WKS-2',
    'PRE-SCHOOL-PC',
    'PRM-AD1',
    'PRM-DEVON-LPT',
    'PRM-DEVON-WKS',
    'PRM-FS01',
    'RAFEEK-407',
    'REESA-PC',
    'REGINA-WKS-1',
    'RS-AD',
    'RS-DATA',
    'Reesas-MacBook-Air',
    'SAR-DESK',
    'SAR-WKS-2',
    'SCG-ADMIN-LPT',
    'SCG-ENGINEERING',
    'SCG-HPPAV-G15 Melissa',
    'SCG-JACK-LPT',
    'SCG-NAZLI-LT',
    'SCNY-1',
    'SCT-ACARELLA-WK',
    'SH-ADRIAN-WK',
    'SH-ADRIAN-WKS',
    'SH-AFG-WKS',
    'SH-AMY-WK',
    'SH-GUARDS-LPT',
    'SH-GWEN-WK',
    'SH-JS-WKS',
    'SH-NAS',
    'SIGCT-AD',
    'SIGCT-AD-2K',
    'SIGCT-CHRIS-SRF',
    'SIGCT-DFS',
    'SIGCT-DFS-2K',
    'SIGCT-FRANK-LPT',
    'SIGCT-GREG-WK',
    'SIGCT-HV-SVR',
    'SIGCT-RICH-SURF',
    'SIGCT-STEVE-LPT',
    'SIGCT-STEVE-WK',
    'SIGCT-TPALMER',
    'SIGNY-CONFERENC',
    'SIGNY-DC',
    'SIGNY-DC2',
    'SIGNY-DFS-New',
    'SIGNY-GISEL-WK',
    'SIGNY-JDECUNZO',
    'SIGNY-JFORTY-LT',
    'SIGNY-JNUNBERG',
    'SIGNY-JSZYMANIK',
    'SIGNY-KRZYSZTOF',
    'SIGNY-LRADA-WK',
    'SIGNY-MIKEO-WKS',
    'SIGNY-MNICOLOSI',
    'SIGNY-MONICA-WK',
    'SIGNY-PSANCHEZ',
    'SIGNY-SFARREL-LPT',
    'SIGNY-SGIRALDO',
    'SIGNY-SIGIFREDO',
    'SMS-CT1001',
    'SNY-AVARGAS-LPT',
    'SNY-AVARGAS-WK',
    'STATION-1',
    'STATION-1',
    'STATION-2',
    'STATION-2',
    'SW-JON-WK',
    'SW-WKS-1',
    'SW-WKS-2',
    'Server DNT-FD01',
    'TABLET-TGL7OS7V',
    'TED-HP',
    'TSP-ASTOFFEL-PC',
    'TSP-ISABEL-LPT',
    'TSP-JACK-LPT',
    'TSP-JOHNB-LPT',
    'TSP-KELLY-LPT',
    'TSP-LAUREN-LPT',
    'TSP-LENOVO-I5',
    'TSP-LOUIS-LPT',
    'TTOMAI-DESK',
    'WP-LAP03',
    'WP-LAP04',
    'WPP-BOB-LPT',
    'WPP-MGACEK-LPT',
    'WPP-NGLENN-LPT',
    'WPP-WS6',
    'WPP-WS6-2021',
    'WWA-CONF-WK',
    'WWA-FRONT-PC',
    'WWA-JEN-PC1',
    'WWA-JEN-PC25',
    'WWA-REMOTE',
    'WWA-SC-PC2',
    'WWA-SVR',
    'WWA-WKS-2',
    'WWA-WKS-3',
    'WWA-WKS-4',
    'X2190'
)

# ---------------------------------------------------------------
# Helper: parse a single session object returned by SC API
# NOTE: SC returns the object directly (not nested under .value)
# when there is exactly one result
# ---------------------------------------------------------------
function Parse-Session {
    param($s)
    if (-not $s -or -not $s.Name) { return $null }

    $gi = $s.GuestInfo

    # Online: check ActiveConnections first, then event times
    $isOnline = $false
    if ($s.ActiveConnections -and $s.ActiveConnections.Count -gt 0) {
        $isOnline = $true
    } else {
        $lastConn = if ($s.LastGuestConnectedEventTime -and $s.LastGuestConnectedEventTime -ne "0001-01-01T00:00:00") {
            [DateTime]$s.LastGuestConnectedEventTime
        } else { [DateTime]::MinValue }
        $lastDisc = if ($s.LastGuestDisconnectedEventTime -and $s.LastGuestDisconnectedEventTime -ne "0001-01-01T00:00:00") {
            [DateTime]$s.LastGuestDisconnectedEventTime
        } else { [DateTime]::MinValue }
        $isOnline = $lastConn -gt $lastDisc -and ([DateTime]::UtcNow - $lastConn).TotalMinutes -lt 15
    }

    # Site name
    $site = ""
    if ($s.CustomProperties -and $s.CustomProperties.CustomProperty1) {
        $site = $s.CustomProperties.CustomProperty1
    }
    if (-not $site -or $site -eq "") {
        $site = if ($gi -and $gi.MachineDomain) { $gi.MachineDomain } else { "UNKNOWN" }
    }

    # OS and Win11
    $os = if ($gi) { $gi.OperatingSystemName } else { "" }
    $win11Ready = if ($os -match "Windows 11") { "yes" }
                  elseif ($os -match "Windows 10") { "check" }
                  elseif ($os -match "Server") { "n/a" }
                  else { "unknown" }

    return @{
        name             = $s.Name
        site             = $site
        os               = $os
        online           = $isOnline
        lastSeen         = $s.GuestInfoUpdateTime
        lastConnected    = $s.LastGuestConnectedEventTime
        lastDisconnected = $s.LastGuestDisconnectedEventTime
        lastBoot         = if ($gi) { $gi.LastBootTime } else { $null }
        diskC            = $null
        daysSinceUpdate  = $null
        av               = "check"
        win11Ready       = $win11Ready
        ip               = if ($gi) { $gi.PrivateNetworkAddress } else { "" }
        domain           = if ($gi) { $gi.MachineDomain } else { "" }
        manufacturer     = if ($gi) { $gi.MachineManufacturerName } else { "" }
        model            = if ($gi) { $gi.MachineModel } else { "" }
        cpu              = if ($gi) { $gi.ProcessorName } else { "" }
        memTotalMB       = if ($gi) { $gi.SystemMemoryTotalMegabytes } else { $null }
        memAvailMB       = if ($gi) { $gi.SystemMemoryAvailableMegabytes } else { $null }
        scVersion        = $s.GuestClientVersion
        sessionId        = $s.SessionID
    }
}

# ---------------------------------------------------------------
# STEP 1: Scan for new machines not in known list
# ---------------------------------------------------------------
Write-Host "Step 1: Scanning for new/unknown machines..."
$allMachineNames = [System.Collections.Generic.List[string]]($knownMachineNames)

$scanPrefixes = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','0','1','2','3','4','5','6','7','8','9')
foreach ($prefix in $scanPrefixes) {
    $testNames = @("${prefix}A","${prefix}B","${prefix}C","${prefix}D","${prefix}E","${prefix}F","${prefix}G","${prefix}H","${prefix}I","${prefix}J")
    foreach ($testName in $testNames) {
        try {
            $body = ConvertTo-Json @($testName)
            $result = Invoke-RestMethod -Uri "$apiBase/GetSessionsByName" -Method POST -Headers $headers -Body $body -ErrorAction SilentlyContinue
            # Handle both single object and array responses
            $sessions = if ($result -is [System.Array]) { $result } elseif ($result -and $result.Name) { @($result) } else { @() }
            foreach ($s in $sessions) {
                if ($s.Name -and $allMachineNames -notcontains $s.Name) {
                    Write-Host "  NEW MACHINE DISCOVERED: $($s.Name)"
                    $allMachineNames.Add($s.Name)
                }
            }
        } catch {}
    }
}

Write-Host "Total machines to fetch: $($allMachineNames.Count) ($($allMachineNames.Count - $knownMachineNames.Count) new)"

# ---------------------------------------------------------------
# STEP 2: Fetch full details for every machine
# ---------------------------------------------------------------
Write-Host "Step 2: Fetching machine details..."
$machines = @()
$fetched = 0
$errors = 0

foreach ($machineName in $allMachineNames) {
    try {
        $body = ConvertTo-Json @($machineName)
        $result = Invoke-RestMethod -Uri "$apiBase/GetSessionsByName" -Method POST -Headers $headers -Body $body -ErrorAction Stop

        # SC returns single object directly or array depending on result count
        $sessions = if ($result -is [System.Array]) { $result }
                    elseif ($result -and $result.Name) { @($result) }
                    else { @() }

        foreach ($s in $sessions) {
            $parsed = Parse-Session $s
            if ($parsed) {
                $machines += $parsed
                $fetched++
            }
        }
    } catch {
        $errors++
    }
}

Write-Host "Fetched: $fetched machines, Skipped/errors: $errors"

# ---------------------------------------------------------------
# STEP 3: Write data.json
# ---------------------------------------------------------------
$output = @{
    generatedAt   = (Get-Date -Format "o")
    totalMachines = $machines.Count
    scUrl         = $SCUrl
    machines      = $machines
}

$output | ConvertTo-Json -Depth 10 | Out-File -FilePath "data.json" -Encoding UTF8
Write-Host "data.json written with $($machines.Count) machines"
Write-Host "Done at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
