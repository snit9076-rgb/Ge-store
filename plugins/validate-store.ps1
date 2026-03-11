param(
    [string]$PluginsRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

$indexPath = Join-Path $PluginsRoot 'plugins.json'
$releasesRoot = Join-Path $PluginsRoot 'releases'
$sourcesRoot = Join-Path $PluginsRoot 'sources'

if (!(Test-Path $indexPath)) { throw "Missing plugins.json: $indexPath" }
if (!(Test-Path $releasesRoot)) { throw "Missing releases directory: $releasesRoot" }
if (!(Test-Path $sourcesRoot)) { throw "Missing sources directory: $sourcesRoot" }

$plugins = Get-Content $indexPath -Raw | ConvertFrom-Json
if ($null -eq $plugins) { throw 'plugins.json is empty' }
if ($plugins -isnot [System.Array]) { $plugins = @($plugins) }

$seenIds = @{}
$allowedPreviewExt = @('.png', '.jpg', '.jpeg', '.webp')
$allowedPluginTypes = @('syntax_card', 'app_plugin')
$allowedCompatibilityLevels = @('native', 'adapted', 'partial', 'unsupported')
$allowedSourceTypes = @('official', 'community', 'adapted')
$allowedReviewStatuses = @('draft', 'verified', 'experimental', 'blocked')
$allowedRiskLevels = @('low', 'medium', 'high')

function Get-NormalizedStringArray {
    param([Parameter(ValueFromPipeline = $true)] $Value)

    if ($null -eq $Value) { return @() }
    $items = if ($Value -is [System.Array]) { $Value } else { @($Value) }
    return @(
        $items |
            ForEach-Object { ([string]$_).Trim() } |
            Where-Object { $_ -ne '' } |
            Select-Object -Unique
    )
}

foreach ($plugin in $plugins) {
    $pluginType = if ([string]::IsNullOrWhiteSpace([string]$plugin.pluginType)) { 'syntax_card' } else { ([string]$plugin.pluginType).Trim().ToLowerInvariant() }
    if ($pluginType -notin $allowedPluginTypes) {
        throw "Plugin '$($plugin.id)' has unsupported pluginType: $pluginType"
    }

    foreach ($field in @('id', 'name', 'version', 'author', 'description', 'downloadUrl', 'iconName', 'category')) {
        $value = $plugin.$field
        if ([string]::IsNullOrWhiteSpace([string]$value)) {
            throw "Plugin '$($plugin.id)' has empty required field '$field'"
        }
    }

    if ($seenIds.ContainsKey($plugin.id)) {
        throw "Duplicate plugin id found in plugins.json: $($plugin.id)"
    }
    $seenIds[$plugin.id] = $true

    if ($plugin.downloads -lt 0) {
        throw "Plugin '$($plugin.id)' has negative downloads"
    }
    if ($plugin.rating -lt 0 -or $plugin.rating -gt 5) {
        throw "Plugin '$($plugin.id)' rating must be between 0 and 5"
    }
    if ([string]$plugin.version -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
        throw "Plugin '$($plugin.id)' version must follow semantic versioning"
    }

    if ([string]::IsNullOrWhiteSpace([string]$plugin.compatibilityLevel)) {
        $compatibilityLevel = 'native'
    } else {
        $compatibilityLevel = ([string]$plugin.compatibilityLevel).Trim().ToLowerInvariant()
    }
    if ($compatibilityLevel -notin $allowedCompatibilityLevels) {
        throw "Plugin '$($plugin.id)' has unsupported compatibilityLevel: $compatibilityLevel"
    }

    if ([string]::IsNullOrWhiteSpace([string]$plugin.sourceType)) {
        $sourceType = 'community'
    } else {
        $sourceType = ([string]$plugin.sourceType).Trim().ToLowerInvariant()
    }
    if ($sourceType -notin $allowedSourceTypes) {
        throw "Plugin '$($plugin.id)' has unsupported sourceType: $sourceType"
    }

    $reviewStatus = if ([string]::IsNullOrWhiteSpace([string]$plugin.reviewStatus)) { $null } else { ([string]$plugin.reviewStatus).Trim().ToLowerInvariant() }
    if ($null -ne $reviewStatus -and $reviewStatus -notin $allowedReviewStatuses) {
        throw "Plugin '$($plugin.id)' has unsupported reviewStatus: $reviewStatus"
    }

    $riskLevel = if ([string]::IsNullOrWhiteSpace([string]$plugin.riskLevel)) { $null } else { ([string]$plugin.riskLevel).Trim().ToLowerInvariant() }
    if ($null -ne $riskLevel -and $riskLevel -notin $allowedRiskLevels) {
        throw "Plugin '$($plugin.id)' has unsupported riskLevel: $riskLevel"
    }

    if ($pluginType -eq 'syntax_card' -and [string]$plugin.id -notmatch '^ext\.[a-z0-9]+(?:[._-][a-z0-9]+)*$') {
        throw "Plugin '$($plugin.id)' must start with ext. and use lowercase slug format"
    }
    if ($pluginType -eq 'app_plugin' -and [string]$plugin.id -notmatch '^app\.[a-z0-9]+(?:[._-][a-z0-9]+)*$') {
        throw "Plugin '$($plugin.id)' must start with app. and use lowercase slug format"
    }

    $supportedPatterns = Get-NormalizedStringArray $plugin.supportedPatterns
    if ($pluginType -eq 'syntax_card' -and $supportedPatterns.Count -eq 0) {
        throw "Plugin '$($plugin.id)' must declare non-empty supportedPatterns"
    }

    $capabilities = Get-NormalizedStringArray $plugin.capabilities
    if ($pluginType -eq 'app_plugin' -and $capabilities.Count -eq 0) {
        throw "Plugin '$($plugin.id)' must declare non-empty capabilities"
    }

    $useCases = Get-NormalizedStringArray $plugin.useCases
    if ($useCases.Count -eq 0) {
        throw "Plugin '$($plugin.id)' must declare at least one useCase"
    }

    $qualitySignals = Get-NormalizedStringArray $plugin.qualitySignals
    if ($qualitySignals.Count -eq 0) {
        throw "Plugin '$($plugin.id)' must declare at least one qualitySignal"
    }

    $minAppVersion = [int]$plugin.minAppVersion
    if ($minAppVersion -le 0) {
        throw "Plugin '$($plugin.id)' minAppVersion must be a positive integer"
    }

    $downloadUri = [Uri]$plugin.downloadUrl
    if ($downloadUri.Scheme -notin @('http', 'https')) {
        throw "Plugin '$($plugin.id)' downloadUrl must be http(s): $($plugin.downloadUrl)"
    }

    $releaseFileName = [System.IO.Path]::GetFileName($downloadUri.AbsolutePath)
    $expectedExtension = if ($pluginType -eq 'syntax_card') { '.cardslot' } else { '.gnplugin' }
    if (![string]::Equals([System.IO.Path]::GetExtension($releaseFileName), $expectedExtension, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Plugin '$($plugin.id)' downloadUrl must point to a $expectedExtension file"
    }

    $releasePath = Join-Path $releasesRoot $releaseFileName
    if (!(Test-Path $releasePath)) {
        throw "Plugin '$($plugin.id)' is missing release package: $releasePath"
    }

    $slug = [System.IO.Path]::GetFileNameWithoutExtension($releaseFileName)
    $sourceDir = Join-Path $sourcesRoot $slug
    $manifestFileName = if ($pluginType -eq 'syntax_card') { 'manifest.json' } else { 'plugin.json' }
    $manifestPath = Join-Path $sourceDir $manifestFileName
    if (!(Test-Path $manifestPath)) {
        throw "Plugin '$($plugin.id)' is missing source manifest: $manifestPath"
    }

    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.id -ne $plugin.id) {
        throw "Plugin '$($plugin.id)' manifest id mismatch: $($manifest.id)"
    }
    if ($manifest.version -ne $plugin.version) {
        throw "Plugin '$($plugin.id)' manifest version mismatch: $($manifest.version) vs $($plugin.version)"
    }
    if ($manifest.name -ne $plugin.name) {
        throw "Plugin '$($plugin.id)' manifest name mismatch"
    }
    if ([int]$manifest.minAppVersion -ne $minAppVersion) {
        throw "Plugin '$($plugin.id)' manifest minAppVersion mismatch: $($manifest.minAppVersion) vs $minAppVersion"
    }

    if ($pluginType -eq 'syntax_card') {
        $manifestPatterns = Get-NormalizedStringArray $manifest.claimedPatterns
        $normalizedStorePatterns = ($supportedPatterns | Sort-Object) -join '|'
        $normalizedManifestPatterns = ($manifestPatterns | Sort-Object) -join '|'
        if ($normalizedStorePatterns -ne $normalizedManifestPatterns) {
            throw "Plugin '$($plugin.id)' supportedPatterns must match manifest claimedPatterns"
        }
    } else {
        $manifestCapabilities = Get-NormalizedStringArray $manifest.capabilities
        $normalizedStoreCapabilities = ($capabilities | Sort-Object) -join '|'
        $normalizedManifestCapabilities = ($manifestCapabilities | Sort-Object) -join '|'
        if ($normalizedStoreCapabilities -ne $normalizedManifestCapabilities) {
            throw "Plugin '$($plugin.id)' capabilities must match plugin.json capabilities"
        }

        $manifestCommands = @($manifest.commands)
        if ($capabilities -contains 'command.register' -and $manifestCommands.Count -eq 0) {
            throw "Plugin '$($plugin.id)' must declare commands in plugin.json when command.register is used"
        }
    }

    if ($null -ne $plugin.previewUrl -and "$($plugin.previewUrl)".Trim() -ne '') {
        $previewUri = [Uri]$plugin.previewUrl
        if ($previewUri.Scheme -notin @('http', 'https')) {
            throw "Plugin '$($plugin.id)' previewUrl must be http(s): $($plugin.previewUrl)"
        }
        $previewExt = [System.IO.Path]::GetExtension($previewUri.AbsolutePath).ToLowerInvariant()
        if ($previewExt -notin $allowedPreviewExt) {
            throw "Plugin '$($plugin.id)' previewUrl must point to png/jpg/jpeg/webp"
        }
    }

    if ($null -ne $plugin.homepageUrl -and "$($plugin.homepageUrl)".Trim() -ne '') {
        $homepageUri = [Uri]$plugin.homepageUrl
        if ($homepageUri.Scheme -notin @('http', 'https')) {
            throw "Plugin '$($plugin.id)' homepageUrl must be http(s): $($plugin.homepageUrl)"
        }
    }

    if ($null -ne $plugin.sourceRepoUrl -and "$($plugin.sourceRepoUrl)".Trim() -ne '') {
        $sourceRepoUri = [Uri]$plugin.sourceRepoUrl
        if ($sourceRepoUri.Scheme -notin @('http', 'https')) {
            throw "Plugin '$($plugin.id)' sourceRepoUrl must be http(s): $($plugin.sourceRepoUrl)"
        }
    }

    if ($null -ne $plugin.adaptationReportUrl -and "$($plugin.adaptationReportUrl)".Trim() -ne '') {
        $reportUri = [Uri]$plugin.adaptationReportUrl
        if ($reportUri.Scheme -notin @('http', 'https')) {
            throw "Plugin '$($plugin.id)' adaptationReportUrl must be http(s): $($plugin.adaptationReportUrl)"
        }
    }

    if ($sourceType -eq 'adapted') {
        if ($compatibilityLevel -eq 'native') {
            throw "Plugin '$($plugin.id)' adapted plugins cannot use native compatibilityLevel"
        }
        if ([string]::IsNullOrWhiteSpace([string]$plugin.originStore)) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare originStore"
        }
        if ($null -eq $plugin.upstream) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare upstream metadata"
        }
        foreach ($field in @('pluginId', 'name', 'author', 'version')) {
            if ([string]::IsNullOrWhiteSpace([string]$plugin.upstream.$field)) {
                throw "Plugin '$($plugin.id)' upstream.$field cannot be blank"
            }
        }
        if ($null -ne $plugin.upstream.sourceUrl -and "$($plugin.upstream.sourceUrl)".Trim() -ne '') {
            $upstreamUri = [Uri]$plugin.upstream.sourceUrl
            if ($upstreamUri.Scheme -notin @('http', 'https')) {
                throw "Plugin '$($plugin.id)' upstream.sourceUrl must be http(s)"
            }
        }
        if ([string]::IsNullOrWhiteSpace([string]$plugin.adapterVersion)) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare adapterVersion"
        }
        if ([string]::IsNullOrWhiteSpace([string]$plugin.adapterMaintainer)) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare adapterMaintainer"
        }
        if ($null -eq $reviewStatus) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare reviewStatus"
        }
        if ($null -eq $riskLevel) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare riskLevel"
        }
        $preservedFeatures = Get-NormalizedStringArray $plugin.preservedFeatures
        if ($preservedFeatures.Count -eq 0) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare preservedFeatures"
        }
        $knownLimitations = Get-NormalizedStringArray $plugin.knownLimitations
        if ($knownLimitations.Count -eq 0) {
            throw "Plugin '$($plugin.id)' adapted plugins must declare knownLimitations"
        }
    }
}

Write-Host "Store validation passed: $($plugins.Count) plugins, $($seenIds.Count) unique ids."