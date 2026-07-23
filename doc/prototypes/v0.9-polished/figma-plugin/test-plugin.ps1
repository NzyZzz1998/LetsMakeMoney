param(
    [string]$PluginRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-FileSha256Lower {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-Utf8WithoutMojibake {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    try { $text = $utf8.GetString($bytes) }
    catch { throw "文件不是有效 UTF-8：$Path" }
    $badPatterns = @(
        ([char]0x951B).ToString(),
        ([char]0x9286).ToString(),
        ([char]0x7481).ToString(),
        ([char]0x6FDE).ToString()
    )
    foreach ($pattern in $badPatterns) {
        Assert-True (-not $text.Contains($pattern)) "检测到乱码模式 '$pattern'：$Path"
    }
}

function Assert-Png {
    param([string]$Path, $Metadata)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $signature = @(137, 80, 78, 71, 13, 10, 26, 10)
    Assert-True ($bytes.Length -gt 24) "PNG 为空或过短：$Path"
    for ($index = 0; $index -lt $signature.Count; $index++) {
        Assert-True ($bytes[$index] -eq $signature[$index]) "PNG 签名错误：$Path"
    }
    Assert-True ($bytes.Length -eq [int64]$Metadata.bytes) "PNG 字节数与 manifest 不一致：$Path"
    Assert-True ((Get-FileSha256Lower $Path) -eq [string]$Metadata.sha256) "PNG SHA256 与 manifest 不一致：$Path"
    $image = [Drawing.Image]::FromFile($Path)
    try {
        Assert-True ($image.Width -eq [int]$Metadata.width) "PNG 宽度与 manifest 不一致：$Path"
        Assert-True ($image.Height -eq [int]$Metadata.height) "PNG 高度与 manifest 不一致：$Path"
        Assert-True ($image.Width -gt 0 -and $image.Height -gt 0) "PNG 尺寸无效：$Path"
    }
    finally { $image.Dispose() }
}

$manifestPath = Join-Path $PluginRoot "manifest.json"
$codePath = Join-Path $PluginRoot "code.js"
$templatePath = Join-Path $PluginRoot "ui.template.html"
$uiPath = Join-Path $PluginRoot "ui.html"
$buildPath = Join-Path $PluginRoot "build.ps1"
$readmePath = Join-Path $PluginRoot "README.md"
$assetManifestPath = Join-Path $PluginRoot "generated-assets\asset-manifest.json"

foreach ($path in @($manifestPath, $codePath, $templatePath, $uiPath, $buildPath, $readmePath, $assetManifestPath)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "缺少插件文件：$path"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($manifest.editorType -contains "figma") "插件必须面向 Figma Design"
Assert-True ($manifest.documentAccess -eq "dynamic-page") "插件必须使用 dynamic-page"
Assert-True ((Test-Path -LiteralPath (Join-Path $PluginRoot $manifest.main))) "manifest.main 不存在"
Assert-True ((Test-Path -LiteralPath (Join-Path $PluginRoot $manifest.ui))) "manifest.ui 不存在"

$code = Get-Content -LiteralPath $codePath -Raw -Encoding UTF8
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$ui = Get-Content -LiteralPath $uiPath -Raw -Encoding UTF8
$forbiddenStatusLabel = ([char]0x5DF2).ToString() + ([char]0x5B9E).ToString() + ([char]0x73B0).ToString()

# 单页、所有权与非 LMM 页面保护。
Assert-True ($code.Contains('const PAGE_NAME = "LMM 01 Full Product Flow"')) "唯一管理页名称不正确"
Assert-True (-not $code.Contains('const PAGE_NAMES =')) "不得维护多个管理页面"
Assert-True ($code.Contains('function isOwnedPage(page)')) "缺少旧页所有权检查"
Assert-True ($code.Contains('if (isOwnedPage(legacy)) legacy.remove()')) "旧页面删除前未验证所有权"
Assert-True ($code.Contains('await figma.setCurrentPageAsync(page)')) "删除旧页面前未切换到目标管理页"
Assert-True ($code.Contains('warnings.push(`保留未确认归属的旧页')) "未确认所有权的旧页没有保护告警"
Assert-True (-not $code.Contains('figma.root.remove')) "禁止删除 Figma 根文档"
Assert-True (-not $code.Contains('for (const page of figma.root.children) page.remove()')) "禁止批量删除非 LMM 页面"
Assert-True ($code.Contains('targetMatches.some((item) => !isOwnedPage(item))')) "目标同名页缺少归属保护"
Assert-True ($code.Contains('for (const child of [...page.children]) child.remove()')) "幂等更新未清理目标管理页子节点"
Assert-True ($code.Contains('const blank = figma.root.children.find')) "首次运行缺少空白页复用"

# 5120 栅格、间距、运行实测尺寸和历史参考尺寸。
foreach ($token in @(
    'const GRID_WIDTH = 5120',
    'const DOCUMENT_WIDTH = 5200',
    'const SECTION_PADDING = 24',
    'const GROUP_GAP = 18',
    'const PRD_REFERENCE_SIZES =',
    'const RUNTIME_BASELINES =',
    'const DPI_SCALE_MATRIX =',
    'main: [900, 500]',
    'panelCollapsed: [300, 124]',
    'panelExpanded: [344, 232]',
    'today: [480, 620]',
    'settings: [700, 520]',
    'wizard: [720, 520]',
    'menu: [232, 34]',
    'about: [420, 280]',
    'panelCollapsed: [236, 64]',
    'panelExpanded: [304, 224]',
    'today: [500, 700]',
    'settings: [720, 540]',
    'wizard: [760, 560]',
    'menu: [240, 34]'
)) {
    Assert-True ($code.Contains($token)) "缺少画布或尺寸合同：$token"
}
Assert-True ($code.Contains('运行证据与历史参考')) "未区分 PRD 历史参考与 Godot 运行实测"
Assert-True (-not $code.Contains('const SIZE_BASELINES =')) "旧尺寸常量不得继续作为运行时基线"
Assert-True ($code.Contains('function contractReference')) "缺少界面邻接契约索引"
Assert-True ([Regex]::Matches($code, 'contractReference\(').Count -ge 10) "邻接契约索引覆盖不足"
Assert-True ($code.Contains('待真实 Windows 验证')) "125%/150% DPI 未标记真实验证边界"
Assert-True ($code.Contains('禁止把 100% 位图直接放大')) "缺少 DPI 真实布局约束"

# 与 QuickRec 原型文档同构的单页信息架构。
foreach ($token in @(
    'function buildDocumentCover(root, y)',
    'LMM Full Product Flow / Document identity',
    'A", "可编辑原型"',
    'B", "控件契约"',
    'const CONTRACT_COLUMNS = 5',
    'const CONTRACT_CARD_HEIGHT = 420',
    'const CONTRACT_ROW_GAP = 16',
    'function contractLine(parent, label, value, y, tone = "default")',
    'function contractBoardHeight(ids)',
    'function contractSectionHeight(gridY, ids)',
    'fill: DOC.surface, stroke: DOC.line, radius: 8',
    'root = owned(nodeFrame(prepared.page, "LMM 01 Full Product Flow / 5120 Grid", 0, 0, DOCUMENT_WIDTH'
)) {
    Assert-True ($code.Contains($token)) "缺少统一原型文档结构：$token"
}
Assert-True (-not $code.Contains('width, 184, { fill: DOC.surface')) "契约卡仍使用会导致文字重叠的 184px 旧高度"
Assert-True (-not $code.Contains('rows * 200')) "契约板仍使用旧的 200px 行距"
Assert-True ($code.Contains('CONTRACT_CARD_HEIGHT + gap')) "契约卡没有按 420px 高度和 16px 间距排布"
Assert-True ([Regex]::Matches($code, 'const areaHeight = contractSectionHeight').Count -eq 6) "六个含契约业务区未全部使用动态高度"
Assert-True ($code.Contains('function validateGeneratedLayout(root)')) "缺少生成后重叠验证"
Assert-True ($code.Contains('顶层区域重叠')) "缺少顶层区域重叠失败信息"
Assert-True ($code.Contains('契约卡重叠')) "缺少契约卡重叠失败信息"
Assert-True ($code.Contains('契约文字越界')) "缺少契约文字越界失败信息"
Assert-True ($code.Contains('同级模块重叠')) "缺少窗口与模块同级重叠门禁"
Assert-True ($code.Contains('窗口文字越界')) "缺少裁切窗口文字越界门禁"
Assert-True ($code.Contains('function validateSiblingFrameLayout(parent)')) "缺少递归同级布局检查"
Assert-True ($code.Contains('function validateClippedTextBounds(root)')) "缺少窗口文字边界检查"
Assert-True ($code.Contains('"Compact component registry", 28, 430')) "组件注册区仍可能与字体卡重叠"
Assert-True ($code.Contains('validateGeneratedLayout(root)')) "生成完成前未执行布局验证"
Assert-True ($template.Contains('LMM Windows v0.9 Design Builder')) "插件面板标题未与原型文档统一"
Assert-True ($template.Contains('LMM 01 Full Product Flow')) "插件面板未说明唯一管理页"
Assert-True ($code.Contains('function flowCard(parent, id, title, detail')) "缺少 QuickRec 同构流程节点"
Assert-True ($code.Contains('card.setSharedPluginData(OWNER_NAMESPACE, "flow-target", id)')) "流程节点缺少隐藏跳转标识"
Assert-True (-not $code.Contains('局部流程')) "不得额外显示流程标题胶囊"
Assert-True (-not $template.Contains('局部流程')) "插件面板不得额外显示流程标题胶囊"
Assert-True ($template.Contains('Figma MCP')) "插件面板未说明本地插件边界"
Assert-True (-not $code.Contains($forbiddenStatusLabel)) "生成器不得自行添加完成状态文案"
Assert-True (-not $template.Contains($forbiddenStatusLabel)) "插件面板不得自行添加完成状态文案"
Assert-True (-not $ui.Contains($forbiddenStatusLabel)) "构建产物不得包含完成状态文案"

# 控件与契约一一对应。
$contractMatches = [Regex]::Matches($code, 'contract\("(LMM-B-\d{3})"')
$contractIds = @($contractMatches | ForEach-Object { $_.Groups[1].Value })
Assert-True ($contractIds.Count -eq 77) "控件契约数量必须保持 77，实际：$($contractIds.Count)"
Assert-True (($contractIds | Sort-Object -Unique).Count -eq $contractIds.Count) "契约 ID 重复"
foreach ($id in $contractIds) {
    $occurrences = [Regex]::Matches($code, [Regex]::Escape($id)).Count
    Assert-True ($occurrences -ge 2) "契约没有对应可编辑控件实例：$id"
}
Assert-True ($code.Contains('setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids"')) "节点未写入 control-contract-ids"
Assert-True ($code.Contains('setSharedPluginData(OWNER_NAMESPACE, "control-contract"')) "节点未写入 control-contract"
Assert-True ($code.Contains('待确认')) "无法确认事项没有标记待确认"

# 所有交互帮助器都要求 contract id 参数。
foreach ($helper in @('controlButton', 'controlInput', 'controlSelect', 'controlToggle', 'controlSlider', 'attachContract')) {
    Assert-True ($code.Contains("function $helper")) "缺少契约化控件帮助器：$helper"
}

# 构建后的 6 张 PNG 与机器可读 manifest。
$assetManifest = Get-Content -LiteralPath $assetManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($assetManifest.schema -eq "lmm-figma-static-assets/v1") "素材 manifest schema 不正确"
Assert-True ([int]$assetManifest.screenshot_assets -eq 0) "不得嵌入运行截图"
$expectedAssets = @('classicWorking', 'classicAwake', 'classicSleeping', 'duoduoWorking', 'duoduoAwake', 'duoduoSleeping')
foreach ($name in $expectedAssets) {
    $metadata = $assetManifest.assets.$name
    Assert-True ($null -ne $metadata) "素材 manifest 缺少：$name"
    Assert-True ($metadata.role -eq "product-pet-keyframe") "素材角色不正确：$name"
    Assert-True (-not [bool]$metadata.runtime_screenshot) "运行截图被误标为素材：$name"
    $assetPath = Join-Path $PluginRoot ([string]$metadata.output).Replace('/', '\')
    Assert-True (Test-Path -LiteralPath $assetPath -PathType Leaf) "缺少生成 PNG：$assetPath"
    Assert-Png -Path $assetPath -Metadata $metadata
}

Assert-True (-not $ui.Contains('__ASSET_PAYLOAD_JSON__')) "ui.html 存在未替换占位符"
Assert-True (-not [Regex]::IsMatch($code + $template, '(?i)(runtime[-_ ]?screenshot|\.tmp_acceptance|evidence[/\\].*\.(png|jpg)|screen[-_ ]?capture)')) "插件源码嵌入了运行截图路径"

# 连续构建两次，输出哈希必须一致。
& powershell -NoProfile -ExecutionPolicy Bypass -File $buildPath -PluginRoot $PluginRoot | Out-Null
$firstUiHash = Get-FileSha256Lower $uiPath
$firstAssetManifestHash = Get-FileSha256Lower $assetManifestPath
& powershell -NoProfile -ExecutionPolicy Bypass -File $buildPath -PluginRoot $PluginRoot | Out-Null
Assert-True ((Get-FileSha256Lower $uiPath) -eq $firstUiHash) "重复构建 ui.html 不幂等"
Assert-True ((Get-FileSha256Lower $assetManifestPath) -eq $firstAssetManifestHash) "重复构建素材 manifest 不幂等"

# JavaScript、UTF-8、乱码与 diff。
$node = Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $node) {
    $bundledNode = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
    if (Test-Path -LiteralPath $bundledNode -PathType Leaf) { $node = $bundledNode }
}
if ($node) {
    & $node --check $codePath
    Assert-True ($LASTEXITCODE -eq 0) "code.js JavaScript 语法检查失败"
}
else { Write-Warning "未找到 Node.js，JavaScript 语法检查未执行" }

Get-ChildItem -LiteralPath $PluginRoot -Recurse -File | Where-Object { $_.Extension -in @('.js', '.html', '.json', '.md', '.ps1') } | ForEach-Object { Assert-Utf8WithoutMojibake $_.FullName }

$repoRoot = (& git -C $PluginRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -eq 0 -and $repoRoot) {
    & git -C $repoRoot diff --check
    Assert-True ($LASTEXITCODE -eq 0) "git diff --check 失败"
}

Write-Host "Figma 插件静态验证通过"
Write-Host "- LMM 管理页面：1"
Write-Host "- 控件契约：$($contractIds.Count)"
Write-Host "- 确定性宠物 PNG：$($expectedAssets.Count)"
Write-Host "- 页面所有权、非 LMM 保护、重复构建幂等：通过"
Write-Host "- 关键尺寸、UTF-8、乱码与 git diff --check：通过"
