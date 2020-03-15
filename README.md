# Powershell-QrCodeGenerator
QrCode Generator, mainly inspired by Nayuki's "QR-Code-generator", fully reimplemented in Powershell. No Wrapper.

## Samples :

### Load using :
```powershell
Import-Module .\PSQRCode.psm1
```

### Various QrCode :

#### Generated and stored for later use, or exporting
```powershell
$myQR = New-QrCode -text "GLD DEMO"
$myQR.toString()
$myQR.toSvgString(4) | Out-File ~\sample.svg ; Start-Process ~\sample.svg
```

#### returns only the QrCode as a string or SVG Content
```powershell
New-QrCode -text "GLD DEMO" -asString
New-QrCode -text "GLD DEMO" -asSvgString
```

#### Alphanumeric Mode
```powershell
New-QrCode -text "DOLLAR-AMOUNT:`$39.87 PERCENTAGE:100.00% OPERATIONS:+-*/" -asString
```

#### Binary/Unicode Mode
```powershell
New-QrCode -text ("" + ([char]0x3053) + ([char]0x3093) + ([char]0x306B) + ([char]0x3061) + ([char]0x0077) + ([char]0x0061) + ([char]0x3001) + ([char]0x4E16) + ([char]0x754C) + ([char]0xFF01) + ([char]0x0020) + ([char]0x03B1) + ([char]0x03B2) + ([char]0x03B3) + ([char]0x03B4)) -asString
```

#### Kanji
```powershell
$bitBuff = New-QrBitBuffer "1000000000010011111100000001010111011010101011010111"
$qrseg = New-QrSegment -Type KANJI -KanjiData $bitBuff
New-QrCode -segments $qrseg -asString
```

#### with parameters
```powershell
New-QrCode -text "https:\\duval.paris" -minimumEcc MEDIUM -disalowEccUpgrade -asString
```

#### Multi-typed segment Demo
```powershell
$strGolden0 = "Golden ratio " + ([char]0x03C6) + " = 1."
$strGolden1 = "6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374"
$strGolden2 = "......"

Write-output "Long, unoptimised version"
New-QrCode -text ($strGolden0 + $strGolden1 + $strGolden2) -minimumEcc LOW -asString

$tmpSegs = @()
$tmpSegs += New-QrSegment -Type BYTE -StringData $strGolden0
$tmpSegs += New-QrSegment -Type NUMERIC -StringData $strGolden1
$tmpSegs += New-QrSegment -Type ALPHANUMERIC -StringData $strGolden2
Write-output "Optimised Multi-typed Version"
New-QrCode -segments $tmpSegs -minimumEcc LOW -asString

$tmpSegs = @()
$tmpSegs += New-QrSegment -StringData $strGolden0
$tmpSegs += New-QrSegment -StringData $strGolden1
$tmpSegs += New-QrSegment -StringData $strGolden2
Write-output "Same Optimised Multi-typed Version using auto-detection"
New-QrCode -segments $tmpSegs -minimumEcc LOW -asString
```

#### ECI Demo
```powershell
$tmpSegs = @()
$tmpSegs += New-QrSegment -type ECI -EciType 26 # UTF8 Encoding marker
$tmpSegs += New-QrSegment -type BYTE -StringData ("" + ([char]0x3053) + ([char]0x3093) + ([char]0x306B) + ([char]0x3061))
Write-output "Appropriate encoding, should display japanese characters"
New-QrCode -segments $tmpSegs -minimumEcc LOW -asString

$tmpSegs = @()
$tmpSegs += New-QrSegment -type ECI -EciType 3 # ISO/IEC 8859-1 Latin alphabet No. 1
$tmpSegs += New-QrSegment -type BYTE -StringData ("" + ([char]0x3053) + ([char]0x3093) + ([char]0x306B) + ([char]0x3061))
Write-output "Not the right encoding, but same payload, should display garbled characters"
Write-output "Some readers ignore ECI flags, iPhone integrated reader seems to abide them"
New-QrCode -segments $tmpSegs -minimumEcc LOW -asString
```

#### Huge QrCode straight to an SVG File
```powershell
New-QrCode -text "Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, 'and what is the use of a book,' thought Alice 'without pictures or conversations?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her." -minimumEcc HIGH -asSvgString | Out-File ~\sample.svg ; Start-Process ~\sample.svg
```
