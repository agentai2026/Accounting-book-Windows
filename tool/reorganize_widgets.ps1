# 一次性脚本：widgets 分子目录 + 修正 import
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$base = Join-Path $root 'lib\desktop\widgets'

$map = @{
  layout        = @('app_shell','sidebar','desktop_shell','content_panel','page_header','page_placeholder')
  common        = @('empty_state','app_card','search_bar','stat_card','chart_card','ez_branded_dialog','data_table')
  charts        = @('budget_ring','statistics_charts','category_pie_chart','income_expense_trend_chart','yearly_trend_chart')
  exchange_rate = @('exchange_rate_panel','exchange_rate_sparkline_chart')
  home          = @('home_dashboard_widgets','home_overview_widgets')
  statistics    = @('statistics_dashboard_widgets','statistics_account_panel')
  forms         = @('account_form_dialog','book_form_dialog','budget_form_dialog','category_form_dialog','loan_form_dialog','scheduled_transaction_form_dialog','tag_form_dialog','default_accounts_dialog','default_categories_dialog')
  account       = @('account_selector','account_list_panel','account_picker_panels')
  category      = @('category_list_panel','category_selector','category_picker_panels')
  transaction   = @('add_transaction_dialog','add_transaction_pickers','add_transaction_tag_field','amount_input','transaction_album_view','transaction_calendar_view','transaction_detail_dialog','transaction_form','transaction_grouped_list','transaction_image_preview','transaction_page_widgets','transaction_data_table','transaction_datetime_picker_panel','transaction_add_menu_button','date_range_picker','timezone_picker_panel')
  dialogs       = @('ai_image_recognition_dialog','alipay_import_reconcile_dialog','transaction_import_dialog')
}

$replacements = @{}
foreach ($subdir in $map.Keys) {
  $dir = Join-Path $base $subdir
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  foreach ($name in $map[$subdir]) {
    $src = Join-Path $base "$name.dart"
    $dst = Join-Path $dir "$name.dart"
    if (Test-Path -LiteralPath $src) {
      Move-Item -LiteralPath $src -Destination $dst -Force
      $replacements["desktop/widgets/$name.dart"] = "desktop/widgets/$subdir/$name.dart"
    }
  }
}

$libDir = Join-Path $root 'lib'
$dartFiles = Get-ChildItem -Path $libDir -Recurse -Filter '*.dart'
foreach ($file in $dartFiles) {
  $content = [System.IO.File]::ReadAllText($file.FullName)
  $original = $content
  foreach ($old in ($replacements.Keys | Sort-Object { $_.Length } -Descending)) {
    $content = $content.Replace($old, $replacements[$old])
  }
  if ($content -ne $original) {
    [System.IO.File]::WriteAllText($file.FullName, $content)
  }
}

Write-Host "Moved $($replacements.Count) widget files and updated imports."
