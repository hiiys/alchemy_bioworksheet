# PowerShell script to convert Markdown to DOCX
# Firebase Implementation Work Plan Converter

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MARKDOWN TO DOCX CONVERTER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$markdownFile = "FIREBASE_IMPLEMENTATION_WORKPLAN.md"
$outputFile = "FIREBASE_WORKPLAN.docx"

# Check if markdown file exists
if (-not (Test-Path $markdownFile)) {
    Write-Host "ERROR: Could not find $markdownFile" -ForegroundColor Red
    Write-Host "Please run this script in the same directory as the markdown file." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found markdown file: $markdownFile" -ForegroundColor Green
Write-Host ""

# Method 1: Try Pandoc (best quality)
Write-Host "Checking for Pandoc..." -ForegroundColor Yellow

$pandocInstalled = $null
try {
    $pandocInstalled = Get-Command pandoc -ErrorAction SilentlyContinue
} catch {
    $pandocInstalled = $null
}

if ($pandocInstalled) {
    Write-Host "✓ Pandoc found! Using Pandoc for conversion..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Converting with table of contents..." -ForegroundColor Cyan

    try {
        pandoc $markdownFile -o $outputFile --toc --toc-depth=3 `
            --highlight-style=tango `
            --reference-doc=reference.docx `
            -V geometry:margin=1in

        if (Test-Path $outputFile) {
            Write-Host ""
            Write-Host "✓ SUCCESS! Document converted successfully!" -ForegroundColor Green
            Write-Host "Output file: $outputFile" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Opening document..." -ForegroundColor Yellow
            Start-Process $outputFile
            Write-Host ""
            Write-Host "Done! You can now print the document from Word." -ForegroundColor Green
        } else {
            throw "Conversion failed - output file not created"
        }
    } catch {
        Write-Host "ERROR: Pandoc conversion failed: $_" -ForegroundColor Red
        Write-Host "Trying alternative method..." -ForegroundColor Yellow
        $pandocInstalled = $null
    }
}

# Method 2: Try Microsoft Word COM object
if (-not $pandocInstalled) {
    Write-Host "Pandoc not found. Trying Microsoft Word..." -ForegroundColor Yellow

    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false

        Write-Host "✓ Microsoft Word found!" -ForegroundColor Green
        Write-Host "Converting document..." -ForegroundColor Cyan

        $fullPath = (Resolve-Path $markdownFile).Path
        $outputPath = Join-Path (Get-Location) $outputFile

        # Open markdown file
        $doc = $word.Documents.Open($fullPath)

        # Save as DOCX
        $wdFormatDocumentDefault = 16
        $doc.SaveAs([ref]$outputPath, [ref]$wdFormatDocumentDefault)
        $doc.Close()
        $word.Quit()

        # Release COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        if (Test-Path $outputFile) {
            Write-Host ""
            Write-Host "✓ SUCCESS! Document converted successfully!" -ForegroundColor Green
            Write-Host "Output file: $outputFile" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Opening document..." -ForegroundColor Yellow
            Start-Process $outputFile
            Write-Host ""
            Write-Host "Note: You may need to apply formatting (headings, etc.) manually." -ForegroundColor Yellow
        }

    } catch {
        Write-Host "ERROR: Word conversion failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "MANUAL CONVERSION INSTRUCTIONS:" -ForegroundColor Yellow
        Write-Host "================================" -ForegroundColor Yellow
        Write-Host "1. Open Microsoft Word" -ForegroundColor White
        Write-Host "2. File → Open" -ForegroundColor White
        Write-Host "3. Navigate to: $(Get-Location)" -ForegroundColor White
        Write-Host "4. Change filter to 'All Files (*.*)'" -ForegroundColor White
        Write-Host "5. Select: $markdownFile" -ForegroundColor White
        Write-Host "6. Click Open" -ForegroundColor White
        Write-Host "7. File → Save As → Choose '.docx' format" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "If automatic conversion failed, you can:" -ForegroundColor Yellow
Write-Host "1. Install Pandoc: https://pandoc.org/installing.html" -ForegroundColor White
Write-Host "   Then run this script again" -ForegroundColor White
Write-Host "2. Use online converter: https://cloudconvert.com/md-to-docx" -ForegroundColor White
Write-Host "3. Open the .md file directly in Microsoft Word" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "`nPress Enter to exit"
