function Get-AppConfiguration {
    $flutterDir = Resolve-Path "$PSScriptRoot\..\.." | Select-Object -ExpandProperty Path
    $envPath = Join-Path $flutterDir ".env"

    if (-not (Test-Path $envPath)) {
        Write-Error "Configuration file not found at: $envPath"
        exit 1
    }

    $config = @{}

    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()

        # Ignore empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            return
        }

        # Split on the first equals sign
        $parts = $line -split '=', 2
        if ($parts.Length -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()

            # Trim surrounding single or double quotes
            if ($value -match "^['`"](.*)['`"]$") {
                $value = $matches[1]
            }

            $config[$key] = $value
        }
    }

    $url = $config['SUPABASE_URL']
    $key = $config['SUPABASE_PUBLISHABLE_KEY']

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Error "Invalid configuration: SUPABASE_URL is missing or empty."
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($key)) {
        Write-Error "Invalid configuration: SUPABASE_PUBLISHABLE_KEY is missing or empty."
        exit 1
    }

    return $config
}
