param(
    [string]$PluginRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-FileSha256Lower {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-Png {
    param([string]$Path, $Metadata)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    Assert-True ($bytes.Length -gt 1024) "PNG 文件过小或为空：$Path"
    for ($index = 0; $index -lt $signature.Length; $index += 1) {
        Assert-True ($bytes[$index] -eq $signature[$index]) "PNG 签名无效：$Path"
    }
    Assert-True ($bytes.Length -eq [int]$Metadata.bytes) "PNG 字节数不一致：$Path"
    Assert-True ((Get-FileSha256Lower $Path) -eq [string]$Metadata.sha256) "PNG SHA256 不一致：$Path"
    Assert-True ([int]$Metadata.width -gt 0 -and [int]$Metadata.height -gt 0) "PNG 尺寸无效：$Path"
}

function Assert-Utf8WithoutMojibake {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $strict = [Text.UTF8Encoding]::new($false, $true)
    try { $content = $strict.GetString($bytes) } catch { throw "文件不是有效 UTF-8：$Path" }
    $replacementCharacter = [string][char]0xfffd
    Assert-True (-not $content.Contains($replacementCharacter)) "检测到 Unicode replacement character：$Path"
}

$codePath = Join-Path $PluginRoot "code.js"
$templatePath = Join-Path $PluginRoot "ui.template.html"
$uiPath = Join-Path $PluginRoot "ui.html"
$buildPath = Join-Path $PluginRoot "build.ps1"
$manifestPath = Join-Path $PluginRoot "manifest.json"
$assetManifestPath = Join-Path $PluginRoot "generated-assets\asset-manifest.json"

foreach ($path in @($codePath, $templatePath, $buildPath, $manifestPath)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "缺少插件文件：$path"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $buildPath -PluginRoot $PluginRoot | Out-Null
Assert-True ($LASTEXITCODE -eq 0) "build.ps1 执行失败"

$code = Get-Content -LiteralPath $codePath -Raw -Encoding UTF8
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$ui = Get-Content -LiteralPath $uiPath -Raw -Encoding UTF8
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 单页、所有权和非 LMM 页面保护。
Assert-True ($code.Contains('const PAGE_NAME = "LMM 01 产品全链路"')) "唯一受管页面名称错误"
Assert-True ($code.Contains('item.name === PAGE_NAME || item.name === "LMM 01 Full Product Flow"')) "旧英文受管页面无法安全迁移"
Assert-True (-not $code.Contains('const PAGE_NAMES =')) "不得管理多个当前页面"
Assert-True ($code.Contains('function isOwnedPage(page)')) "缺少页面所有权检查"
Assert-True ($code.Contains('if (isOwnedPage(legacy)) legacy.remove()')) "删除旧页面前未验证所有权"
Assert-True ($code.Contains('targetMatches.some((item) => !isOwnedPage(item))')) "同名未授权页面缺少保护"
Assert-True ($code.Contains('for (const child of [...page.children]) child.remove()')) "目标页重复运行未幂等清理"
Assert-True ($code.Contains('const blank = figma.root.children.find')) "首次运行缺少空白页复用"
Assert-True (-not $code.Contains('figma.root.remove')) "禁止删除 Figma 根文档"
Assert-True (-not $code.Contains('for (const page of figma.root.children) page.remove()')) "禁止批量删除非 LMM 页面"

# 当前产品事实与真实尺寸。
foreach ($token in @(
    'const BUILDER_VERSION = "v1.0.8-full-product-flow-1"',
    'const GRID_WIDTH = 5120',
    'const DOCUMENT_WIDTH = 5200',
    'const SECTION_PADDING = 24',
    'const GROUP_GAP = 18',
    'mini: [344, 108]',
    'workbench: [820, 620]',
    'settings: [760, 560]',
    'wizard: [780, 580]',
    'privacyTab: [34, 108]',
    'Windows 11 已验收',
    'T-WORKBENCH-TODAY',
    'T-WORKBENCH-CALENDAR',
    'T-DATE-OVERRIDE',
    'T-OVERTIME',
    'T-WIZARD-1',
    'T-SETTINGS-INCOME',
    'WINDOWS-NATIVE-TRAY',
    'lmm:window-hidden/shown',
    'lmm://configuration-updated'
)) {
    Assert-True ($code.Contains($token)) "缺少 v1.0.8 产品合同：$token"
}

# v0.9 桌宠/Godot 内容不得继续出现在当前画布生成器。
foreach ($token in @('PetManager', 'T-PET-', '纯桌宠', 'Godot', 'Classic Pro', '多多 Pro', 'working_ack', 'awake_rest', 'sleeping')) {
    Assert-True (-not $code.Contains($token)) "当前生成器仍残留 v0.9 内容：$token"
}
Assert-True ($template.Contains('v0.9 桌宠、Godot 和动画合同会从受管画布移除')) "插件面板没有说明历史内容移除边界"

# 单页业务区和设计系统。
foreach ($token in @(
    'function buildCover(root, y)',
    'function buildOverview(root, y)',
    'function buildMini(root, y)',
    'function buildToday(root, y)',
    'function buildCalendar(root, y)',
    'function buildWizard(root, y)',
    'function buildSettings(root, y)',
    'function buildSystem(root, y)',
    'function buildDesign(root, y)',
    'figma.variables.createVariableCollection("LMM v1.0.8 / 浅色")',
    'figma.variables.createVariableCollection("LMM v1.0.8 / 深色")',
    'LMM/窗口阴影',
    '颜色/背景/画布',
    'LMM/${textStyleNames[name] || "文字"}',
    '浅色',
    '深色',
    '本区控件契约',
    '交互控件清单'
)) {
    Assert-True ($code.Contains($token)) "缺少单页结构或设计系统：$token"
}
Assert-True (-not $code.Contains('.addMode(')) "Starter 兼容模式不得在单个变量集合中添加第二个 mode"
Assert-True ($code.Contains('collection.name === "LMM v1.0.8" || collection.name.startsWith("LMM v1.0.8 / ")')) "缺少失败后半成品变量集合清理"

# 控件与契约一一对应。
$contractMatches = [Regex]::Matches($code, 'c\("(LMM-B-\d{3})"')
$contractIds = @($contractMatches | ForEach-Object { $_.Groups[1].Value })
Assert-True ($contractIds.Count -ge 80) "控件契约覆盖不足，实际：$($contractIds.Count)"
Assert-True (($contractIds | Sort-Object -Unique).Count -eq $contractIds.Count) "控件契约 ID 重复"
foreach ($id in $contractIds) {
    Assert-True ($id -match '^LMM-B-\d{3}$') "契约编号格式错误：$id"
}
$contractAreaMatches = [Regex]::Matches($code, 'c\("LMM-B-\d{3}",\s*"([^"]+)"')
$contractAreas = @($contractAreaMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$buildAreaMatches = [Regex]::Matches($code, 'CONTROL_SPECS\.filter\(\(s\) => s\.area === "([^"]+)"\)')
$buildAreas = @($buildAreaMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
foreach ($area in $contractAreas) {
    Assert-True ($buildAreas -contains $area) "控件契约区域没有对应画布构建分组：$area"
}
Assert-True ($code.Contains('c("LMM-B-007", "Settings"')) "LMM-B-007 必须归入 Settings 构建分组"
Assert-True ($code.Contains('const CONTRACT_AREA_LABELS')) "缺少控件区域中文显示映射"
Assert-True ($code.Contains('function inventory(parent, ids, x, y, width, height)')) "缺少就近契约清单生成器"
Assert-True ($code.Contains('function contractBoard(parent, ids, y)')) "缺少完整开发契约生成器"
Assert-True ($code.Contains('caption: { size: 14, line: 20')) "画布辅助文字字号过小"
Assert-True ($code.Contains('body: { size: 16, line: 24')) "画布正文字号过小"
Assert-True ($code.Contains('title: { size: 28, line: 36')) "画布标题字号过小"
Assert-True ($code.Contains('{ family: "Noto Sans SC", regular: "Regular", semibold: "Medium", bold: "Bold" }')) "画布必须优先使用完整覆盖中文的字体"
Assert-True (-not $code.Contains('{ family: "Inter"')) "禁止使用缺少中文字形的 Inter 作为整段字体"
Assert-True (-not $code.Contains('{ family: "Arial"')) "禁止使用依赖中文字形回退的 Arial"
Assert-True ($code.IndexOf('{ family: "Noto Sans SC"') -lt $code.IndexOf('{ family: "Microsoft YaHei"')) "Noto Sans SC 必须是首选字体"
Assert-True ($code.Contains('const INVENTORY_ITEM_WIDTH = 320')) "交互清单缺少紧凑宽度合同"
Assert-True ($code.Contains('const actualWidth = 36 + columns * INVENTORY_ITEM_WIDTH')) "交互清单仍可能无条件撑满可用宽度"
Assert-True ($code.Contains('const actualHeight = 82 + rows * INVENTORY_ROW_HEIGHT')) "交互清单仍使用固定空白高度"
Assert-True ($code.Contains('const boardWidth = 32 + CONTRACT_COLUMNS * CONTRACT_CARD_WIDTH')) "契约区仍无条件撑满整页宽度"
Assert-True ($code.Contains('const spec = contractFor(id)')) "可编辑控件未从同一契约事实源读取"
Assert-True ($code.Contains('setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids"')) "节点未写入 control-contract-ids"
Assert-True ($code.Contains('setSharedPluginData(OWNER_NAMESPACE, "control-contract"')) "节点未写入 control-contract"
Assert-True ($code.Contains('function validateGeneratedLayout(root)')) "缺少生成后布局/覆盖检查"
Assert-True (-not $code.Contains('function sha256Hex(bytes)')) "Figma 主线程不得维护自定义 SHA256 实现"
Assert-True (-not $code.Contains('crypto.subtle')) "Figma 主线程不得依赖浏览器 crypto 全局对象"
Assert-True (-not $template.Contains('window.crypto.subtle')) "Figma UI iframe 不得依赖当前宿主未提供的 Web Crypto"
Assert-True ($template.Contains('buildVerifiedSha256')) "UI iframe 未传递构建时素材完整性证明"
Assert-True ($code.Contains('metadata.buildVerifiedSha256 !== metadata.sha256')) "Figma 主线程未校验构建时素材完整性证明"
Assert-True ($code.Contains('let currentBuildStage = "等待开始"')) "缺少生成阶段诊断状态"
Assert-True ($code.Contains('生成失败（${currentBuildStage}）')) "运行错误未包含失败阶段"
foreach ($stage in @('05.01 根画布', '05.02 文档封面', '05.03 产品总览', '05.04 Mini', '05.05 今日工作台', '05.06 日历', '05.07 Wizard', '05.08 Settings', '05.09 系统边界', '05.10 Logo 素材留档')) {
    Assert-True ($code.Contains($stage)) "可编辑画布缺少细分诊断阶段：$stage"
}
Assert-True ($code.Contains('detail.split("\n").slice(0, 4).join("\n")')) "运行错误未向插件面板返回精简堆栈"
Assert-True ($code.Contains('const bg = frame(parent, `状态标签/${value}`')) "状态标签必须使用可承载文字子节点的 Frame"
Assert-True (-not $code.Contains('const bg = rect(parent, `状态标签/${value}`')) "状态标签不得把文字追加到 RectangleNode"
Assert-True ($code.Contains('function connector(parent')) "流程画布必须保留无箭头横向连线"
Assert-True (-not $code.Contains('text(parent, "→"')) "流程连线不得生成箭头符号"
Assert-True (-not $code.Contains('arrow(area,')) "业务区域不得残留流程箭头调用"
Assert-True (-not $code.Contains('pill(card, id,')) "流程卡不得显示黄色英文目标编号"
Assert-True ($code.Contains('target(frame(parent, `流程节点/${title}`')) "流程卡必须使用中文图层名并保留不可见跳转目标元数据"
Assert-True (-not $code.Contains('pill(card, spec.id')) "契约卡不得显示英文控件编号标签"
Assert-True (-not $code.Contains('pill(card, spec.kind')) "契约卡不得显示英文控件类型标签"
Assert-True (-not $code.Contains('pill(item, id.replace("LMM-B-", "B-")')) "交互清单不得显示英文控件编号标签"
foreach ($label in @('控件类型', '所在界面', '出现条件', '用户操作', '触发事件', '调用链路', '数据与状态', '用户可见结果', '失败与恢复', '取消 / 关闭', '去向 / 系统边界')) {
    Assert-True ($code.Contains($label)) "控件契约缺少详细字段：$label"
}
Assert-True ($code.Contains('function improveExistingContracts(assetPayload)')) "缺少保留手动画布的增量优化模式"
Assert-True ($code.Contains('message.type !== "improve-contracts"')) "插件消息入口未支持契约增量优化"
Assert-True ($template.Contains('增量优化现有画布（保留手动修改）')) "插件面板缺少非破坏性增量优化入口"
Assert-True ($template.Contains('完整重建 v1.0.8 设计')) "插件面板缺少明确的完整重建入口"
Assert-True ($code.Contains('labelNode.characters === oldLabel')) "契约增量优化未保护手动修改的字段标签"
Assert-True ($code.Contains('valueNode.characters === oldValue')) "契约增量优化未保护手动修改的字段内容"
Assert-True ($code.Contains('const contractY = 1200')) "Wizard 契约区仍保留异常大空白"
Assert-True ($code.Contains('function compactSectionContractGap(page, index)')) "缺少 Wizard 空白增量压缩器"
Assert-True ($code.Contains('function rebuildLogoArchiveSection(page)')) "缺少第 07 区 Logo 留档增量更新器"
Assert-True ($code.Contains('function localizeManagedLayerNames(page)')) "缺少旧受管图层菜单中文化迁移器"
Assert-True ($code.Contains('incremental-layer-language-version')) "受管图层菜单中文化版本未写入页面"
Assert-True ($code.Contains('name.startsWith("文本/")')) "增量更新未清理旧文本图层的“文本/”前缀"
Assert-True (-not $code.Contains('node.name = `文本/${summary}`')) "新建文本图层仍包含“文本/”前缀"
Assert-True ($code.Contains('中文化 ${result.localizedLayerNames} 个受管图层菜单')) "增量更新结果未报告中文化数量"
Assert-True ($code.Contains('function drawLogoArchive(parent, x, y)')) "缺少 Logo 素材留档画布"
Assert-True ($code.Contains('Logo 相关素材留档')) "第 07 区未更新为 Logo 素材留档"
Assert-True ($code.Contains('area.name = "07 / Logo 相关素材留档"')) "第 07 区图层名未使用简洁编号和主体标题"
Assert-True (-not $code.Contains('area.name = "第 07 区 / Logo 相关素材留档"')) "第 07 区图层名仍保留旧后缀"
Assert-True ($code.Contains('return `${String(sectionMatch[1]).padStart(2, "0")} / ${localizedSectionTitle(sectionMatch[2])}`')) "完整生成仍为区块图层名添加“第/区”冗余字样"
Assert-True ($code.Contains('name.match(/^第\s*(\d+)\s*区')) "增量更新未兼容 00-06 区已有的中文旧格式"
Assert-True ($code.Contains('return `${String(localizedSectionMatch[1]).padStart(2, "0")} / ${localizedSectionTitle(localizedSectionMatch[2])}`')) "增量更新不能将中文旧区块名收敛为简洁编号"
Assert-True (-not $code.Contains('"设计系统与交付边界"')) "第 07 区仍残留旧设计系统标题"
Assert-True (-not $code.Contains('function drawDesignSystem(')) "第 07 区仍使用旧设计系统生成器"
Assert-True ($template.Contains('type: "improve-contracts", assets: verifiedAssets')) "增量更新未携带已验证 Logo 素材"
Assert-True ($code.Contains('incremental-layout-version')) "增量布局版本未写入受管页面"
Assert-True ($code.Contains('拖动结束事件（dragCompleted）')) "技术事件未转换为中文业务说明"
Assert-True ($code.Contains('完成拖动并判断是否贴边（finalize_mini_drag）')) "调用链路未转换为中文业务说明"
foreach ($legacyNodeCall in @(
    'frame(root, "Document cover"',
    'frame(area, "Architecture boundaries"',
    'frame(parent, "Local control contracts"',
    'frame(parent, `Button/${label}`',
    'frame(parent, `Window/${title}`'
)) {
    Assert-True (-not $code.Contains($legacyNodeCall)) "完整生成仍使用英文图层名：$legacyNodeCall"
}

# 当前仅允许一张确定性 L2 品牌 PNG，运行截图为零。
$assetManifest = Get-Content -LiteralPath $assetManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($assetManifest.schema -eq "lmm-figma-static-assets/v2") "素材 manifest schema 错误"
Assert-True ($assetManifest.product_version -eq "v1.0.8") "素材 manifest 产品版本错误"
Assert-True ([int]$assetManifest.screenshot_assets -eq 0) "不得嵌入运行截图"
$assetNames = @($assetManifest.assets.PSObject.Properties.Name)
Assert-True ($assetNames.Count -eq 1 -and $assetNames[0] -eq 'appLogo') "产品素材必须只有 appLogo"
$metadata = $assetManifest.assets.appLogo
Assert-True ($metadata.role -eq "product-brand-mark") "L2 素材角色错误"
Assert-True (-not [bool]$metadata.runtime_screenshot) "L2 素材被误标为运行截图"
$assetPath = Join-Path $PluginRoot ([string]$metadata.output).Replace('/', '\')
Assert-True (Test-Path -LiteralPath $assetPath -PathType Leaf) "缺少 L2 PNG：$assetPath"
Assert-Png -Path $assetPath -Metadata $metadata
Assert-True (-not $ui.Contains('__ASSET_PAYLOAD_JSON__')) "ui.html 素材占位符未替换"
$uiPayloadMatch = [Regex]::Match($ui, 'const assets = (\{.*?\});', [Text.RegularExpressions.RegexOptions]::Singleline)
Assert-True ($uiPayloadMatch.Success) "ui.html 缺少嵌入素材载荷"
$uiPayload = $uiPayloadMatch.Groups[1].Value | ConvertFrom-Json
$uiLogo = $uiPayload.appLogo
Assert-True ([string]$uiLogo.sha256 -eq [string]$metadata.sha256) "ui.html 嵌入 SHA256 与素材 manifest 不一致"
$uiLogoBytes = [Convert]::FromBase64String([string]$uiLogo.base64)
Assert-True ($uiLogoBytes.Length -eq [int]$metadata.bytes) "ui.html 嵌入素材字节数不一致"
$uiLogoTemp = Join-Path ([IO.Path]::GetTempPath()) ("lmm-figma-logo-" + [Guid]::NewGuid().ToString("N") + ".png")
try {
    [IO.File]::WriteAllBytes($uiLogoTemp, $uiLogoBytes)
    Assert-True ((Get-FileSha256Lower $uiLogoTemp) -eq [string]$metadata.sha256) "ui.html 嵌入素材 SHA256 不一致"
}
finally {
    if (Test-Path -LiteralPath $uiLogoTemp) { Remove-Item -LiteralPath $uiLogoTemp -Force }
}

# 插件身份与面板文案。
Assert-True ($manifest.id -eq "1529485011316724739") "插件 ID 被意外修改"
Assert-True ($manifest.main -eq "code.js" -and $manifest.ui -eq "ui.html") "插件入口错误"
Assert-True ($template.Contains('LetsMakeMoney v1.0.8 产品全链路生成器')) "插件面板版本未更新或未中文化"
Assert-True ($template.Contains('LMM 01 产品全链路')) "插件面板未声明唯一管理页"
Assert-True ($manifest.name -eq 'LetsMakeMoney 产品全链路生成器') "插件菜单名称未中文化"
Assert-True ($template.Contains('不调用 Figma MCP')) "插件面板未声明本地插件边界"

# 重复构建必须确定性。
$firstUiHash = Get-FileSha256Lower $uiPath
$firstAssetHash = Get-FileSha256Lower $assetPath
$firstManifestHash = Get-FileSha256Lower $assetManifestPath
& powershell -NoProfile -ExecutionPolicy Bypass -File $buildPath -PluginRoot $PluginRoot | Out-Null
Assert-True ((Get-FileSha256Lower $uiPath) -eq $firstUiHash) "重复构建 ui.html 不确定"
Assert-True ((Get-FileSha256Lower $assetPath) -eq $firstAssetHash) "重复构建 appLogo.png 不确定"
Assert-True ((Get-FileSha256Lower $assetManifestPath) -eq $firstManifestHash) "重复构建素材 manifest 不确定"

# JavaScript、UTF-8、乱码和 Git diff。
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

Write-Host "Figma 插件静态验收通过"
Write-Host "- LMM 管理页面：1"
Write-Host "- v1.0.8 控件契约：$($contractIds.Count)"
Write-Host "- 确定性产品 PNG：1"
Write-Host "- v0.9 桌宠/Godot 当前合同：0"
Write-Host "- 页面所有权、非 LMM 保护、重复构建幂等：通过"
