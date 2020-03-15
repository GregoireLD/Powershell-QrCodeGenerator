# Powershell-QrCodeGenerator
QrCode Generator, mainly inspired by Nayuki's "QR-Code-generator", fully reimplemented in Powershell. No Wrapper.

## Samples :

### Load using :
```powershell
Import-Module .\PSQRCode.psm1
```

### Various QrCode :

#### not showing, stored for later use
```powershell
$myQR = New-QrCode -text "GLD DEMO"
```

#### directly drawn
```powershell
(New-QrCode -text "GLD DEMO").toString()
```

#### Alphanumeric Mode
```powershell
(New-QrCode -text "DOLLAR-AMOUNT:`$39.87 PERCENTAGE:100.00% OPERATIONS:+-*/").toString()
```

#### Binary/Unicode Mode
```powershell
(New-QrCode -text ("" + ([char]0x3053) + ([char]0x3093) + ([char]0x306B) + ([char]0x3061) + ([char]0x0077) + ([char]0x0061) + ([char]0x3001) + ([char]0x4E16) + ([char]0x754C) + ([char]0xFF01) + ([char]0x0020) + ([char]0x03B1) + ([char]0x03B2) + ([char]0x03B3) + ([char]0x03B4))).toString()
```

#### Kanji
```powershell
$bitBuff = New-QrBitBuffer "00000001101011000000000010011111100000001010111011010101011010111"
$qrseg = New-QrSegment -Type KANJI -KanjiData $bitBuff
(New-QrCode -segments $qrseg).toString()
```

#### with parameters
```powershell
(New-QrCode -text "https:\\duval.paris" -minimumEcc MEDIUM -disalowEccUpgrade).toString()
```

#### multi-typed segment Demo (Partial Support)
```powershell
$strGolden0 = "Golden ratio + " + ([char]0x03C6) + " = 1."
$strGolden1 = "6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374"
$strGolden2 = "......"

(New-QrCode -text ($strGolden0 + $strGolden1 + $strGolden2) -minimumEcc LOW).toString()

$tmpSegs = @()
$tmpSegs += New-QrSegment -Type BYTE -StringData $strGolden0
$tmpSegs += New-QrSegment -Type NUMERIC -StringData $strGolden1
$tmpSegs += New-QrSegment -Type ALPHANUMERIC -StringData $strGolden2
(New-QrCode -segments $tmpSegs -minimumEcc LOW).toString()
```

#### ECI Demo (Partial Support)
```powershell
# ToDo
```

#### Huge QrCode
```powershell
(New-QrCode -text "Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, 'and what is the use of a book,' thought Alice 'without pictures or conversations?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her." -minimumEcc MEDIUM).toString()
```
