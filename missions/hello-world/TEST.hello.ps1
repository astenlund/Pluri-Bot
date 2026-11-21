# The hello-world mission's sample test: it passes when the package it was started for exists.
$package = $env:DLSS5_TEST_PACKAGE_PATH
if ([string]::IsNullOrEmpty($package) -or -not (Test-Path -LiteralPath $package -PathType Leaf)) {
    Write-Output 'The package path is missing or does not name a file.'
    exit 1
}
Write-Output ('Hello from the test ' + $env:DLSS5_TEST_NAME + ' at a ' + $env:DLSS5_TEST_ROLE + ' location.')
exit 0
