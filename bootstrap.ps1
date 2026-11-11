# Run from repo root:  .\bootstrap.ps1
$ErrorActionPreference = "Stop"
$pkgs = @(
  "packages/rxflare_core",
  "packages/rxflare_router",
  "packages/rxflare_i18n",
  "packages/rxflare"
)
foreach ($p in $pkgs) {
  Write-Host "=== pub get $p ===" -ForegroundColor Cyan
  Push-Location $p
  flutter pub get
  Pop-Location
}
Write-Host "=== analyze + test core ===" -ForegroundColor Cyan
Push-Location packages/rxflare_core
flutter analyze
flutter test
Pop-Location
Write-Host "Done. For umbrella: cd packages/rxflare; flutter analyze" -ForegroundColor Green
