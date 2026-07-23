param(
  [Parameter(Mandatory = $true)]
  [string]$DraftPath,
  [string]$OutputRoot = "build/tree_import_dry_runs"
)

$ErrorActionPreference = 'Stop'
$familyId = 'ayivon'
$projectId = 'ayivon-aziangbede'
$databaseBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents"

function Invoke-FamilyQuery([string]$collectionId) {
  $body = @{
    structuredQuery = @{
      from = @(@{ collectionId = $collectionId })
      where = @{ fieldFilter = @{
        field = @{ fieldPath = 'familyId' }
        op = 'EQUAL'
        value = @{ stringValue = $familyId }
      }}
    }
  } | ConvertTo-Json -Depth 10
  $response = Invoke-RestMethod -Method Post -Uri "$databaseBase`:runQuery" -ContentType 'application/json' -Body $body
  return @($response | Where-Object { $_.document } | ForEach-Object { $_.document })
}

if (-not (Test-Path -LiteralPath $DraftPath)) {
  throw "Draft absent: $DraftPath"
}
$draft = Get-Content -Raw -LiteralPath $DraftPath | ConvertFrom-Json
$people = @($draft.persons)
$links = @($draft.parentChildLinks)
$ids = @($people | ForEach-Object { [string]$_.id })
$idSet = [Collections.Generic.HashSet[string]]::new([string[]]$ids)
$duplicates = @($ids | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
$invalidLinks = @($links | Where-Object { -not $idSet.Contains([string]$_.parentId) -or -not $idSet.Contains([string]$_.childId) })
$incoming = @{}
$children = @{}
foreach ($id in $ids) { $incoming[$id] = 0; $children[$id] = @() }
foreach ($link in $links) {
  $incoming[[string]$link.childId]++
  $children[[string]$link.parentId] += [string]$link.childId
}
$queue = [Collections.Generic.Queue[string]]::new()
$queue.Enqueue([string]$draft.rootPersonId)
$visited = [Collections.Generic.HashSet[string]]::new()
while ($queue.Count -gt 0) {
  $current = $queue.Dequeue()
  if (-not $visited.Add($current)) { continue }
  foreach ($child in $children[$current]) { $queue.Enqueue($child) }
}
$rootChildren = @($children[[string]$draft.rootPersonId])
$expectedHeads = @('akakpo','amekoudzi','nouwodou','dziwonou','amouzou')
$structuralErrors = @()
if ($draft.schema -ne 'ayivon-genealogy-draft/1.0') { $structuralErrors += 'schema inattendu' }
if ($draft.familyId -ne $familyId) { $structuralErrors += 'familyId inattendu' }
if ($people.Count -ne 23) { $structuralErrors += "personnes: $($people.Count) au lieu de 23" }
if ($links.Count -ne 22) { $structuralErrors += "relations: $($links.Count) au lieu de 22" }
if ($duplicates.Count -gt 0) { $structuralErrors += "IDs dupliques: $($duplicates -join ', ')" }
if ($invalidLinks.Count -gt 0) { $structuralErrors += 'references de relation invalides' }
if ($visited.Count -ne $people.Count) { $structuralErrors += "graphe non connexe: $($visited.Count)/$($people.Count) atteignables" }
if ($incoming[[string]$draft.rootPersonId] -ne 0) { $structuralErrors += 'la racine a un parent' }
if (@($incoming.Values | Where-Object { $_ -gt 1 }).Count -gt 0) { $structuralErrors += 'au moins une personne a plusieurs parents generiques' }
$actualHeadsKey = (($rootChildren | Sort-Object) -join ',')
$expectedHeadsKey = (($expectedHeads | Sort-Object) -join ',')
if ($actualHeadsKey -ne $expectedHeadsKey) { $structuralErrors += 'les cinq chefs de branche ne correspondent pas' }

$timestamp = Get-Date -Format 'yyyyMMddTHHmmssK'
$safeTimestamp = $timestamp.Replace(':','-').Replace('+','_')
$outputDir = Join-Path $OutputRoot $safeTimestamp
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$remoteMembers = Invoke-FamilyQuery 'members'
$remoteRelationships = Invoke-FamilyQuery 'relationships'
$remoteLinks = Invoke-FamilyQuery 'family_tree_links'
$familyDoc = $null
try { $familyDoc = Invoke-RestMethod -Method Get -Uri "$databaseBase/families/$familyId" } catch { $familyDoc = @{ readError = $_.Exception.Message } }
$localTree = Get-Content -Raw -LiteralPath 'assets/data/family_tree.json' | ConvertFrom-Json
$backup = [ordered]@{
  capturedAt = (Get-Date).ToUniversalTime().ToString('o')
  mode = 'read-only-dry-run'
  projectId = $projectId
  familyId = $familyId
  firestore = [ordered]@{
    family = $familyDoc
    members = $remoteMembers
    relationships = $remoteRelationships
    familyTreeLinks = $remoteLinks
  }
  localTree = $localTree
}
$backupPath = Join-Path $outputDir 'current_tree_backup.json'
$backup | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $backupPath -Encoding utf8

$mapping = @()
foreach ($person in $people) {
  $sourceId = [string]$person.id
  $targetId = "$familyId--$sourceId"
  $parentIds = @($links | Where-Object childId -eq $sourceId | ForEach-Object { "$familyId--$($_.parentId)" })
  $childIds = @($links | Where-Object parentId -eq $sourceId | ForEach-Object { "$familyId--$($_.childId)" })
  $mapping += [ordered]@{
    sourceId = $sourceId
    documentId = $targetId
    fields = [ordered]@{
      id = $targetId
      familyId = $familyId
      firstName = [string]$person.displayName
      lastName = ''
      gender = ''
      generation = [int]$person.generation
      fatherId = ''
      motherId = ''
      parents = $parentIds
      children = $childIds
      childrenIds = $childIds
      spouses = @()
      spouseIds = @()
      version = 1
      deletedAt = ''
      schemaVersion = 1
      createdAt = '<serverTimestamp>'
      updatedAt = '<serverTimestamp>'
      createdBy = '<authenticated-admin-uid>'
      updatedBy = '<authenticated-admin-uid>'
    }
  }
}
$mappingPath = Join-Path $outputDir 'firestore_mapping.json'
$mapping | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $mappingPath -Encoding utf8

$nonTechnicalMembers = @($remoteMembers | Where-Object { $_.name -notmatch '/members/_diagnostic_' })
$diagnosticMembers = @($remoteMembers | Where-Object { $_.name -match '/members/_diagnostic_' })
$report = [ordered]@{
  mode = 'DRY-RUN - NO FIRESTORE WRITES'
  draftPath = (Resolve-Path -LiteralPath $DraftPath).Path
  draftSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $DraftPath).Hash
  validation = [ordered]@{
    valid = ($structuralErrors.Count -eq 0)
    errors = $structuralErrors
    personCount = $people.Count
    parentChildLinkCount = $links.Count
    generationCount = @($people.generation | Sort-Object -Unique).Count
    reachableFromRoot = $visited.Count
    duplicateIds = $duplicates
    invalidLinkCount = $invalidLinks.Count
    rootPersonId = [string]$draft.rootPersonId
    rootChildren = $rootChildren
  }
  currentState = [ordered]@{
    firestoreMembers = $remoteMembers.Count
    genealogicalMembersPlannedForReplacement = $nonTechnicalMembers.Count
    technicalMembersPreserved = $diagnosticMembers.Count
    relationships = $remoteRelationships.Count
    familyTreeLinks = $remoteLinks.Count
    localPeople = @($localTree.people).Count
    localMarriageRelations = @($localTree.marriageRelations).Count
  }
  plannedWrite = [ordered]@{
    enabled = $false
    atomicRequired = $true
    createMembers = $mapping.Count
    createSeparateParentChildDocuments = 0
    embeddedParentChildLinks = $links.Count
    replaceGenealogicalMemberDocuments = $nonTechnicalMembers.Count
    preserveTechnicalDocuments = $diagnosticMembers.Count
    rootPersonDocumentId = "$familyId--$($draft.rootPersonId)"
    leaderPersonDocumentId = "$familyId--$($draft.rootPersonId)"
  }
  unresolvedNonBlockingFields = @($draft.validation.unresolvedFields)
  safeguards = @(
    'Aucune requete Firestore create/update/delete/commit executee',
    'Le document technique de diagnostic est exclu du remplacement',
    'Les noms ne sont pas arbitrairement decoupes',
    'Le sexe et les identifiants pere/mere restent vides',
    'Une authentification admin/superAdmin sera exigee avant un futur --apply'
  )
  artifacts = [ordered]@{ backup = $backupPath; mapping = $mappingPath }
}
$reportPath = Join-Path $outputDir 'dry_run_report.json'
$report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $reportPath -Encoding utf8
$manifest = Get-ChildItem -LiteralPath $outputDir -File | ForEach-Object {
  [ordered]@{ file = $_.Name; bytes = $_.Length; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash }
}
$manifestPath = Join-Path $outputDir 'manifest.json'
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$report | ConvertTo-Json -Depth 20
