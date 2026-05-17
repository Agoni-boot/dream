$ErrorActionPreference = "Stop"

$root = "D:\TRAE\TR\project01"
$prefix = "http://127.0.0.1:8123/"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Static server running at $prefix"

$contentTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()
    $requestPath = $context.Request.Url.AbsolutePath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($requestPath)) {
      $requestPath = "aviation_dream_bottle.html"
    }

    $safePath = $requestPath.Replace("/", "\")
    $filePath = Join-Path $root $safePath

    if (-not (Test-Path $filePath -PathType Leaf)) {
      $context.Response.StatusCode = 404
      $bytes = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $context.Response.Close()
      continue
    }

    $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
    if ($contentTypes.ContainsKey($extension)) {
      $context.Response.ContentType = $contentTypes[$extension]
    }

    $buffer = [System.IO.File]::ReadAllBytes($filePath)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.OutputStream.Close()
  } catch {
    if ($context -and $context.Response) {
      $context.Response.StatusCode = 500
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($_.Exception.Message)
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $context.Response.Close()
    }
  }
}
