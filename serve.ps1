$ErrorActionPreference = 'Stop'
$root = (Resolve-Path $PSScriptRoot).Path
$prefix = 'http://127.0.0.1:8000/'
$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm' = 'text/html; charset=utf-8'
  '.css' = 'text/css; charset=utf-8'
  '.js' = 'text/javascript; charset=utf-8'
  '.mjs' = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.svg' = 'image/svg+xml'
  '.png' = 'image/png'
  '.jpg' = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.webp' = 'image/webp'
  '.ico' = 'image/x-icon'
  '.webmanifest' = 'application/manifest+json'
  '.txt' = 'text/plain; charset=utf-8'
  '.woff' = 'font/woff'
  '.woff2' = 'font/woff2'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try { $listener.Start() } catch {
  Write-Host "Could not start the local server on port 8000." -ForegroundColor Red
  Write-Host "Close any other server using port 8000, then try again."
  Read-Host 'Press Enter to close'
  exit 1
}
Write-Host "ENSTP Campus Navigator is running at $prefix" -ForegroundColor Green
Write-Host 'Keep this window open while using the website. Press Ctrl+C to stop.'
Start-Process $prefix
while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()
    $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
    $relative = $relative.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $file = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
      $context.Response.StatusCode = 403
      $bytes = [Text.Encoding]::UTF8.GetBytes('Forbidden')
    } elseif ((Test-Path -LiteralPath $file -PathType Leaf)) {
      $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
      if ($mime.ContainsKey($ext)) { $context.Response.ContentType = $mime[$ext] } else { $context.Response.ContentType = 'application/octet-stream' }
      $bytes = [IO.File]::ReadAllBytes($file)
      $context.Response.StatusCode = 200
    } else {
      $context.Response.StatusCode = 404
      $bytes = [Text.Encoding]::UTF8.GetBytes('404 - File not found')
    }
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.OutputStream.Close()
  } catch {
    # Continue serving requests if a browser closes a connection unexpectedly.
  }
}
