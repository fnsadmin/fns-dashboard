# FNS RMM - ScreenConnect Data Fetcher
# Runs via GitHub Actions every 30 minutes
# Pulls all machine data from SC API and saves to data.json

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

# All known machine name prefixes across your 20 sites
# Format: "PREFIX" will match any machine starting with that prefix
$sitePrefixes = @(
    # Site prefix, friendly site name
    @{prefix="MAC-";    site="MacKenzie Painting"},
    @{prefix="BDR-";    site="BDR"},
    @{prefix="SIG-";    site="Signature"},
    @{prefix="FJP-";    site="FJP"},
    @{prefix="CMI-";    site="CMI"},
    @{prefix="WW-";     site="Weinshel"},
    @{prefix="WWA-";    site="Weinshel"},
    @{prefix="TED-";    site="Weinshel"},
    @{prefix="LER-";    site="Leron"},
    @{prefix="BTX-";    site="BTX"},
    @{prefix="FNS-";    site="FNS"},
    @{prefix="CSS-";    site="CSS"},
    @{prefix="PRM-";    site="PRM"},
    @{prefix="ATP-";    site="ATP"},
    @{prefix="PPT-";    site="PhilPhysical"},
    @{prefix="MRG-";    site="Mill River Group"},
    @{prefix="SHL-";    site="Shollander"},
    @{prefix="RSH-";    site="Rodeph Sholom"},
    @{prefix="JP-";     site="JP Property"},
    @{prefix="LOEB-";   site="Loeb"},
    @{prefix="DAVID";   site="Leron"}
)

# We'll collect all unique sessions here
$allSessions = @{}

Write-Host "Starting SC data fetch at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "SC URL: $SCUrl"

# For each prefix, search for machines
foreach ($entry in $sitePrefixes) {
    $prefix = $entry.prefix
    Write-Host "Fetching machines with prefix: $prefix"
    
    try {
        # Search by each letter a-z and 0-9 after the prefix to get all machines
        # GetSessionsByName does exact match, so we use the machine name prefix trick
        # by fetching known machine names. First try the prefix itself.
        $body = '["' + $prefix.TrimEnd('-') + '"]'
        $result = Invoke-RestMethod -Uri "$apiBase/GetSessionsByName" -Method POST -Headers $headers -Body $body -ErrorAction SilentlyContinue
        
        if ($result -and $result.value) {
            foreach ($session in $result.value) {
                if (-not $allSessions.ContainsKey($session.SessionID)) {
                    $allSessions[$session.SessionID] = $session
                }
            }
        }
    } catch {
        Write-Host "  Error fetching $prefix`: $_"
    }
}

# Better approach: use GetSessionsByCustomProperty to get by company name
# CustomProperty1 = Company/Site name
$companyNames = @(
    "MacKenzie Painting",
    "BDR",
    "Signature",
    "FJP",
    "CMI",
    "Weinshel",
    "Leron",
    "BTX",
    "FNS",
    "CSS",
    "PRM",
    "ATP",
    "PhilPhysical",
    "Mill River",
    "Shollander",
    "Rodeph",
    "JP Property",
    "Loeb"
)

# Try GetSessionsByCustomProperty for each company
foreach ($company in $companyNames) {
    Write-Host "Fetching by company: $company"
    try {
        $body = '["' + $company + '"]'
        $result = Invoke-RestMethod -Uri "$apiBase/GetSessionsByCustomProperty" -Method POST -Headers $headers -Body $body -ErrorAction SilentlyContinue
        
        if ($result -and $result.value) {
            Write-Host "  Found $($result.Count) machines for $company"
            foreach ($session in $result.value) {
                if (-not $allSessions.ContainsKey($session.SessionID)) {
                    $allSessions[$session.SessionID] = $session
                }
            }
        }
    } catch {
        Write-Host "  Method not available, skipping: $_"
    }
}

Write-Host "Total unique sessions found: $($allSessions.Count)"

# Now transform the raw SC data into our dashboard format
$machines = @()
$now = Get-Date -AsUTC

foreach ($session in $allSessions.Values) {
    try {
        $gi = $session.GuestInfo
        
        # Determine online status - if last disconnected > last connected, machine is offline
        $lastConn = if ($session.LastGuestConnectedEventTime) { [DateTime]$session.LastGuestConnectedEventTime } else { [DateTime]::MinValue }
        $lastDisc = if ($session.LastGuestDisconnectedEventTime) { [DateTime]$session.LastGuestDisconnectedEventTime } else { [DateTime]::MinValue }
        $online = $lastConn -gt $lastDisc -and ($now - $lastConn).TotalMinutes -lt 10
        
        # Get site name from CustomProperty1
        $site = if ($session.CustomProperties.CustomProperty1) { $session.CustomProperties.CustomProperty1 } else { $gi.MachineDomain }
        if (-not $site) { $site = "UNKNOWN" }
        
        # Determine OS
        $os = if ($gi) { $gi.OperatingSystemName } else { "" }
        
        # Win11 ready check
        $win11Ready = if ($os -match "Windows 11") { "yes" } elseif ($os -match "Windows 10") { "check" } else { "n/a" }
        
        # Days since last update - we don't get this from SC directly
        # This will be enriched by the FNS Monitor data later
        $daysSinceUpdate = $null

        # Last seen
        $lastSeen = if ($session.GuestInfoUpdateTime) { $session.GuestInfoUpdateTime } else { $null }

        # Memory
        $memTotal = if ($gi) { $gi.SystemMemoryTotalMegabytes } else { $null }
        $memAvail = if ($gi) { $gi.SystemMemoryAvailableMegabytes } else { $null }

        $machines += @{
            sessionId        = $session.SessionID
            name             = $session.Name
            site             = $site
            os               = $os
            online           = $online
            lastSeen         = $lastSeen
            lastConnected    = $session.LastGuestConnectedEventTime
            lastDisconnected = $session.LastGuestDisconnectedEventTime
            lastBoot         = if ($gi) { $gi.LastBootTime } else { $null }
            diskC            = $null
            daysSinceUpdate  = $daysSinceUpdate
            av               = "check"
            win11Ready       = $win11Ready
            ip               = if ($gi) { $gi.PrivateNetworkAddress } else { "" }
            domain           = if ($gi) { $gi.MachineDomain } else { "" }
            manufacturer     = if ($gi) { $gi.MachineManufacturerName } else { "" }
            model            = if ($gi) { $gi.MachineModel } else { "" }
            cpu              = if ($gi) { $gi.ProcessorName } else { "" }
            memTotalMB       = $memTotal
            memAvailMB       = $memAvail
            scVersion        = $session.GuestClientVersion
            activeConnections = $session.ActiveConnections.Count
        }
    } catch {
        Write-Host "Error processing session $($session.Name): $_"
    }
}

# Build final output
$output = @{
    generatedAt   = (Get-Date -Format "o")
    totalMachines = $machines.Count
    scUrl         = $SCUrl
    machines      = $machines
}

$json = $output | ConvertTo-Json -Depth 10
$json | Out-File -FilePath "data.json" -Encoding UTF8

Write-Host "data.json written with $($machines.Count) machines"
Write-Host "Done at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
