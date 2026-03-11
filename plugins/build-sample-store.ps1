$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repoRoot = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $repoRoot 'app/src/main/assets/cards'
$sourcesRoot = Join-Path $PSScriptRoot 'sources'
$releasesRoot = Join-Path $PSScriptRoot 'releases'
$rawBase = 'https://raw.githubusercontent.com/snit9076-rgb/Ge-store/main'
$repoBase = 'https://github.com/snit9076-rgb/Ge-store'
$deterministicArchiveTimestamp = [DateTimeOffset]::Parse('2024-01-01T00:00:00+00:00')
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Convert-ToLf {
    param([AllowNull()][string]$Content)

    if ($null -eq $Content) { return '' }
    return $Content.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Write-Utf8FileIfChanged {
    param(
        [string]$Path,
        [string]$Content
    )

    $normalized = Convert-ToLf $Content
    if ($normalized.Length -gt 0 -and -not $normalized.EndsWith("`n")) {
        $normalized += "`n"
    }
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    if (Test-Path $Path) {
        $existing = Convert-ToLf ([System.IO.File]::ReadAllText($Path))
        if ($existing -ceq $normalized) {
            return
        }
    }

    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

function Copy-FileIfChanged {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    $sourceContent = [System.IO.File]::ReadAllText($SourcePath)
    Write-Utf8FileIfChanged -Path $DestinationPath -Content $sourceContent
}

function New-DeterministicArchive {
    param(
        [string]$SourceDir,
        [string]$DestinationPath
    )

    $sourceRootPath = (Resolve-Path $SourceDir).Path.TrimEnd('\')
    $parent = Split-Path -Parent $DestinationPath
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    if (Test-Path $DestinationPath) {
        Remove-Item $DestinationPath -Force
    }

    $files = Get-ChildItem -Path $SourceDir -Recurse -File | Sort-Object { $_.FullName.Replace('\', '/') }
    $archiveStream = [System.IO.File]::Open($DestinationPath, [System.IO.FileMode]::Create)
    try {
        $archive = New-Object System.IO.Compression.ZipArchive($archiveStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($sourceRootPath.Length + 1).Replace('\', '/')
                $entry = $archive.CreateEntry($relativePath, [System.IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = $deterministicArchiveTimestamp
                $entryStream = $entry.Open()
                try {
                    $sourceStream = [System.IO.File]::OpenRead($file.FullName)
                    try {
                        $sourceStream.CopyTo($entryStream)
                    } finally {
                        $sourceStream.Dispose()
                    }
                } finally {
                    $entryStream.Dispose()
                }
            }
        } finally {
            $archive.Dispose()
        }
    } finally {
        $archiveStream.Dispose()
    }
}

$plugins = @(
    @{ PluginType='syntax_card'; Id='ext.wiki-links'; Name='Wiki Links'; Slug='wiki-links'; Version='1.0.0'; Author='GeminiNotes'; Description='Render [[WikiLinks]], #tags, and @mentions as styled links'; IconName='Link'; Category='Format'; Downloads=0; Rating=4.8; Featured=$true; Asset='builtin.wiki-links'; MinAppVersion=12; Patterns=@('wikilink','hashtag','mention'); UseCases=@('Knowledge Base','Research Notes','Cross-link Navigation'); QualitySignals=@('Verified','Beginner-friendly','High compatibility'); InstallHint='Works best in note collections that rely on tags, mentions, and wiki-style navigation.'; SourceType='official'; CompatibilityLevel='native' },
    @{ PluginType='syntax_card'; Id='ext.emoji-shortcode'; Name='Emoji Shortcodes'; Slug='emoji-shortcode'; Version='1.1.0'; Author='GeminiNotes'; Description='Convert :shortcodes: into emoji characters with an expanded dictionary'; IconName='AutoAwesome'; Category='Format'; Downloads=0; Rating=4.7; Featured=$true; Asset='builtin.emoji-shortcode'; MinAppVersion=12; Patterns=@('emoji_shortcode'); UseCases=@('Study Notes','Personal Journals','Lightweight Status Markers'); QualitySignals=@('Verified','Quick win','Beginner-friendly'); InstallHint='A good starter card for general-purpose decks that need more expressive notes without extra syntax overhead.'; SourceType='official'; CompatibilityLevel='native' },
    @{ PluginType='syntax_card'; Id='ext.text-highlight'; Name='Text Highlight'; Slug='text-highlight'; Version='1.0.0'; Author='GeminiNotes'; Description='Highlight ==marked== text segments inside notes'; IconName='AutoAwesome'; Category='Format'; Downloads=0; Rating=4.6; Featured=$false; Asset='builtin.text-highlight'; MinAppVersion=12; Patterns=@('text_highlight'); UseCases=@('Revision Notes','Lecture Review','Key Point Extraction'); QualitySignals=@('Verified','Focused writing','Low friction'); InstallHint='Pair this with a clean reading deck when users need clear emphasis without adding heavy layout syntax.'; SourceType='community'; CompatibilityLevel='native' },
    @{ PluginType='syntax_card'; Id='ext.code-tools'; Name='Code Tools'; Slug='code-tools'; Version='1.0.0'; Author='GeminiNotes'; Description='Add copy buttons and line numbers to fenced code blocks'; IconName='Terminal'; Category='Tool'; Downloads=0; Rating=4.9; Featured=$true; Asset='builtin.code-tools'; MinAppVersion=12; Patterns=@('code_copy','code_line_numbers'); UseCases=@('Technical Docs','Programming Notes','Code Review Prep'); QualitySignals=@('Verified','Power-user ready','Technical writing'); InstallHint='Best added to developer-focused decks alongside syntax highlighting and markdown basics.'; SourceType='official'; CompatibilityLevel='native' },
    @{ PluginType='app_plugin'; Id='app.linter-actions'; Name='Linter Actions'; Slug='linter-actions'; Version='0.1.0'; Author='GeminiNotes'; Description='Run safe markdown cleanup commands on the current note'; IconName='Rule'; Category='Productivity'; Downloads=0; Rating=4.6; Featured=$true; MinAppVersion=20; Capabilities=@('command.register','note.read','note.write_current'); Permissions=@('note.read','note.write_current'); Commands=@(@{ id='normalize_heading_spacing'; label='Normalize Heading Spacing'; description='Insert a space after heading markers like #Title'; action='normalize_heading_spacing'; payload=''; requiresSelection=$false }, @{ id='normalize_list_spacing'; label='Normalize List Spacing'; description='Insert a space after unordered and ordered list markers'; action='normalize_list_spacing'; payload=''; requiresSelection=$false }, @{ id='trim_trailing_spaces'; label='Trim Trailing Spaces'; description='Remove trailing spaces and tabs from each line'; action='trim_trailing_spaces'; payload=''; requiresSelection=$false }, @{ id='collapse_blank_lines'; label='Collapse Blank Lines'; description='Reduce repeated blank lines to a single separator'; action='collapse_blank_lines'; payload=''; requiresSelection=$false }); UseCases=@('Markdown Cleanup','Imported Notes','Technical Writing'); QualitySignals=@('Verified candidate','Deterministic transforms','Current-note safe'); InstallHint='Runs deterministic markdown cleanup commands on the active note through the GeminiNotes App Plugin host.'; SourceType='adapted'; CompatibilityLevel='adapted'; OriginStore='obsidian-community'; Upstream=@{ pluginId='obsidian-linter'; name='Linter'; author='Victor Tao'; version='1.27.1'; sourceUrl='https://github.com/platers/obsidian-linter' }; AdapterVersion='0.1.0-adapted.1'; AdapterMaintainer='GeminiNotes Labs'; PreservedFeatures=@('Normalize heading spacing in the current note','Normalize list marker spacing','Trim trailing spaces','Collapse repeated blank lines'); RemovedFeatures=@('Vault-wide batch formatting','File rename and metadata workflows'); KnownLimitations=@('Only the active note is transformed','Desktop-only automation and vault-wide cleanup are omitted'); UnsupportedFeatures=@('Batch linting across multiple files','File-system driven metadata operations'); ReviewStatus='experimental'; RiskLevel='low'; AdaptationReportPath='plugins/adapted/reports/app.linter-actions.md' },
    @{ PluginType='app_plugin'; Id='app.quick-actions'; Name='Quick Actions'; Slug='quick-actions'; Version='0.1.0'; Author='GeminiNotes'; Description='Add quick note cleanup commands, selection tools, and editor shortcuts'; IconName='AutoAwesome'; Category='Productivity'; Downloads=0; Rating=4.5; Featured=$false; MinAppVersion=20; Capabilities=@('command.register','note.read','note.write_current','editor.selection.replace'); Permissions=@('note.read','note.write_current','editor.selection.replace'); Commands=@(@{ id='insert_meeting_template'; label='Insert Meeting Template'; description='Insert a lightweight meeting template at the cursor'; action='insert_text'; payload="## Meeting Notes`n- Agenda`n- Decisions`n- Follow-ups`n"; requiresSelection=$false }, @{ id='wrap_selection_as_action_items'; label='Wrap Selection as Action Items'; description='Wrap the current selection into an action items block'; action='wrap_selection'; payload="### Action Items`n- {{selection}}"; requiresSelection=$true }, @{ id='append_follow_up_section'; label='Append Follow-up Section'; description='Append a follow-up section to the end of the note'; action='append_text'; payload="## Follow-up`n- [ ] Owner`n- [ ] Deadline`n- [ ] Next step"; requiresSelection=$false }); UseCases=@('Meeting Notes','Inbox Cleanup','Daily Capture'); QualitySignals=@('Experimental','Phase 2 sample','Adapted-ready'); InstallHint='Provides safe declarative editor commands that are registered by the App Plugin host.'; SourceType='adapted'; CompatibilityLevel='partial'; OriginStore='obsidian-community'; Upstream=@{ pluginId='quickadd'; name='QuickAdd'; author='Christian B. B. Houmann'; version='1.11.5'; sourceUrl='https://github.com/chhoumann/quickadd' }; AdapterVersion='0.1.0-adapted.1'; AdapterMaintainer='GeminiNotes Labs'; PreservedFeatures=@('Current-note template insertion','Selection-to-action-items transformation','Append follow-up checklist to the active note'); RemovedFeatures=@('Vault-wide capture macros','Interactive modal workflows'); KnownLimitations=@('Advanced capture macros are not included','Vault-wide automation was narrowed to current-note actions'); UnsupportedFeatures=@('Desktop-only file system actions','Custom modal workflows from the original plugin'); ReviewStatus='experimental'; RiskLevel='medium'; AdaptationReportPath='plugins/adapted/reports/app.quick-actions.md' }
)

New-Item -ItemType Directory -Force -Path $sourcesRoot | Out-Null
New-Item -ItemType Directory -Force -Path $releasesRoot | Out-Null

$index = @()

foreach ($plugin in $plugins) {
    $pluginDir = Join-Path $sourcesRoot $plugin.Slug
    $isSyntaxCard = $plugin.PluginType -eq 'syntax_card'
    $assetDir = if ($isSyntaxCard) {
        $candidateAssetDir = Join-Path $assetsRoot $plugin.Asset
        if (Test-Path $candidateAssetDir) { $candidateAssetDir } else { $null }
    } else {
        $null
    }
    $packageExtension = if ($isSyntaxCard) { '.cardslot' } else { '.gnplugin' }
    $releasePath = Join-Path $releasesRoot ($plugin.Slug + $packageExtension)

    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null

    if ($isSyntaxCard) {
        $manifest = [ordered]@{
            pluginType = $plugin.PluginType
            id = $plugin.Id
            name = $plugin.Name
            version = $plugin.Version
            author = $plugin.Author
            description = $plugin.Description
            iconName = $plugin.IconName
            claimedPatterns = [System.Object[]]@($plugin.Patterns)
            incompatibleWith = @()
            minAppVersion = $plugin.MinAppVersion
        } | ConvertTo-Json -Depth 4

        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'manifest.json') -Content $manifest
        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'render.js') -Content "(function(){ /* Asset-driven plugin bootstrap */ })();"
        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'README.md') -Content "# $($plugin.Name)`n`nGenerated from built-in card assets for the GeminiNotes community store."

        if ($null -ne $assetDir) {
            foreach ($fileName in @('style.css', 'post.js')) {
                $source = Join-Path $assetDir $fileName
                if (Test-Path $source) {
                    Copy-FileIfChanged -SourcePath $source -DestinationPath (Join-Path $pluginDir $fileName)
                }
            }
        }
    } else {
        $manifest = [ordered]@{
            pluginType = $plugin.PluginType
            id = $plugin.Id
            name = $plugin.Name
            version = $plugin.Version
            author = $plugin.Author
            description = $plugin.Description
            iconName = $plugin.IconName
            minAppVersion = $plugin.MinAppVersion
            compatibilityLevel = $plugin.CompatibilityLevel
            sourceType = $plugin.SourceType
            permissions = [System.Object[]]@($plugin.Permissions)
            capabilities = [System.Object[]]@($plugin.Capabilities)
            commands = [System.Object[]]@($plugin.Commands)
            entry = [ordered]@{ main = 'main.js' }
        } | ConvertTo-Json -Depth 4

        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'plugin.json') -Content $manifest
        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'main.js') -Content "(function(){ console.log('$($plugin.Name) app plugin placeholder'); })();"
        Write-Utf8FileIfChanged -Path (Join-Path $pluginDir 'README.md') -Content "# $($plugin.Name)`n`nGenerated sample App Plugin package for the GeminiNotes community store."
    }

    New-DeterministicArchive -SourceDir $pluginDir -DestinationPath $releasePath

    $supportedPatterns = $null
    $capabilities = $null
    $permissions = $null
    if ($isSyntaxCard) {
        $supportedPatterns = [System.Object[]]@($plugin.Patterns)
    } else {
        $capabilities = [System.Object[]]@($plugin.Capabilities)
        $permissions = [System.Object[]]@($plugin.Permissions)
    }
    $knownLimitations = if ($null -ne $plugin.KnownLimitations) { [System.Object[]]@($plugin.KnownLimitations) } else { $null }
    $unsupportedFeatures = if ($null -ne $plugin.UnsupportedFeatures) { [System.Object[]]@($plugin.UnsupportedFeatures) } else { $null }
    $preservedFeatures = if ($null -ne $plugin.PreservedFeatures) { [System.Object[]]@($plugin.PreservedFeatures) } else { $null }
    $removedFeatures = if ($null -ne $plugin.RemovedFeatures) { [System.Object[]]@($plugin.RemovedFeatures) } else { $null }

    $indexEntry = [ordered]@{
        pluginType = $plugin.PluginType
        id = $plugin.Id
        name = $plugin.Name
        version = $plugin.Version
        author = $plugin.Author
        description = $plugin.Description
        downloadUrl = "$rawBase/plugins/releases/$($plugin.Slug)$packageExtension"
        homepageUrl = "$repoBase/blob/main/plugins/sources/$($plugin.Slug)/README.md"
        sourceRepoUrl = "$repoBase/tree/main/plugins/sources/$($plugin.Slug)"
        iconName = $plugin.IconName
        category = $plugin.Category
        downloads = $plugin.Downloads
        rating = $plugin.Rating
        previewUrl = $null
        featured = $plugin.Featured
        supportedPatterns = $supportedPatterns
        useCases = [System.Object[]]@($plugin.UseCases)
        qualitySignals = [System.Object[]]@($plugin.QualitySignals)
        capabilities = $capabilities
        permissions = $permissions
        minAppVersion = $plugin.MinAppVersion
        installHint = $plugin.InstallHint
        sourceType = $plugin.SourceType
        compatibilityLevel = $plugin.CompatibilityLevel
    }

    if ($null -ne $plugin.OriginStore) { $indexEntry.originStore = $plugin.OriginStore }
    if ($null -ne $plugin.Upstream) { $indexEntry.upstream = $plugin.Upstream }
    if ($null -ne $plugin.AdapterVersion) { $indexEntry.adapterVersion = $plugin.AdapterVersion }
    if ($null -ne $plugin.AdapterMaintainer) { $indexEntry.adapterMaintainer = $plugin.AdapterMaintainer }
    if ($null -ne $preservedFeatures) { $indexEntry.preservedFeatures = $preservedFeatures }
    if ($null -ne $removedFeatures) { $indexEntry.removedFeatures = $removedFeatures }
    if ($null -ne $knownLimitations) { $indexEntry.knownLimitations = $knownLimitations }
    if ($null -ne $unsupportedFeatures) { $indexEntry.unsupportedFeatures = $unsupportedFeatures }
    if ($null -ne $plugin.ReviewStatus) { $indexEntry.reviewStatus = $plugin.ReviewStatus }
    if ($null -ne $plugin.RiskLevel) { $indexEntry.riskLevel = $plugin.RiskLevel }
    if ($null -ne $plugin.AdaptationReportPath) { $indexEntry.adaptationReportUrl = "$repoBase/blob/main/$($plugin.AdaptationReportPath)" }

    $index += $indexEntry
}

Write-Utf8FileIfChanged -Path (Join-Path $PSScriptRoot 'plugins.json') -Content ($index | ConvertTo-Json -Depth 5)
& (Join-Path $PSScriptRoot 'validate-store.ps1') -PluginsRoot $PSScriptRoot
Write-Host "Generated plugins.json and $($plugins.Count) sample packages under plugins/."