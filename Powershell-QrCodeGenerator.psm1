#region Enumerations
enum EccEnum{
    LOW = 1
    MEDIUM = 0
    QUARTILE = 3
    HIGH = 2
}

enum ModeEnum{
	NUMERIC      = 0
	ALPHANUMERIC = 1
	BYTE         = 2
	KANJI        = 3
	ECI          = 4
}
#endregion Enumerations


#region Classes
class Ecc{

	# Must be declared in ascending order of error protection
	# so that the implicit getEccOrdinal and getEccValue work properly

	#                                                               NAME | Ecc Value | Ordinal Value
	# The QR Code can tolerate about  7% erroneous codewords ->      LOW =     1           0
	# The QR Code can tolerate about 15% erroneous codewords ->   MEDIUM =     0           1
	# The QR Code can tolerate about 25% erroneous codewords -> QUARTILE =     3           2
	# The QR Code can tolerate about 30% erroneous codewords ->     HIGH =     2           3

	hidden [EccEnum] $internalEcl

    [int] getEccValue(){
        [int] $tmpEcl = 1 # LOW

        switch ($this.internalEcl) {
            "HIGH" { $tmpEcl = 2 }
            "QUARTILE" { $tmpEcl = 3 }
            "MEDIUM" { $tmpEcl = 0 }
            # LOW
        }
        return $tmpEcl
    }

    [int] getEccOrdinal(){
        [int] $tmpEcl = 0 # LOW

        switch ($this.internalEcl) {
            "HIGH" { $tmpEcl = 3 }
            "QUARTILE" { $tmpEcl = 2 }
            "MEDIUM" { $tmpEcl = 1 }
            # LOW
        }
        return $tmpEcl
    }

    [Ecc] getHigherEcc(){
        [Ecc] $tmpEcl = New-Object 'Ecc' 1

        switch ($this.internalEcl) {
            "LOW" { $tmpEcl.setEccValue(0) }
            "MEDIUM" { $tmpEcl.setEccValue(3) }
            "QUARTILE" { $tmpEcl.setEccValue(2) }
            Default {
                throw "getHigherEcc was called on a already HIGH Ecc"
            }
        }
        return $tmpEcl
    }

    [Ecc] getLowerEcc(){
        [Ecc] $tmpEcl = New-Object 'Ecc' 1

        switch ($this.internalEcl) {
            "HIGH" { $tmpEcl.setEccValue(3)}
            "QUARTILE" { $tmpEcl.setEccValue(0) }
            "MEDIUM" { $tmpEcl.setEccValue(1) }
            Default {
                throw "getLowerEcc was called on a already LOW Ecc"
            }
        }
        return $tmpEcl
    }

    [bool] isMax(){
        if ($this.internalEcl -eq [EccEnum]::HIGH) {
            return $true
        }
        return $false
    }

    [bool] isMin(){
        if ($this.internalEcl -eq [EccEnum]::LOW) {
            return $true
        }
        return $false
	}
	
	setEccValue([int] $val){
		$this.internalEcl = $val
	}

	setEccValue([Ecc] $val){
		$this.setEccValue($val.getEccValue())
	}

	Ecc(){
		$this.internalEcl = 0
	}
	
	Ecc([int] $val){
		$this.internalEcl = $val
	}

	Ecc([Ecc] $val){
		$this.internalEcl = $val.getEccValue()
	}

	Ecc([string] $val){

		switch ($val) {
            "LOW" { $this.internalEcl = "LOW" }
            "QUARTILE" { $this.internalEcl = "QUARTILE" }
			"MEDIUM" { $this.internalEcl = "MEDIUM" }
			"HIGH" { $this.internalEcl = "HIGH" }
            Default {
                throw "Invalid ECC String"
            }
        }
	}

	static [Ecc] LOW()      {return New-Object 'Ecc' 1}
	static [Ecc] MEDIUM()   {return New-Object 'Ecc' 0}
	static [Ecc] QUARTILE() {return New-Object 'Ecc' 3}
	static [Ecc] HIGH()     {return New-Object 'Ecc' 2}
}

# Describes how a segment's data bits are interpreted.
class QrMode{
	# -- Fields --
	
	# The mode indicator bits, which is a uint4 value (range 0 to 15).
	[int] $modeBits
	
	# Number of character count bits for three different version ranges.
	hidden [int[]] $numBitsCharCount
		
		
	# -- Constructor --
		
	hidden QrMode([int] $qrmode, [int[]] $ccbits)
	{
		$this.modeBits = $qrmode
		$this.numBitsCharCount = $ccbits
	}
	
	QrMode([string] $qrmode){

		switch ($qrmode) {
            "NUMERIC" { $this.modeBits = 0x1 ; $this.numBitsCharCount = @( 10, 12, 14) }
            "ALPHANUMERIC" { $this.modeBits = 0x2 ; $this.numBitsCharCount = @(  9, 11, 13) }
			"BYTE" { $this.modeBits = 0x3 ; $this.numBitsCharCount = @(  8, 16, 16) }
			"KANJI" { $this.modeBits = 0x8 ; $this.numBitsCharCount = @(  8, 10, 12) }
			"ECI" { $this.modeBits = 0x7 ; $this.numBitsCharCount = @(  0,  0,  0) }
            Default {
                throw "Invalid QrMode String"
            }
        }
	}
	
	
	# -- Method --

	static [QrMode] NUMERIC()      {return New-Object 'QrMode' 0x1,@( 10, 12, 14)}
	static [QrMode] ALPHANUMERIC() {return New-Object 'QrMode' 0x2,@(  9, 11, 13)}
	static [QrMode] BYTE()         {return New-Object 'QrMode' 0x4,@(  8, 16, 16)}
	static [QrMode] KANJI()        {return New-Object 'QrMode' 0x8,@(  8, 10, 12)}
	static [QrMode] ECI()          {return New-Object 'QrMode' 0x7,@(  0,  0,  0)}

	# Returns the bit width of the character count field for a segment in this mode
	# in a QR Code at the given version number. The result is in the range [0, 16].
	[int] numCharCountBits([int] $ver)
	{
		if (([QrCode]::MIN_VERSION -gt $ver) -or ($ver -gt [QrCode]::MAX_VERSION))
        {
			throw "Version is not a valid value. It must range from "+[QrCode]::MIN_VERSION+" to "+[QrCode]::MAX_VERSION
        }
		return $this.numBitsCharCount[[Math]::truncate(($ver + 7) / 17)]
	}
}

class QrBitBuffer {
	# ---- Fields ----

	hidden [string] $data
	hidden [int] $bitLength # Non-negative

	# ---- Constructor ----

	# Constructs an empty bit buffer (length 0).
	QrBitBuffer()
	{
		$this.data = ""
		$this.bitLength = 0
	}

	QrBitBuffer([int] $size)
	{
		$this.data = ""
		$this.bitLength = 0

		for ($i = 0; $i -lt $size; $i++) {
			$this.data += "0"
			$this.bitLength += 1
		}
	}
	
	QrBitBuffer([string] $binaryString)
	{
		if (-not($binaryString -match [QrCode]::BINARY_REGEX))
		{
			throw "binaryString to use is not a binary string"
		}

		$this.data = $binaryString
		$this.bitLength = $binaryString.Length
	}
	
	
	# ---- Methods ----
	
	# Returns the length of this sequence, which is a non-negative value.
	# @return the length of this sequence
	[int] getBitLength()
	{
		if($this.bitLength -lt 0)
		{
			throw "Negative BitLength ("+$this.bitLength+") Reached"
		}
		return $this.bitLength
	}
	
	
	# Returns the bit at the specified index, yielding 0 or 1.
	# @param index the index to get the bit at
	# @return the bit at the specified index
	# @throws IndexOutOfBoundsException if index &lt; 0 or index &#x2265; bitLength
	[int] getBit([int] $index)
	{
		if (($index -lt 0) -or ($index -ge $this.bitLength))
		{
			throw "Requested Bit ("+$index+") is out of range (from 0 to "+$this.bitLength+")"
		}
		$retVal = 0
		if($this.data[$index] -eq "1"){$retVal = 1}
		return $retVal
	}
	
	[int] getByte([int] $index)
	{
		return [Convert]::ToByte([Convert]::ToInt16($this.data.Substring($index*8,8),2))
	}

	[int] getBigEndianByte([int] $index)
	{
		[string] $tmpString = $this.data.Substring($index*8,8)
		[string] $tmpReverseString = $tmpString[7]+$tmpString[6]+$tmpString[5]+$tmpString[4]+$tmpString[3]+$tmpString[2]+$tmpString[1]+$tmpString[0]

		return [Convert]::ToByte([Convert]::ToInt16($tmpReverseString,2))
	}

	setBit([int] $index,[int] $val)
	{
		[char] $insert = "0"

		if ($val)
		{
			$insert = "1"
		}

		[string] $orig = $this.data

		[string] $new = $orig.Substring(0,$val) + $insert + $orig.Substring($val+1,$orig.Length-1)

		$this.data = $new
	}

	[byte[]] toBytes()
	{
		[int] $oversize = $this.bitLength % 8
		[int] $stopBeforeEnd = 0
		[int] $arraySize = [math]::Truncate($this.bitLength / 8)
		if($oversize)
		{
			$stopBeforeEnd = 1
		}
		[byte[]] $byteArray = New-Object 'byte[]' $arraySize

		for ($i = 0; $i -lt ($arraySize - $stopBeforeEnd); $i++)
		{
			$byteArray[$i] = $this.getByte($i)
		}

		if($oversize)
		{
			[string] $zeroes = ""
			for($j = 0 ; $j -lt (8-$oversize) ; $j++)
			{
				$zeroes = $zeroes + "0"
			}
			$byteArray[3] = [Convert]::ToByte([Convert]::ToInt16($this.data.Substring(($arraySize-1)*8,$oversize)+""+$zeroes,2))
		}
		return $byteArray
	}

	[string] toString()
	{
		return $this.data
	}
	
	# Appends the specified number of low-order bits of the specified value to this
	# buffer. Requires 0 &#x2264; len &#x2264; 31 and 0 &#x2264; val &lt; 2<sup>len</sup>.
	# @param val the value to append
	# @param len the number of low-order bits in the value to take
	# @throws IllegalArgumentException if the value or number of bits is out of range
	# @throws IllegalStateException if appending the data
	# would make bitLength exceed Integer.MAX_VALUE
	appendBits([int] $val, [int] $len)
	{
		if ((($len -lt 0) -or ($len -gt 31) -or ($val -shr $len)) -ne 0)
		{
			throw "len ("+$len+") is out of range or val can't fit in len bit"
		}
		if (([int]::MaxValue - $this.bitLength) -lt $len)
		{
			throw "Maximum bitLength length reached when appending bits"
		}
		if($len -eq 0){return}
		# for (int i = len - 1; i >= 0; i--, bitLength++)  // Append bit by bit
		# 	data.set(bitLength, QrCode.getBit(val, i));
		$this.data += [Convert]::ToString($val, 2).PadLeft($len, '0')
		$this.bitLength += $len
	}
	
	
	# Appends the content of the specified bit buffer to this buffer.
	# @param bb the bit buffer whose data to append (not {@code null})
	# @throws NullPointerException if the bit buffer is {@code null}
	# @throws IllegalStateException if appending the data
	# would make bitLength exceed Integer.MAX_VALUE
	appendData([QrBitBuffer] $bb)
	{
		if (-not $bb)
        {
            throw "bb to append is null"
        }
		if (([int]::MaxValue - $this.bitLength) -lt $bb.getBitLength())
		{
			throw "Maximum bitLength length reached when appending data"
		}
		$tmpStr = $bb.ToString()

		$this.data += $tmpStr
		$this.bitLength += $tmpStr.Length

	}
	
	appendBinaryString([string] $binStr)
	{
		if (-not $binStr)
        {
            throw "binStr to append is null"
        }
		if (-not($binStr -match [QrCode]::BINARY_REGEX))
		{
			throw "binStr to append is not a binary string"
		}
		$this.data += $binStr
		$this.bitLength += $binStr.Length
	}
	
	# Returns a new copy of this buffer.
	# @return a new copy of this buffer (not {@code null})
	[QrBitBuffer] clone()
	{
		[QrBitBuffer] $tmpBb = New-Object 'QrBitBuffer'
		$tmpBb.appendData($this)
		return ($tmpBb)
	}

}

class QrSegment {
	# ---- Static factory functions (mid level) ----
	
	# Returns a segment representing the specified binary data
	# encoded in byte mode. All input byte arrays are acceptable.
	# <p>Any text string can be converted to UTF-8 bytes ({@code
	# s.getBytes(StandardCharsets.UTF_8)}) and encoded as a byte mode segment.</p>
	# @param data the binary data (not {@code null})
	# @return a segment (not {@code null}) containing the data
	# @throws NullPointerException if the array is {@code null}
	static [QrSegment] makeBytes([byte[]] $data)
	{
		if (-not $data)
        {
            throw "data (Bytes) to forge segment is null"
		}
		[QrBitBuffer] $bb = New-Object 'QrBitBuffer'
		foreach ($b in $data) {
			$bb.appendBits($b -band 0xFF,8)
		}

		return (New-Object 'QrSegment' ([QrMode]::BYTE()),$data.Length,$bb )
	}
	
	
	# Returns a segment representing the specified string of decimal digits encoded in numeric mode.
	# @param digits the text (not {@code null}), with only digits from 0 to 9 allowed
	# @return a segment (not {@code null}) containing the text
	# @throws NullPointerException if the string is {@code null}
	# @throws IllegalArgumentException if the string contains non-digit characters
	static [QrSegment] makeNumeric([String] $digits)
	{
		if (-not $digits)
        {
            throw "digits (String) to forge segment is null"
		}
		if (-not ($digits -match [QrCode]::NUMERIC_REGEX)){
            throw "digits to forge segment from is not a digital string"
		}

		[QrBitBuffer] $bb = New-Object 'QrBitBuffer'
		for ([int] $i = 0; $i -lt $digits.length; ) # Consume up to 3 digits per iteration
		{
			[int] $n = [Math]::Min($digits.length - $i, 3)
			$bb.appendBits([int]::Parse($digits.Substring($i,$n)), ($n * 3) + 1)
			$i += $n
		}
		return (New-Object 'QrSegment' ([QrMode]::NUMERIC()), $digits.length , $bb)
	}
	
	
	# Returns a segment representing the specified text string encoded in alphanumeric mode.
	# The characters allowed are: 0 to 9, A to Z (uppercase only), space,
	# dollar, percent, asterisk, plus, hyphen, period, slash, colon.
	# @param text the text (not {@code null}), with only certain characters allowed
	# @return a segment (not {@code null}) containing the text
	# @throws NullPointerException if the string is {@code null}
	# @throws IllegalArgumentException if the string contains non-encodable characters
	static [QrSegment] makeAlphanumeric([String] $text)
	{
		if (-not $text)
        {
            throw "text (String) to forge segment is null"
		}
		
		if ( -not ( $text -cmatch [QrCode]::ALPHANUMERIC_REGEX))
		{
			throw "text (String) to forge segment from contains illegal characters"
		}
		
		[QrBitBuffer] $bb = New-Object 'QrBitBuffer'
		[int] $i = 0 # needed here for global persistance
		for ($i = 0; $i -le ($text.length - 2); $i += 2) # Process groups of 2
		{
			[int] $temp = [QrCode]::ALPHANUMERIC_CHARSET.IndexOf($text[$i]) * 45
			$temp += [QrCode]::ALPHANUMERIC_CHARSET.IndexOf($text[$i+1])
			$bb.appendBits($temp, 11)
		}
		
		if ($i -lt $text.length) # 1 character remaining
		{
			$bb.appendBits([QrCode]::ALPHANUMERIC_CHARSET.IndexOf($text[$i]), 6)
		}
		
		return (New-Object 'QrSegment' ([QrMode]::ALPHANUMERIC()), $text.length , $bb)
	}
	
	
	# Returns a list of zero or more segments to represent the specified Unicode text string.
	# The result may use various segment modes and switch modes to optimize the length of the bit stream.
	# @param text the text to be encoded, which can be any Unicode string
	# @return a new mutable list (not {@code null}) of segments (not {@code null}) containing the text
	# @throws NullPointerException if the text is {@code null}
	static [QrSegment[]] makeSegments([String] $text)
	{
		if (-not $text)
        {
            throw "text (String) to forge generic segment is null"
		}
		
		# Select the most efficient segment encoding automatically
		[QrSegment[]] $result = @()
		if ($text.equals(""))
		{
			#Leave result empty
		}
		elseif ($text -match [QrCode]::NUMERIC_REGEX )
		{
			$result += ([QrSegment]::makeNumeric($text))
		}
		elseif ($text -cmatch [QrCode]::ALPHANUMERIC_REGEX )
		{
			$result += ([QrSegment]::makeAlphanumeric($text))
		}
		else
		{
			$enc = [system.Text.Encoding]::UTF8
			$bytes = $enc.GetBytes($text)
			$result += ([QrSegment]::makeBytes($bytes))
		}
		return $result
	}
	
	
	# Returns a segment representing an Extended Channel Interpretation
	# (ECI) designator with the specified assignment value.
	# @param assignVal the ECI assignment number (see the AIM ECI specification)
	# @return a segment (not {@code null}) containing the data
	# @throws IllegalArgumentException if the value is outside the range [0, 10<sup>6</sup>)
	static [QrSegment] makeEci([int] $assignVal)
	{
		[QrBitBuffer] $bb = New-Object 'QrBitBuffer'
		
		if ($assignVal -lt 0)
		{
			throw "ECI assignment value out of range"
		}
		elseif ($assignVal -lt (1 -shl 7))
		{
			$bb.appendBits($assignVal, 8)
		}
		elseif ($assignVal -lt (1 -shl 14))
		{
			$bb.appendBits(2, 2)
			$bb.appendBits($assignVal, 14)
		}
		elseif ($assignVal -lt 1000000)
		{
			$bb.appendBits(6, 3)
			$bb.appendBits($assignVal, 21)
		}
		else
		{
			throw "ECI assignment value out of range"
		}
		
		return New-Object 'QrSegment' ([QrMode]::ECI()), 0, $bb
	}
	
	
	
	# ---- Instance fields ----
	
	# The mode indicator of this segment. Not {@code null}. */
	[QrMode] $qrmode
	
	# The length of this segment's unencoded data. Measured in characters for
	# numeric/alphanumeric/kanji mode, bytes for byte mode, and 0 for ECI mode.
	# Always zero or positive. Not the same as the data's bit length. */
	[int] $numChars
	
	# The data bits of this segment. Not null. Accessed through getData().
	hidden [QrBitBuffer] $data
	
	
	# ---- Constructor (low level) ----
	
	#  * Constructs a QR Code segment with the specified attributes and data.
	#  * The character count (numCh) must agree with the mode and the bit buffer length,
	#  * but the constraint isn't checked. The specified bit buffer is cloned and stored.
	#  * @param md the mode (not {@code null})
	#  * @param numCh the data length in characters or bytes, which is non-negative
	#  * @param data the data bits (not {@code null})
	#  * @throws NullPointerException if the mode or data is {@code null}
	#  * @throws IllegalArgumentException if the character count is negative
	QrSegment([QrMode] $qrmd, [int] $numCh, [QrBitBuffer] $data)
	{
		if (-not $qrmd)
        {
            throw "md (Mode) is null"
		}
		$this.qrmode = $qrmd
		if ($numCh -lt 0)
        {
			throw "numCh must be greater than zero"
		}
		if (-not $data)
        {
            throw "data (QrBitBuffer) is null"
		}
		
		$this.numChars = $numCh
		$this.data = $data.clone() # Make defensive copy
	}
	
	
	# ---- Methods ----
	
	# Returns the data bits of this segment.
	# @return a new copy of the data bits (not {@code null})
	[QrBitBuffer] getData() {
		[QrBitBuffer] $tmpBb = $this.data.clone()
		return $tmpBb # Make defensive copy
	}
	
	[int] getDataLength() {
		return $this.data.getBitLength()
	}
	
	# Calculates the number of bits needed to encode the given segments at the given version.
	# Returns a non-negative number if successful. Otherwise returns -1 if a segment has too
	# many characters to fit its length field, or the total bits exceeds Integer.MAX_VALUE.
	static [int] getTotalBits([QrSegment[]] $segs, [int] $version)
	{
		if (-not $segs)
		{
			throw "segs (QrSegment[]) is null"
		}
		[long] $result = 0
		foreach ($seg in $segs)
		{
			if (-not $seg)
			{
				throw "inner seg (QrSegment) is null"
			}
			[int] $ccbits = $seg.qrmode.numCharCountBits($version)
			if ($seg.numChars -ge (1 -shl $ccbits))
			{
				return -1 # The segment's length doesn't fit the field's bit width
			}

			$result += ([long]4) + $ccbits + $seg.getDataLength()

			if ($result -gt [int]::MaxValue)
			{
				return -1 # The sum will overflow an int type
			}
		}
		return [Convert]::ToInt32($result)
	}
}

class QrCode {

	# Returns a QR Code representing the specified Unicode text string at the specified error correction level.
	# As a conservative upper bound, this function is guaranteed to succeed for strings that have 738 or fewer
	# Unicode code points (not UTF-16 code units) if the low error correction level is used. The smallest possible
	# QR Code version is automatically chosen for the output. The ECC level of the result may be higher than the
	# ecl argument if it can be done without increasing the version.
	# @param text the text to be encoded (not {@code null}), which can be any Unicode string
	# @param ecl the error correction level to use (not {@code null}) (boostable)
	# @return a QR Code (not {@code null}) representing the text
	# @throws NullPointerException if the text or error correction level is {@code null}
	# @throws DataTooLongException if the text fails to fit in the
    # largest version QR Code at the ECL, which means it is too long
    static [QrCode] encodeText([string] $text, [Ecc] $ecl,[int] $mask=-1, [boolean] $boostEcl=$true)
    {
        if (-not $text)
        {
            throw "text (string) in encodeText is null"
        }
        if (-not $ecl)
        {
            throw "Ecl (Ecc) in encodeText is null"
		}
		if(($mask -lt -2) -or ($mask -gt 7))
        {
            throw "mask is out of range. Must range from 0 to 7 (or -1 to auto detect ; -2 to disable masking)"
		}

		[QrSegment[]] $segs = [QrSegment]::makeSegments($text)
        return [QrCode]::encodeSegments($segs, $ecl,$mask,$boostEcl)
	}

	

	# Returns a QR Code representing the specified binary data at the specified error correction level.
	# This function always encodes using the binary segment mode, not any text mode. The maximum number of
	# bytes allowed is 2953. The smallest possible QR Code version is automatically chosen for the output.
	# The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
	# @param data the binary data to encode (not {@code null})
	# @param ecl the error correction level to use (not {@code null}) (boostable)
	# @return a QR Code (not {@code null}) representing the data
	# @throws NullPointerException if the data or error correction level is {@code null}
	# @throws DataTooLongException if the data fails to fit in the
    # largest version QR Code at the ECL, which means it is too long
    static [QrCode] encodeBinary([byte[]] $data, [Ecc] $ecl,[int] $mask=-1, [boolean] $boostEcl=$true)
    {
		if (-not $data)
        {
            throw "data (byte[]) in encodeBinary is null"
        }
        if (-not $ecl)
        {
            throw "ecl (Ecc) in encodeBinary is null"
		}
		if(($mask -lt -2) -or ($mask -gt 7))
        {
            throw "mask is out of range. Must range from 0 to 7 (or -1 to auto detect ; -2 to disable masking)"
		}
		
		[QrSegment] $seg = [QrSegment]::makeBytes($data)
        return [QrCode]::encodeSegments($seg, $ecl,$mask,$boostEcl)
	}
	
	# ---- Static Properties used globaly ----

	# The minimum version number  (1) supported in the QR Code Model 2 standard.
    static [int] $MIN_VERSION = 1

    # The maximum version number (40) supported in the QR Code Model 2 standard.
    static [int] $MAX_VERSION = 40

	# The Default Quiet Zone Size.
    static [int] $DEFAULT_QUIET_ZONE = 2

    # For use in getPenaltyScore(), when evaluating which mask is best.
    static $PENALTY_N1 =  3
    static $PENALTY_N2 =  3
    static $PENALTY_N3 = 40
    static $PENALTY_N4 = 10


    static [byte[][]] $ECC_CODEWORDS_PER_BLOCK = @(
    # Version: (note that index 0 is for padding, and is set to an illegal value)
    #    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40     Error correction level
    @(0xFF,  7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30), # Low
    @(0xFF, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28), # Medium
    @(0xFF, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30), # Quartile
    @(0xFF, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30)  # High
    )


    static [byte[][]]  $NUM_ERROR_CORRECTION_BLOCKS = @(
    # Version: (note that index 0 is for padding, and is set to an illegal value)
    #    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40      Error correction level
    @(0xFF, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4,  4,  4,  4,  4,  6,  6,  6,  6,  7,  8,  8,  9,  9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25),  # Low
    @(0xFF, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5,  5,  8,  9,  9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49),  # Medium
    @(0xFF, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8,  8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68),  # Quartile
    @(0xFF, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81)   # High
	)

		# ---- Constants ----
	

	static [string] $BINARY_REGEX = "^[01]+$"

	
	# Describes precisely all strings that are encodable in numeric mode. To test whether a
	# string {@code s} is encodable: {@code boolean ok = NUMERIC_REGEX.matcher(s).matches();}.
	# A string is encodable iff each character is in the range 0 to 9.
	# @see #makeNumeric(String) */
	static [string] $NUMERIC_REGEX = "^\d+$"
	
	# Describes precisely all strings that are encodable in alphanumeric mode. To test whether a
	# string {@code s} is encodable: {@code boolean ok = ALPHANUMERIC_REGEX.matcher(s).matches();}.
	# A string is encodable iff each character is in the following set: 0 to 9, A to Z
	# (uppercase only), space, dollar, percent, asterisk, plus, hyphen, period, slash, colon.
	# @see #makeAlphanumeric(String) */
	static [string] $ALPHANUMERIC_REGEX = "^[A-Z0-9 $%*+./:-]+$"

	# The set of all legal characters in alphanumeric mode, where
	# each character value maps to the index in the string.
	static [string] $ALPHANUMERIC_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

	
	# ---- Static factory functions (mid level) ----
	
	# Returns a QR Code representing the specified segments at the specified error correction
	# level. The smallest possible QR Code version is automatically chosen for the output. The ECC level
	# of the result may be higher than the ecl argument if it can be done without increasing the version.
	# <p>This function allows the user to create a custom sequence of segments that switches
	# between modes (such as alphanumeric and byte) to encode text in less space.
	# This is a mid-level API; the high-level API is {@link #encodeText(String,Ecc)}
	# and {@link #encodeBinary(byte[],Ecc)}.</p>
	# @param segs the segments to encode
	# @param ecl the error correction level to use (not {@code null}) (boostable)
	# @return a QR Code (not {@code null}) representing the segments
	# @throws NullPointerException if the list of segments, any segment, or the error correction level is {@code null}
	# @throws DataTooLongException if the segments fail to fit in the
	# largest version QR Code at the ECL, which means they are too long
	static [QrCode] encodeSegments([QrSegment[]] $segs, [Ecc] $ecl,[int] $mask=-1, [boolean] $boostEcl=$true) {
        return [QrCode]::encodeSegments($segs, $ecl, [QrCode]::MIN_VERSION, [QrCode]::MAX_VERSION, $mask, $boostEcl)
	}
	
	
	# Returns a QR Code representing the specified segments with the specified encoding parameters.
	# The smallest possible QR Code version within the specified range is automatically
	# chosen for the output. Iff boostEcl is {@code true}, then the ECC level of the
	# result may be higher than the ecl argument if it can be done without increasing
	# the version. The mask number is either between 0 to 7 (inclusive) to force that
	# mask, or &#x2212;1 to automatically choose an appropriate mask (which may be slow).
	# <p>This function allows the user to create a custom sequence of segments that switches
	# between modes (such as alphanumeric and byte) to encode text in less space.
	# This is a mid-level API; the high-level API is {@link #encodeText(String,Ecc)}
	# and {@link #encodeBinary(byte[],Ecc)}.</p>
	# @param segs the segments to encode
	# @param ecl the error correction level to use (not {@code null}) (boostable)
	# @param minVersion the minimum allowed version of the QR Code (at least 1)
	# @param maxVersion the maximum allowed version of the QR Code (at most 40)
	# @param mask the mask number to use (between 0 and 7 (inclusive)), or &#x2212;1 for automatic mask
	# @param boostEcl increases the ECC level as long as it doesn't increase the version number
	# @return a QR Code (not {@code null}) representing the segments
	# @throws NullPointerException if the list of segments, any segment, or the error correction level is {@code null}
	# @throws IllegalArgumentException if 1 &#x2264; minVersion &#x2264; maxVersion &#x2264; 40
	# or &#x2212;1 &#x2264; mask &#x2264; 7 is violated
	# @throws DataTooLongException if the segments fail to fit in
	# the maxVersion QR Code at the ECL, which means they are too long
	static [QrCode] encodeSegments([QrSegment[]] $segs, [Ecc] $ecl, [int] $minVersion, [int] $maxVersion, [int] $mask, [boolean] $boostEcl) {
        if (-not $segs)
        {
            throw "segs (QrSegment[]) in encodeSegments is null"
        }
        if (-not $ecl)
        {
            throw "ecl (Ecc) in encodeSegments is null"
        }

        if ( -not ((([QrCode]::MIN_VERSION -le $minVersion) -and ($minVersion -le $maxVersion) -and ($maxVersion -le [QrCode]::MAX_VERSION)) -or ($mask -lt -1) -or ($mask -gt 7)))
        {
            throw "invalid version or mask in encodeSegments"
        }
		
		
		# Find the minimal version number to use
        [int] $tmpVersion = 0
        [int] $dataUsedBits = 0

        $continueLoop = $true
        $tmpVersion = $minVersion - 1
        while ($continueLoop) {
            $tmpVersion++

		    [int] $dataCapacityBits = [QrCode]::getNumDataCodewords($tmpVersion, $ecl) * 8 # Number of data bits available
            $dataUsedBits = [QrSegment]::getTotalBits($segs, $tmpVersion)
            if (($dataUsedBits -ne -1) -and ($dataUsedBits -le $dataCapacityBits))
            {
                $continueLoop = $false # This version number is found to be suitable
            }
            else {
                if ($tmpVersion -ge $maxVersion) # All versions in the range could not fit the given data
                {  
            		[String] $msg = "Segment too long"
                    if ($dataUsedBits -ne -1)
                    {
                        $msg = "Data length = " + $dataUsedBits.toString() + " bits, Max capacity = " + $dataCapacityBits.toString() + " bits"
                    }
                    
					throw "$msg"
                }
            }
        }

        if ($dataUsedBits -eq -1)
        {
            throw "dataUsedBits error in encodeSegments"
        }
		
		# Increase the error correction level while the data still fits in the current version number
        if($boostEcl)
        {
			$nextEcl = $ecl
			while (-not $nextEcl.isMax())
			{
				$nextEcl = $nextEcl.getHigherEcc()
                if ($dataUsedBits -le ([QrCode]::getNumDataCodewords($tmpVersion, $nextEcl) * 8))
                {
                    $ecl.setEccValue($nextEcl.getEccValue())
				}
			}
        }
		
        # Concatenate all segments to create the data bit string
        
		[QrBitBuffer] $bb = New-Object 'QrBitBuffer'
        foreach ($seg in $segs)
        {
			$bb.appendBits($seg.qrmode.modeBits, 4)
			
			$bb.appendBits($seg.numChars, $seg.qrmode.numCharCountBits($tmpVersion))

			$bb.appendData($seg.getData())
        }
        
        if ($bb.getBitLength() -ne $dataUsedBits)
        {
            throw "bb.getBitLength must now be equal to dataUsedBits"
        }
		
        # Add terminator and pad up to a byte if applicable
		[int] $dataCapacityBits = [QrCode]::getNumDataCodewords($tmpVersion, $ecl) * 8

        if ($bb.getBitLength() -gt $dataCapacityBits)
        {
            throw "bb.getBitLength cannot be greater than dataCapacityBits"
        }

		$bb.appendBits(0,[Math]::Min(4,$dataCapacityBits - $bb.getBitLength()))
		$bb.appendBits(0,((8 - $bb.getBitLength() % 8) % 8))
		

        if (($bb.getBitLength() % 8) -ne 0)
        {
            throw "bb.getBitLength must be a multiple of 8"
        }
		
		# Pad with alternating bytes until data capacity is reached
		for ([int] $padByte = 0xEC; $bb.getBitLength() -lt $dataCapacityBits; $padByte = $padByte -bxor (0xEC -bxor 0x11))
        {
            $bb.appendBits($padByte,8)
        }
		
		# Pack bits into bytes in big endian
		$byteSize = ([Math]::truncate($bb.getBitLength() / 8))
		[byte[]] $dataCodewords = New-Object 'byte[]' $byteSize

        for ([int] $i = 0; $i -lt $byteSize; $i++) {
			# ToDo_test
			# Write-Host("BEFORE -- i : ",$i," --- bit : ",$bb.getBit($i)," --- (i >> 3) : ",($i -shr 3)," --- dcw[i>>3] : ",$datacodewords[$i -shr 3]," --- dcw : ",$datacodewords)
			$dataCodewords[$i] = $bb.getByte($i)
			# ToDo_test
            # Write-Host(" AFTER -- i : ",$i," --- bit : ",$bb.getBit($i)," --- (i >> 3) : ",($i -shr 3)," --- dcw[i>>3] : ",$datacodewords[$i -shr 3]," --- dcw : ",$datacodewords)
		}

		# Create the QR Code object
        return New-Object 'QrCode' $tmpVersion, $ecl, $dataCodewords, $mask
	}
	
	
	
	# ---- Instance fields ----
	
	# Public immutable scalar parameters:
	
    # The version number of this QR Code, which is between 1 and 40 (inclusive).
	# This determines the size of this barcode.
    [int] $version

    # The width and height of this QR Code, measured in modules, between
	# 21 and 177 (inclusive). This is equal to version &#xD7; 4 + 17.
    [int] $size

	# Stores the size of the border
	[int] $quietZone

    # /** The error correction level used in this QR Code, which is not {@code null}. */
	[Ecc] $errorCorrectionLevel
	
	# /** The index of the mask pattern used in this QR Code, which is between 0 and 7 (inclusive).
	#  * <p>Even if a QR Code is created with automatic masking requested (mask =
	#  * &#x2212;1), the resulting object still has a mask value between 0 and 7. */
	[int] $mask
	
	# Stores if the QRCode must be displayed with inverted colors
	[boolean] $isInverted
	
	# // Private grids of modules/pixels, with dimensions of size*size:
	
	# // The modules of this QR Code (false = white, true = black).
	# // Immutable after constructor finishes. Accessed through getModule().
    hidden [boolean[][]] $modules
	
	# // Indicates function modules that are not subjected to masking. Discarded when constructor finishes.
    hidden [boolean[][]] $isFunction
    
    	
	
	# ---- Constructor (low level) ----
	
	# Constructs a QR Code with the specified version number,
	# error correction level, data codeword bytes, and mask number.
	# <p>This is a low-level API that most users should not use directly. A mid-level
	# API is the {@link #encodeSegments(List,Ecc,int,int,int,boolean)} function.</p>
	# @param ver the version number to use, which must be in the range 1 to 40 (inclusive)
	# @param ecl the error correction level to use
	# @param dataCodewords the bytes representing segments to encode (without ECC)
	# @param msk the mask pattern to use, which is either &#x2212;1 for automatic choice or from 0 to 7 for fixed choice
	# @throws NullPointerException if the byte array or error correction level is {@code null}
	# @throws IllegalArgumentException if the version or mask value is out of range,
	# or if the data is the wrong length for the specified version and error correction level
	QrCode([int] $ver, [Ecc] $ecl, [byte[]] $dataCodewords, [int] $msk) {
		# Check arguments and initialize fields
        if (($ver -lt [QrCode]::MIN_VERSION) -or ($ver -gt [QrCode]::MAX_VERSION))
        {
			throw "version is out of range. Must range from "+[QrCode]::MIN_VERSION+" to "+[QrCode]::MAX_VERSION
        }
		
        if (($msk -lt -2) -or ($msk -gt 7))
        {
			throw "mask is out of range. Must range from 0 to 7 (or -1 to auto detect ; -2 to disable masking)"
        }

		$this.version = $ver
        $this.size = ($ver * 4) + 17
        $this.errorCorrectionLevel = New-Object 'Ecc' $ecl;
		$this.quietZone=[QrCode]::DEFAULT_QUIET_ZONE
        if (-not $dataCodewords)
        {
            throw "dataCodewords (byte[]) in QrCode is null"
        }
        $this.modules = New-Object 'boolean[][]' $this.size,$this.size # Initially all white
		$this.isFunction = New-Object 'boolean[][]' $this.size,$this.size
		
        # Compute ECC, draw modules, do masking
		$this.drawFunctionPatterns()
		# ToDo_test
		# Write-Host $this.toString()
		
		[byte[]] $allCodewords = $this.addEccAndInterleave($dataCodewords)
		
		$this.drawCodewords($allCodewords)
		# ToDo_test
		# Write-Host $this.toString()

		$this.mask = $this.handleConstructorMasking($msk)
		$this.isFunction = $null
	}
    
    # ---- Public instance methods ----
	
	# Returns the color of the module (pixel) at the specified coordinates, which is {@code false}
	# for white or {@code true} for black. The top left corner has the coordinates (x=0, y=0).
	# If the specified coordinates are out of bounds, then {@code false} (white) is returned.
	# @param x the x coordinate, where 0 is the left edge and size&#x2212;1 is the right edge
	# @param y the y coordinate, where 0 is the top edge and size&#x2212;1 is the bottom edge
	# @return {@code true} if the coordinates are in bounds and the module
	# at that location is black, or {@code false} (white) otherwise
    [boolean] getModule([int] $x, [int] $y)
    {
        return ((0 -le $x) -and ($x -lt $this.size) -and (0 -le $y) -and ($y -lt $this.size) -and $this.modules[$y][$x])
	}
	

	invert()
    {
		$this.isInverted = (-not $this.isInverted)
	}
	
	setQuietZone([int] $quietZone)
    {
		if($quietZone -lt 0){throw "quietZone (borderSize) must be equal or greater than 0"}
		$this.quietZone = $quietZone
	}

	setQuietZone()
    {
		$this.quietZone = [QrCode]::DEFAULT_QUIET_ZONE
	}

	# Deprecated function
	setBorderSize([int] $quietZone)
    {
		Write-Warning -Message "setBorderSize is deprecated, use setQuietZone instead"
		$this.setQuietZone($quietZone)
	}

	# Deprecated function
	setBorderSize()
    {
		Write-Warning -Message "setBorderSize is deprecated, use setQuietZone instead"
		$this.setQuietZone()
	}

	# Returns a raster image depicting this QR Code, with the specified module scale and border modules.
	# <p>For example, toImage(scale=10, border=4) means to pad the QR Code with 4 white
	# border modules on all four sides, and use 10&#xD7;10 pixels to represent each module.
	# The resulting image only contains the hex colors 000000 and FFFFFF.
	# @param scale the side length (measured in pixels, must be positive) of each module
	# @param border the number of border modules to add, which must be non-negative
	# @return a new image representing this QR Code, with padding and scaling
	# @throws IllegalArgumentException if the scale or border is out of range, or if
    # {scale, border, size} cause the image dimensions to exceed Integer.MAX_VALUE
    # ToDo_Func
	# public BufferedImage toImage(int scale, int border) {
	# 	if (scale <= 0 || border < 0)
	# 		throw new IllegalArgumentException("Value out of range");
	# 	if (border > Integer.MAX_VALUE / 2 || size + border * 2L > Integer.MAX_VALUE / scale)
	# 		throw new IllegalArgumentException("Scale or border too large");
		
	# 	BufferedImage result = new BufferedImage((size + border * 2) * scale, (size + border * 2) * scale, BufferedImage.TYPE_INT_RGB);
	# 	for (int y = 0; y < result.getHeight(); y++) {
	# 		for (int x = 0; x < result.getWidth(); x++) {
	# 			boolean color = getModule(x / scale - border, y / scale - border);
	# 			result.setRGB(x, y, color ? 0x000000 : 0xFFFFFF);
	# 		}
	# 	}
	# 	return result;
	# }

	[string] toString([int] $quietZone) {
		$output = ""

		$blackChar = " "
		$whiteChar = [char]0x2588

		if($this.isInverted){
			$tmpChar = $blackChar
			$blackChar = $whiteChar
			$whiteChar = $tmpChar
		}

		if($quietZone -lt 0){throw "quietZone (borderSize) must be equal or greater than 0"}

		for ([int] $y = -$quietZone; $y -lt ($this.size + $quietZone); $y++)
		{
			for ([int] $x = -$quietZone; $x -lt ($this.size + $quietZone); $x++)
			{
				if (($y -ge 0) -and ($y -lt $this.size) -and ($x -ge 0) -and ($x -lt $this.size))
				{
					if($this.getModule($x, $y))
					{
						# write space
						$output += $blackChar
						$output += $blackChar
					}
					else
					{
						# write block
						$output += $whiteChar
						$output += $whiteChar
					}
				}
				else
				{
					# write protective blocks
					$output += $whiteChar
					$output += $whiteChar
				}
			}
			$output += "`n"
		}
		# $output += "`n"

		return $output
	}
	
	[string] toString() {
		return $this.toString($this.quietZone)
	}
	
	# Returns a string of SVG code for an image depicting this QR Code, with the specified number
	# of border modules. The string always uses Unix newlines (\n), regardless of the platform.
	# @param quietZone the number of border modules to add, which must be non-negative
	# @return a string representing this QR Code as an SVG XML document
	# @throws IllegalArgumentException if the quiet zone size is negative
	[String] toSvgString([int] $quietZone)
	{
		if($quietZone -lt 0){throw "quietZone (borderSize) must be equal or greater than 0"}
		
		$blackChar = "#FFFFFF"
		$whiteChar = "#000000 "

		if($this.isInverted){
			$tmpChar = $blackChar
			$blackChar = $whiteChar
			$whiteChar = $tmpChar
		}

		[long] $brd = $quietZone
		[long] $fullSize = $this.size + ($brd * 2)
		[string] $sb = ""
		$sb += "<?xml version=""1.0"" encoding=""UTF-8""?>`n"
		$sb += "<!DOCTYPE svg PUBLIC ""-//W3C//DTD SVG 1.1//EN"" ""http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"">`n"
		$sb += "<svg xmlns=""http://www.w3.org/2000/svg"" version=""1.1"" viewBox=""0 0 $fullSize $fullSize"" stroke=""none"">`n"

		$sb += "`t<rect width=""$fullSize"" height=""$fullSize"" fill=""$blackChar""/>`n"
		
		$sb += "`t<path d="""

		for ([int] $y = 0; $y -lt $this.size; $y++)
		{
			for ([int] $x = 0; $x -lt $this.size; $x++)
			{
				if ($this.getModule($x, $y))
				{
					if (($x -ne 0) -or ($y -ne 0))
					{
						$sb += " "
					}
					$sb += "M$( $x + $brd ),$( $y + $brd )h1v1h-1z"
				}
			}
		}

		$sb += """ fill=""$whiteChar""/>`n"

		$sb += "</svg>`n"

		return $sb
	}
	
	[string] toSvgString() {
		return $this.toSvgString($this.quietZone)
	}


	# Returns a string of Braille characteres depicting this QR Code, with the specified number
	# of border modules. The string always uses Unix newlines (\n), regardless of the platform.
	# @param border the number of border modules to add, which must be non-negative
	# @return a string representing this QR Code in Unicode Braille Characters
	# @throws IllegalArgumentException if the quiet zone size is negative
	[String] toBrailleString([int] $quietZone)
	{
		if($quietZone -lt 0){throw "quietZone (borderSize) must be equal or greater than 0"}

		$output = ""

		for ([int] $y = -$quietZone; $y -lt ($this.size + $quietZone); $y=$y+4)
		{
			for ([int] $x = -$quietZone; $x -lt ($this.size + $quietZone); $x=$x+2)
			{
				$BrailleChar=0x2800 #Empty Braille Char

				# 4 First Dots Loop
				for([int] $innerX = 0; $innerX -lt 2; $innerX++)
				{
					for ([int] $innerY = 0; $innerY -lt 3; $innerY++)
					{
						if ((($y+$innerY) -ge 0) -and (($y+$innerY) -lt $this.size) -and (($x+$innerX) -ge 0) -and (($x+$innerX) -lt $this.size))
						{
							# Write-Host "Coords xy : $($x+$innerX)-$($y+$innerY) -- $($this.getModule($x+$innerX, $y+$innerY)) -- $([Math]::Pow(2,$innerY+($innerX*3)))"
							if($this.isInverted){
								if(($this.getModule($x+$innerX, $y+$innerY)))
								{
									# add dot
									$BrailleChar += [Math]::Pow(2,$innerY+($innerX*3))
								}
							} else {
								if(-not ($this.getModule($x+$innerX, $y+$innerY)))
								{
									# add dot
									$BrailleChar += [Math]::Pow(2,$innerY+($innerX*3))
								}
							}
						} else {
							# Write-Host "Coords xy : $($x+$innerX)-$($y+$innerY) -- FILLER -- $([Math]::Pow(2,$innerY+($innerX*3)))"
							if (-not ((($y+$innerY) -ge ($this.size+$quietZone)) -or (($X+$innerX) -ge ($this.size+$quietZone))))
							{
								if(-not $this.isInverted){
									$BrailleChar += [Math]::Pow(2,$innerY+($innerX*3))
								}
							}
						}
					}
				}

				# 2 Last Dots Loop
				$innerY = 3
				for([int] $innerX = 0; $innerX -lt 2; $innerX++)
				{
					if ((($y+$innerY) -ge 0) -and (($y+$innerY) -lt $this.size) -and (($x+$innerX) -ge 0) -and (($x+$innerX) -lt $this.size))
					{
						# Write-Host "Coords xy : $($x+$innerX)-$($y+$innerY) -- $($this.getModule($x+$innerX, $y+$innerY)) -- $([Math]::Pow(2,6+$innerX))`n"
						if($this.isInverted){
							if(($this.getModule($x+$innerX, $y+$innerY)))
							{
								# add dot
								$BrailleChar += [Math]::Pow(2,6+$innerX)
							}
						} else {
							if(-not ($this.getModule($x+$innerX, $y+$innerY)))
							{
								# add dot
								$BrailleChar += [Math]::Pow(2,6+$innerX)
							}
						}
					} else {
						# Write-Host "Coords xy : $($x+$innerX)-$($y+$innerY) -- FILLER -- $([Math]::Pow(2,6+$innerX))"
						if (-not ((($y+$innerY) -ge ($this.size+$quietZone)) -or (($X+$innerX) -ge ($this.size+$quietZone))))
						{
							if(-not $this.isInverted){
								$BrailleChar += [Math]::Pow(2,6+$innerX)
							}
						}
					}
				}

				$output += [char]([int]$BrailleChar)

			}
			$output += "`n"
		}
		# $output += "`n"

		return $output
	}
	
	[string] toBrailleString() {
		return $this.toBrailleString($this.quietZone)
	}

	[System.Drawing.Bitmap] toBitmap()
	{
		$blackChar = [System.Drawing.Color]::FromName("Black")
		$whiteChar = [System.Drawing.Color]::FromName("White")

		if($this.isInverted){
			$tmpChar = $blackChar
			$blackChar = $whiteChar
			$whiteChar = $tmpChar
		}

    	$width = $height = $this.size + (2 * $this.quietZone)
    	$bitmap = New-Object 'System.Drawing.Bitmap' $width,$height

		# Set pixel colors
		for ($y = 0; $y -lt $height; $y++) {
			for ($x = 0; $x -lt $width; $x++) {
				$color = $blackChar
				if(($y -gt $this.quietZone) -and ($y -lt ($this.size + $this.quietZone)) -and ($x -gt $this.quietZone) -and ($x -lt ($this.size + $this.quietZone))){
					$color = if($this.getModule($y-$this.quietZone,$x-$this.quietZone)){ $whiteChar }
				}
				$bitmap.SetPixel($x, $y, $color)
			}
		}

		return $bitmap
	}

	saveAsSvg([String] $path){
		$completePath = $this.getFullFinalPath($path, "svg")
		$this.toSvgString() | Out-File -FilePath $completePath -Encoding UTF8
	}

	saveAsPng([String] $path, [int] $scale){
		if($scale -lt 1){throw "scale must be equal or greater than 1"}

		$completePath = $this.getFullFinalPath($path, "png")
		$this.toBitmap().Save($completePath, [System.Drawing.Imaging.ImageFormat]::Png)
	}

	saveAsPng([String] $path){
		$this.saveAsPng($path,1)
	}

	saveAsBmp([String] $path, [int] $scale)
	{
		if($scale -lt 1){throw "scale must be equal or greater than 1"}

		[byte[]] $blackChar = @([byte]0xFF,[byte]0xFF,[byte]0xFF)
		[byte[]] $whiteChar = @([byte]0x00,[byte]0x00,[byte]0x00)

		if($this.isInverted){
			$tmpChar = $blackChar
			$blackChar = $whiteChar
			$whiteChar = $tmpChar
		}

		$completePath = $this.getFullFinalPath($path, "bmp")

		$fileStream = [System.IO.File]::Create($completePath)
		$binaryWriter = New-Object System.IO.BinaryWriter($fileStream)

		$fullwidth = ($this.size + (2 * $this.quietZone)) * $scale

		$pixelSize = ([Math]::Pow($fullwidth,2)*3)

		try {
			# BMP File Header
			$binaryWriter.Write([char[]]"BM")  # Signature
			$binaryWriter.Write([int32](0x36 + $pixelSize))  # File size
			$binaryWriter.Write([int32]0x00)  # Reserved
			$binaryWriter.Write([int32]0x36)  # Offset to pixel data

			# DIB Header (BITMAPINFOHEADER)
			$binaryWriter.Write([int32]0x28)  # Header size
			$binaryWriter.Write([int32]$fullwidth)  # Image width
			$binaryWriter.Write([int32]$fullwidth)  # Image height
			$binaryWriter.Write([int16]1)  # Number of color planes
			$binaryWriter.Write([int16]24)  # Bits per pixel
			$binaryWriter.Write([int32]0)  # Compression method (0 = none)
			$binaryWriter.Write([int32]$pixelSize)  # Image size
			$binaryWriter.Write([int32]0)  # Horizontal resolution (pixels/meter)
			$binaryWriter.Write([int32]0)  # Vertical resolution (pixels/meter)
			$binaryWriter.Write([int32]0)  # Number of colors in the palette
			$binaryWriter.Write([int32]0)  # Number of important colors
			
			$padCount = 0
			# Pixel data
			for ($x = ($fullwidth - 1) ; $x -ge 0 ; $x--) {
				for ($y = 0 ; $y -lt $fullwidth ; $y++) {
					$color = $blackChar
					# if(($y -ge $this.quietZone) -and ($y -lt ($this.size + $this.quietZone)) -and ($x -ge $this.quietZone) -and ($x -lt ($this.size + $this.quietZone))){
					if((([math]::truncate($y/$scale)) -ge $this.quietZone) -and (([math]::truncate($y/$scale)) -lt ($this.size + $this.quietZone)) -and (([math]::truncate($x/$scale)) -ge $this.quietZone) -and (([math]::truncate($x/$scale)) -lt ($this.size + $this.quietZone))){
						if($this.getModule(([math]::truncate($y/$scale))-$this.quietZone,([math]::truncate($x/$scale))-$this.quietZone)){ $color = $whiteChar }
					}
					$padCount += $color.Count
					$binaryWriter.Write([byte[]]$color)
				}

				while($padCount%4 -ne 0){
					$binaryWriter.Write([byte[]]0x00)
					$padCount++
				}
			}

		} finally {
			$binaryWriter.Close()
			$fileStream.Close()
		}
	}

	saveAsBmp([String] $path)
	{
		$this.saveAsBmp($path,1)
	}

	hidden [string] getFullFinalPath([String] $path, [String] $fileFormat){
		$allowedFormats = @("svg","png","bmp")
		if ($allowedFormats.IndexOf($fileFormat) -eq -1){ throw "Format not supported" }

		$tmpDirectory = "./"
		$finalDirectory = ""
		$finalFilename = ""
		$tmpFilename = ""
		$defaultFilename = "QrCode_"
		$fileExtention = "." + $fileFormat
		$_frperror = $null

		$tmpPath = Resolve-Path $path -ErrorAction SilentlyContinue -ErrorVariable _frperror
		if (-not $tmpPath){ $tmpPath = $_frperror[0].TargetObject }

		if([System.IO.Path]::GetExtension((Split-Path $tmpPath -leaf)) -eq $fileExtention){
			$tmpDirectory = Split-Path $tmpPath -Parent
			$tmpFilename = Split-Path $tmpPath -leaf
		}else{
			$tmpDirectory = $tmpPath
		}

		if(Test-Path $tmpDirectory){
			$finalDirectory = Get-Item $tmpDirectory
		}else{
			$finalDirectory = New-Item -ItemType Directory -Path $tmpDirectory
		}
		if (-not $finalDirectory){ throw("Error when targeting/creating the folder " + $tmpDirectory) }

		if($tmpFilename){
			$finalFilename = $tmpFilename
		} else {
			# determination et composition du nom du fichier
			$finalFilename = $this.findAvailableFileName($finalDirectory, $defaultFilename, $fileExtention)
		}
		if (-not $finalFilename){ throw("Error when determining the filename") }

		return (Join-Path -Path $finalDirectory -ChildPath $finalFilename)
	}

	hidden [string] findAvailableFileName([string] $folder, [string]$startName, [string]$extension) {

		$number = 1
		$positions = 3 # how many numbers
		$maxAttempts = [Math]::Pow(10,$positions)
		$result = $null
		$fileName = ""

		while ($number -le $maxAttempts) {
			$fileName = ("{0}{1:D" + $positions + "}{2}") -f $startName, $number, $extension
			$fullPath = Join-Path -Path $folder -ChildPath $fileName

			if (-not (Test-Path -Path $fullPath -PathType Leaf)) {
				$result = $fullPath
				break
			}

			$number++
		}

		if ($result -eq $null) { throw ("No available file names found after " + ($maxAttempts -1) + " attempts.") }

		return $fileName
	}
 
	# ---- Private helper methods for constructor: Drawing function modules ----
	
	# Reads this object's version field, and draws and marks all function modules.
    hidden drawFunctionPatterns()
    {
        # Draw horizontal and vertical timing patterns
        for ([int] $i = 0; $i -lt $this.size; $i++)
        {
            $this.setFunctionModule(6, $i, ($i % 2) -eq 0)
            $this.setFunctionModule($i, 6, ($i % 2) -eq 0)
        }
        
        # Draw 3 finder patterns (all corners except bottom right; overwrites some timing modules)
        $this.drawFinderPattern(3, 3)
        $this.drawFinderPattern($this.size - 4, 3)
        $this.drawFinderPattern(3, $this.size - 4)
        
        # Draw numerous alignment patterns
        [int[]] $alignPatPos = $this.getAlignmentPatternPositions()
        [int] $numAlign = $alignPatPos.length
        for ([int] $i = 0; $i -lt $numAlign; $i++)
        {
            for ([int] $j = 0; $j -lt $numAlign; $j++)
            {
                # Don't draw on the three finder corners
                if ( -not ((($i -eq 0) -and ($j -eq 0)) -or (($i -eq 0) -and ($j -eq ($numAlign - 1))) -or (($i -eq ($numAlign - 1)) -and ($j -eq 0))))
                {
                    $this.drawAlignmentPattern($alignPatPos[$i], $alignPatPos[$j])
                }
            }
        }
        
        # Draw configuration data
        $this.drawFormatBits(0) # Dummy mask value; overwritten later in the constructor
        $this.drawVersion()
        return
	}
	
	
	# Draws two copies of the format bits (with its own error correction code)
	# based on the given mask and this object's error correction level field.
    hidden drawFormatBits([int] $msk)
    {
        # Calculate error correction code and pack bits
        [int] $data = ($this.errorCorrectionLevel.getEccValue() -shl 3) -bor $msk # errCorrLvl is uint2, mask is uint3
        [int] $rem = $data
        for ([int] $i = 0; $i -lt 10; $i++)
        {
            $rem = ($rem -shl 1) -bxor (($rem -shr 9) * 0x537)
        }
        
        [int] $bits = ($data -shl 10 -bor $rem) -bxor 0x5412 # uint15

        if (($bits -shr 15) -ne 0)
        {
            throw "bits must be less than 15 bits long"
        }
        
        # Draw first copy
        for ([int] $i = 0; $i -le 5; $i++)
        {
            $this.setFunctionModule(8, $i, [QrCode]::getBit($bits, $i))
        }
        $this.setFunctionModule(8, 7, [QrCode]::getBit($bits, 6))
        $this.setFunctionModule(8, 8, [QrCode]::getBit($bits, 7))
        $this.setFunctionModule(7, 8, [QrCode]::getBit($bits, 8))
        for ([int] $i = 9; $i -lt 15; $i++)
        {
            $this.setFunctionModule(14 - $i, 8, [QrCode]::getBit($bits, $i))
        }
        
        # Draw second copy
        for ([int] $i = 0; $i -lt 8; $i++)
        {
            $this.setFunctionModule($this.size - 1 - $i, 8, [QrCode]::getBit($bits, $i))
        }
        for ([int] $i = 8; $i -lt 15; $i++)
        {
            $this.setFunctionModule(8, $this.size - 15 + $i, [QrCode]::getBit($bits, $i))
        }
        $this.setFunctionModule(8, $this.size - 8, $true) # Always black
	}
	
	
	# Draws two copies of the version bits (with its own error correction code),
	# based on this object's version field, iff 7 <= version <= 40.
    hidden drawVersion()
    {
        if ($this.version -lt 7) { return }
        
        # Calculate error correction code and pack bits
        [int] $rem = $this.version # version is uint6, in the range [7, 40]
        
        for ([int] $i = 0; $i -lt 12; $i++)
        {
            $rem = ($rem -shl 1) -bxor (($rem -shr 11) * 0x1F25)
        }
        
        [int] $bits = $this.version -shl 12 -bor $rem # uint18

		if (($bits -shr 18) -ne 0)
        {
			throw "bits must be less than 18 bits long"
        }
        
        # Draw two copies
        for ([int] $i = 0; $i -lt 18; $i++)
        {
            [boolean] $bit = [QrCode]::getBit($bits, $i)
            [int] $a = $this.size - 11 + ($i % 3)
            [int] $b = [Math]::truncate($i / 3)
            $this.setFunctionModule($a, $b, $bit)
            $this.setFunctionModule($b, $a, $bit)
        }
    }
	
	
	# Draws a 9*9 finder pattern including the border separator,
	# with the center module at (x, y). Modules can be out of bounds.
    hidden drawFinderPattern([int] $x, [int] $y)
    {
        for ([int] $dy = -4; $dy -le 4; $dy++)
        {
            for ([int] $dx = -4; $dx -le 4; $dx++)
            {
                [int] $dist = [Math]::Max([Math]::Abs($dx), [Math]::Abs($dy)) # Chebyshev/infinity norm
                [int] $xx = $x + $dx
                [int] $yy = $y + $dy
                if ((0 -le $xx) -and ($xx -lt $this.size) -and (0 -le $yy) -and ($yy -lt $this.size))
                {
                    $this.setFunctionModule($xx, $yy, ($dist -ne 2) -and ($dist -ne 4))
                }
            }
        }
    }
	
	
	# Draws a 5*5 alignment pattern, with the center module
	# at (x, y). All modules must be in bounds.
    hidden drawAlignmentPattern([int] $x, [int] $y)
    {
        for ([int] $dy = -2; $dy -le 2; $dy++)
        {
            for ([int] $dx = -2; $dx -le 2; $dx++)
            {
                $this.setFunctionModule($x + $dx, $y + $dy, [Math]::Max([Math]::Abs($dx), [Math]::Abs($dy)) -ne 1)
            }
        }
    }
	
	
	# Sets the color of a module and marks it as a function module.
	# Only used by the constructor. Coordinates must be in bounds.
    hidden setFunctionModule([int] $x, [int] $y, [boolean] $isBlack)
    {
        $this.modules[$y][$x] = $isBlack
        $this.isFunction[$y][$x] = $true
    }
	
	
	# ---- Private helper methods for constructor: Codewords and masking ----
	
	# Returns a new byte string representing the given data with the appropriate error correction
	# codewords appended to it, based on this object's version and error correction level.
    hidden [byte[]] addEccAndInterleave([byte[]] $data)
    {
        if (-not $data)
        {
			throw "data (byte[]) in addEccAndInterleave is null"
		}

        if ($data.length -ne [QrCode]::getNumDataCodewords($this.version, $this.errorCorrectionLevel))
        {
			throw "data.length in addEccAndInterleave is not equal to getNumDataCodewords"
		}
		
		# Calculate parameter numbers
        [int] $numBlocks = [QrCode]::NUM_ERROR_CORRECTION_BLOCKS[$this.errorCorrectionLevel.getEccOrdinal()][$this.version]
        [int] $blockEccLen = [QrCode]::ECC_CODEWORDS_PER_BLOCK[$this.errorCorrectionLevel.getEccOrdinal()][$this.version]
		[int] $rawCodewords = [Math]::truncate([QrCode]::getNumRawDataModules($this.version) / 8)
        [int] $numShortBlocks = $numBlocks - ($rawCodewords % $numBlocks)
        [int] $shortBlockLen = [Math]::truncate($rawCodewords / $numBlocks)
		
        # Split data into blocks and append ECC to each block
        [byte[][]] $blocks = New-Object 'byte[][]' $numBlocks
        [byte[]] $rsDiv = [QrCode]::reedSolomonComputeDivisor($blockEccLen)
        [int] $k = 0
        for ([int] $i = 0; $i -lt $numBlocks; $i++)
        {
            if($i -lt $numShortBlocks){$boolNSB = 0}else{$boolNSB = 1}
            $newSize = $shortBlockLen - $blockEccLen + $boolNSB
            [byte[]] $dat = New-Object 'byte[]' $newSize
			$loopSize = [Math]::Min($data.Length - $k, $newSize)
            for ($counter = 0; $counter -lt $loopSize; $counter++)
            {
                $dat[$counter] = $data[$k + $counter]
            }

            $k += $dat.length
            [byte[]] $block = New-Object 'byte[]' ($shortBlockLen + 1)
            $loopSize = [Math]::Min($shortBlockLen + 1,$dat.length)
            for ($counter = 0; $counter -lt $loopSize; $counter++)
            {
                $block[$counter] = $dat[$counter]
            }

			[byte[]] $ecc = [QrCode]::reedSolomonComputeRemainder($dat, $rsDiv)
			
            # System.arraycopy(ecc, 0, block, block.length - blockEccLen, ecc.length)
            # source_arr : $ecc
            # sourcePos : 0
            # dest_arr : $block
            # destPos : $block.length - $blockEccLen
            # len : $ecc.length
            for ($counter = 0; $counter -lt $ecc.length; $counter++)
            {
                $block[($block.length - $blockEccLen) + $counter] = $ecc[0 + $counter]
            }

            $blocks[$i] = $block
        }
        
        # Interleave (not concatenate) the bytes from every block into a single sequence
        [byte[]] $result = New-Object 'byte[]' $rawCodewords
        [int] $k = 0
        for ([int] $i = 0; $i -lt $blocks[0].length; $i++)
        {
            for ([int] $j = 0; $j -lt $blocks.length; $j++)
            {
                # Skip the padding byte in short blocks
                if (($i -ne ($shortBlockLen - $blockEccLen)) -or ($j -ge $numShortBlocks))
                {
                    $result[$k] = $blocks[$j][$i]
                    $k++
                }
            }
        }
        return $result
    }
	
	
	# Draws the given sequence of 8-bit codewords (data and error correction) onto the entire
	# data area of this QR Code. Function modules need to be marked off before this is called.
	hidden drawCodewords([byte[]] $data) {
        if (-not $data)
        {
			throw "data (byte[]) in drawCodewords is null"
		}
		
		if ($data.length -ne ([Math]::truncate([QrCode]::getNumRawDataModules($this.version) / 8)))
		{
			throw "data.length in drawCodewords is not equal to getNumRawDataModules"
		}

		[int] $i = 0 # Bit index into the data
		# Do the funny zigzag scan
		for ([int] $right = $this.size - 1; $right -ge 1; $right -= 2) # Index of right column in each column pair
		{
			if ($right -eq 6){$right = 5}
			for ([int] $vert = 0; $vert -lt $this.size; $vert++)
			{ # Vertical counter
				for ([int] $j = 0; $j -lt 2; $j++)
				{
					[int] $x = $right - $j # Actual x coordinate
					[boolean] $upward = (($right + 1) -band 2) -eq 0
					[int] $y = $vert
					if ($upward) {$y = ($this.size - 1 - $vert)} # Actual y coordinate
					# ToDo_test
					# Write-Host("upward : ",$upward," --- y : ",$y," --- x : ",$x," --- i : ",$i," --- data.length : ",$data.length)
					if ( (-not ($this.isFunction[$y][$x])) -and ($i -lt ($data.length * 8)))
					{
						$this.modules[$y][$x] = [QrCode]::getBit($data[($i -shr 3)], 7 - ($i -band 7))
						$i++
					}
					# If this QR Code has any remainder bits (0 to 7), they were assigned as
					# 0/false/white by the constructor and are left unchanged by this method
				}
			}
		}
		if ($i -ne ($data.length * 8))
		{
			throw "i in drawCodewords is not equal to data.length * 8"
		}
    }
	
	
	# XORs the codeword modules in this QR Code with the given mask pattern.
	# The function modules must be marked and the codeword bits must be drawn
	# before masking. Due to the arithmetic of XOR, calling applyMask() with
	# the same mask value a second time will undo the mask. A final well-formed
	# QR Code needs exactly one (not zero, two, etc.) mask applied.
	hidden applyMask([int] $msk)
	{
		if(($msk -lt 0) -or ($msk -gt 7))
		{
			throw "mask is out of range. Must range from 0 to 7 (-1 and -2 are not applicable here)"
		}
		
		for([int] $y = 0; $y -lt $this.size; $y++)
		{
			for([int] $x = 0; $x -lt $this.size; $x++)
			{
				[boolean] $invert = $false
				switch ($msk) {
					0 {$invert = (($x + $y) % 2 -eq 0)                                                    }
					1 {$invert = (($y % 2) -eq 0)                                                         }
					2 {$invert = (($x % 3) -eq 0)                                                         }
					3 {$invert = ((($x + $y) % 3) -eq 0)                                                  }
					4 {$invert = (((([Math]::Truncate($x / 3)) + ([Math]::Truncate($y / 2))) % 2) -eq 0)  }
					5 {$invert = ((($x * $y % 2) + ($x * $y % 3)) -eq 0)                                  }
					6 {$invert = (((($x * $y % 2) + ($x * $y % 3)) % 2) -eq 0)                            }
					7 {$invert = ((((($x + $y) % 2) + ($x * $y % 3)) % 2) -eq 0)                          }
					default {
						throw "mask is weirdly out of range. Must range from 0 to 7 (-1 and -2 are not applicable here)"
					}
				}
				$this.modules[$y][$x] = $this.modules[$y][$x] -bxor ($invert -band (-not $this.isFunction[$y][$x]))
			}
		}
	}
	
	
	# A messy helper function for the constructor. This QR Code must be in an unmasked state when this
	# method is called. The given argument is the requested mask, which is -1 for auto or 0 to 7 for fixed.
	# This method applies and returns the actual mask chosen, from 0 to 7.
	hidden [int] handleConstructorMasking([int] $msk)
	{
		if($msk -eq -2)
		{
			return -2
		}

		if ($msk -eq -1) # Automatically choose best mask
		{
			[int] $minPenalty = [int]::MaxValue
			for ([int] $i = 0; $i -lt 8; $i++)
			{
				$this.applyMask($i)
				$this.drawFormatBits($i)
				[int] $penalty = $this.getPenaltyScore()
				# Write-Host "mask " + $i + " : " $penalty
				if ($penalty -lt $minPenalty)
				{
					$msk = $i
					$minPenalty = $penalty
				}
				$this.applyMask($i) # Undoes the mask due to XOR
			}
		}

		if(($msk -lt 0) -or ($msk -gt 7))
		{
			throw "mask is out of range in handleConstructorMasking. Must range from 0 to 7 (-1 is not applicable here)"
		}
		
		# ToDo_test
		# $msk = 1
		# Write-Host $msk

		$this.applyMask($msk) # Apply the final choice of mask
		$this.drawFormatBits($msk) # Overwrite old format bits
		return $msk # The caller shall assign this value to the final-declared field
	}
	
	
	# Calculates and returns the penalty score based on state of this QR Code's current modules.
	# This is used by the automatic mask choice algorithm to find the mask pattern that yields the lowest score.
	hidden [int] getPenaltyScore()
	{
		[int] $result = 0
		
		# Adjacent modules in row having same color, and finder-like patterns
		for([int] $y = 0; $y -lt $this.size; $y++)
		{
			[boolean] $runColor = $false
			[int] $runX = 0
			[int[]] $runHistory = New-Object 'int[]' 7
			for ([int] $x = 0; $x -lt $this.size; $x++)
			{
				if ($this.modules[$y][$x] -eq $runColor)
				{
					$runX++
					if ($runX -eq 5)
					{
						$result += [QrCode]::PENALTY_N1
					}
					elseif ($runX -gt 5)
					{
						$result++
					}
				}
				else
				{
					$this.finderPenaltyAddHistory($runX, $runHistory)
					if (-not $runColor)
					{
						$result += $this.finderPenaltyCountPatterns($runHistory) * [QrCode]::PENALTY_N3
					}
					$runColor = $this.modules[$y][$x]
					$runX = 1
				}
			}
			$result += ($this.finderPenaltyTerminateAndCount($runColor, $runX, $runHistory) * [QrCode]::PENALTY_N3)
		}
		# Write-Host "1 - " + $result

		# Adjacent modules in column having same color, and finder-like patterns
		for ([int] $x = 0; $x -lt $this.size; $x++)
		{
			[boolean] $runColor = $false
			[int] $runY = 0
			[int[]] $runHistory = New-Object 'int[]' 7
			for ([int] $y = 0; $y -lt $this.size; $y++)
			{
				if ($this.modules[$y][$x] -eq $runColor)
				{
					$runY++
					if ($runY -eq 5)
					{
						$result += [QrCode]::PENALTY_N1
					}
					elseif ($runY -gt 5)
					{
						$result++
					}
				}
				else
				{
					$this.finderPenaltyAddHistory($runY, $runHistory)
					if (-not $runColor)
					{
						$result += $this.finderPenaltyCountPatterns($runHistory) * [QrCode]::PENALTY_N3
					}
					$runColor = $this.modules[$y][$x]
					$runY = 1
				}
			}
			$result += ($this.finderPenaltyTerminateAndCount($runColor, $runY, $runHistory) * [QrCode]::PENALTY_N3)
		}
		# Write-Host "2 - " + $result
		
		# 2*2 blocks of modules having same color
		for ([int] $y = 0; $y -lt ($this.size - 1); $y++)
		{
			for ([int] $x = 0; $x -lt ($this.size - 1); $x++)
			{
				[boolean] $color = $this.modules[$y][$x]
				if (  ($color -eq $this.modules[$y][$x + 1]) -and ($color -eq $this.modules[$y + 1][$x]) -and ($color -eq $this.modules[$y + 1][$x + 1]) )
				{
					$result += [QrCode]::PENALTY_N2
				}
			}
		}
		# Write-Host "3 - " + $result
		
		# Balance of black and white modules
		[int] $black = 0
		foreach ($row in $this.modules)
		# for ([boolean[]] row : modules)
		{
			foreach ($color in $row)
			# for (boolean color : row)
			{
				if ($color){$black++}
			}
		}
		[int] $total = $this.size * $this.size # Note that size is odd, so black/total != 1/2
		# Write-Host "4 - " + $result

		# Compute the smallest integer k >= 0 such that (45-5k)% <= black/total <= (55+5k)%
		[int] $k = [math]::Truncate(([math]::Abs(($black * 20) - ($total * 10)) + $total - 1) / $total) - 1
		$result += $k * [QrCode]::PENALTY_N4
		# Write-Host "5 - " + $result

		return $result
	}
	
	
	
	# /*---- Private helper functions ----*/
	
	# // Returns an ascending list of positions of alignment patterns for this version number.
	# // Each position is in the range [0,177), and are used on both the x and y axes.
	# // This could be implemented as lookup table of 40 variable-length lists of unsigned bytes.
    hidden [int[]] getAlignmentPatternPositions()
    {
		if ($this.version -eq 1)
		{
			return (New-Object 'int[]' 1)
		}
		else
		{
			[int] $numAlign = [Math]::truncate($this.version / 7) + 2
			[int] $step = 0
			
			if ($this.version -eq 32) # Special snowflake
			{
				$step = 26
			}
			else # step = ceil[(size - 13) / (numAlign*2 - 2)] * 2
			{
				$step = [Math]::truncate((($this.version * 4) + ($numAlign * 2) + 1) / ((($numAlign * 2) - 2))) * 2
			}
			
			[int[]] $result = New-Object 'int[]' $numAlign
			$result[0] = 6
			[int] $pos = $this.size - 7
			for ([int] $i = ($result.length - 1); $i -ge 1; $i--)
			{
				$result[$i] = $pos
				$pos -= $step
			}
			return $result
		}
        return $null
    }
	
	
	# Returns the number of data bits that can be stored in a QR Code of the given version number, after
	# all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
	# The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
	hidden static [int] getNumRawDataModules([int] $ver)
	{
		if (($ver -lt [QrCode]::MIN_VERSION) -or ($ver -gt [QrCode]::MAX_VERSION))
        {
			throw "Version in getNumRawDataModules is not a valid value. It must range from "+[QrCode]::MIN_VERSION+" to "+[QrCode]::MAX_VERSION
		}
		
		$result = (((16 * $ver) + 128) * $ver) + 64

		if ($ver -ge 2)
		{
			[int] $numAlign = [Math]::truncate($ver / 7) + 2
			$result -= (((25 * $numalign) - 10) * $numalign) - 55
			if ($ver -ge 7)
			{
				$result -= 6 * 3 * 2 # Subtract version information
			}
		}
		if(($result -lt 208) -or ($result -gt 29648))
		{
			throw "result in getNumRawDataModules is not a valid value. It must range from 208 to 29648"
		}
		return $result
	}
	
	
	# Returns a Reed-Solomon ECC generator polynomial for the given degree. This could be
	# implemented as a lookup table over all possible parameter values, instead of as an algorithm.
	hidden static [byte[]] reedSolomonComputeDivisor([int] $degree)
	{
		if (($degree -lt 1) -or ($degree -gt 255))
		{
			throw "degree in reedSolomonComputeDivisor is not a valid value. It must range from 1 to 255"
		}
		# Polynomial coefficients are stored from highest to lowest power, excluding the leading term which is always 1.
		# For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array {255, 8, 93}.
		[byte[]] $result = New-Object 'byte[]' $degree
		$result[$degree - 1] = 1 # Start off with the monomial x^0
		
		# Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
		# and drop the highest monomial term which is always 1x^degree.
		# Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
		[int] $root = 1
		for ([int] $i = 0; $i -lt $degree; $i++)
		{
			# Multiply the current product by (x - r^i)
			for ([int] $j = 0; $j -lt $result.length; $j++)
			{
				$result[$j] = [Convert]::ToByte([QrCode]::reedSolomonMultiply($result[$j] -band 0xFF, $root))

				if (($j + 1) -lt $result.length)
				{
					$result[$j] = $result[$j] -bxor $result[$j + 1]
				}
			}
			$root = [QrCode]::reedSolomonMultiply($root, 0x02)
		}
		return $result
	}
	
	
	# Returns the Reed-Solomon error correction codeword for the given data and divisor polynomials.
	hidden static [byte[]] reedSolomonComputeRemainder([byte[]] $data, [byte[]] $divisor)
	{
		if (-not $data)
		{
			throw "data (byte[]) in reedSolomonComputeRemainder is null"
		}
		if (-not $divisor)
		{
			throw "divisor (byte[]) in reedSolomonComputeRemainder is null"
		}
		[byte[]] $result = New-Object 'byte[]' $divisor.length
		foreach ($b in $data) # Polynomial division
		{
			[int] $factor = ($b -bxor $result[0]) -band 0xFF
			# System.arraycopy(result, 1, result, 0, result.length - 1);
            # source_arr : $result
            # sourcePos : 1
            # dest_arr : $result
            # destPos : 0
			# len : $result.length - 1
			$resultClone = $result.Clone()
            for ($counter = 0; $counter -lt ($result.length - 1); $counter++)
            {
                $result[0 + $counter] = $resultClone[1 + $counter]
			}
			$result[$result.length - 1] = 0

			for ([int] $i = 0; $i -lt $result.length; $i++)
			{
				$result[$i] = $result[$i] -bxor [QrCode]::reedSolomonMultiply($divisor[$i] -band 0xFF, $factor)
			}
		}
		return $result
	}
	
	
	# Returns the product of the two given field elements modulo GF(2^8/0x11D). The arguments and result
	# are unsigned 8-bit integers. This could be implemented as a lookup table of 256*256 entries of uint8.
	hidden static [int] reedSolomonMultiply([int] $x, [int] $y)
	{
		if ((($x -shr 8) -ne 0) -or (($y -shr 8) -ne 0))
		{
			throw "x and y in reedSolomonMultiply must be less than 8 bits long"
		}
		# Russian peasant multiplication
		[int] $z = 0
		for ([int] $i = 7; $i -ge 0; $i--)
		{
			$z = ($z -shl 1) -bxor (($z -shr 7) * 0x11D)
			$z = $z -bxor ((($y -shr $i) -band 1) * $x)
		}
		if (($z -shr 8) -ne 0)
		{
			throw "z in reedSolomonMultiply got above 8 bits long"
		}
		return $z
	}
	
	
	# Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
	# QR Code of the given version number and error correction level, with remainder bits discarded.
	# This stateless pure function could be implemented as a (40*4)-cell lookup table.
	static [int] getNumDataCodewords([int] $ver, [Ecc] $ecl)
	{
		return (([Math]::truncate([QrCode]::getNumRawDataModules($ver) / 8)) - ([QrCode]::ECC_CODEWORDS_PER_BLOCK[$ecl.getEccOrdinal()][$ver] * [QrCode]::NUM_ERROR_CORRECTION_BLOCKS[$ecl.getEccOrdinal()][$ver]))
	}
	
	
	# Can only be called immediately after a white run is added, and
	# returns either 0, 1, or 2. A helper function for getPenaltyScore().
	hidden [int] finderPenaltyCountPatterns([int[]] $runHistory)
	{
		[int] $n = $runHistory[1]
		if ($n -gt ($this.size * 3))
		{
			throw "runHistory[1] in finderPenaltyCountPatterns is out of range. It must be less than (this.size * 3)"
		}
		
		[boolean] $core = (($n -gt 0) -and ($runHistory[2] -eq $n) -and ($runHistory[3] -eq ($n * 3)) -and ($runHistory[4] -eq $n) -and ($runHistory[5] -eq $n))
		[int] $tmpA = 0
		[int] $tmpB = 0
		if($runHistory[6] -ge $n){$tmpA = 1}
		if($runHistory[0] -ge $n){$tmpB = 1}
		return ($core -and ($runHistory[0] -ge ($n * 4)) -and ($tmpA)) + ($core -and ($runHistory[6] -ge ($n * 4)) -and ($tmpB))
	}
	
	
	# Must be called at the end of a line (row or column) of modules. A helper function for getPenaltyScore().
	hidden [int] finderPenaltyTerminateAndCount([boolean] $currentRunColor, [int] $currentRunLength, [int[]] $runHistory)
	{
		if ($currentRunColor) # Terminate black run
		{
			$this.finderPenaltyAddHistory($currentRunLength, $runHistory)
			$currentRunLength = 0
		}
		$currentRunLength += $this.size # Add white border to final run
		$this.finderPenaltyAddHistory($currentRunLength, $runHistory)
		return $this.finderPenaltyCountPatterns($runHistory)
	}
	
	
	# Pushes the given value to the front and drops the last value. A helper function for getPenaltyScore().
	hidden finderPenaltyAddHistory([int] $currentRunLength, [int[]] $runHistory)
	{
		if ($runHistory[0] -eq 0)
		{
			$currentRunLength += $this.size # Add white border to initial run
		}
		
		# System.arraycopy($runHistoryClone, 0, $runHistory, 1, $runHistory.length - 1)
		# source_arr : $runHistoryClone
		# sourcePos : 0
		# dest_arr : $runHistory
		# destPos : 1
		# len : $runHistory.length - 1
		$runHistoryClone = $runHistory.Clone()
		for ($counter = 0; $counter -lt ($runHistory.length - 1); $counter++)
		{
			$runHistory[1 + $counter] = $runHistoryClone[0 + $counter]
		}
		$runHistory[0] = $currentRunLength
	}
	
	
	# Returns true iff the i'th bit of x is set to 1.
    static [boolean] getBit([int] $x, [int] $i)
    {
        return ((($x -shr $i) -band 1) -ne 0)
	}
}
#endregion Classes

function New-QrCode {
	<#
	.SYNOPSIS
		Produce a QRCode
	
	.DESCRIPTION
		This Cmdlet can produce a large variety of QRCodes, Monolithic or segmented,
		in all supported formats (Numeric, Alphanumeric, Byte, Kanji, ECI).
		You can generate a QRCode either directly from data, or using QRCode segments
		generated with the New-QrSegment Cmdlet.
	
	.PARAMETER text
		Text to embed in the QRCode.
	
	.PARAMETER segments
		Array of QRCode segments to embed in the QRCode.
	
	.PARAMETER minimumEcc
		This parameter specify the lowest Error Correction Code Level allowed to use.
		Valid values are : "LOW","MEDIUM","QUARTILE", and "HIGH"
	
	.PARAMETER toSvg
		Save the QrCode as a SVG file at the specified path (if only a folder path is specified,
		it will name the file "QrCode_xxx.svg" with xxx being a sequential number).
	
	.PARAMETER toPng
		Save the QrCode as a PNG file at the specified path (if only a folder path is specified,
		it will name the file "QrCode_xxx.png" with xxx being a sequential number).
	
	.PARAMETER toBmp
		Save the QrCode as a BMP file at the specified path (if only a folder path is specified,
		it will name the file "QrCode_xxx.bmp" with xxx being a sequential number).
	
	.PARAMETER scale
		Specify the scale at which the QrCode must be generated (BMP file format).
	
	.PARAMETER forceMask
		This parameter can force the use of a sub obtimal mask (from 0 to 7),
		auto-detect mask (-1, default), and no mask at all (-2).
		The "No Mask" parameter generates an invalid QRCode and must only be used for
		educational purpose.
	
	.PARAMETER quietZone
		This parameter specify the size of the Quiet Zone (border) in modules (wich
		represent the size of a unit square in the QRCode terminology).
		Default size is 2, as requested by the QRCode specification.
		This value is specified in the static variable [QrCode]::DEFAULT_QUIET_ZONE.
	
	.PARAMETER borderSize
		This parameter is an alias for the quietZone parameter.
	
	.PARAMETER invert
		If this switch is present, the QRCode colors will be inverted.
		The same result can be obtained afterwards by using the invert() funtion of
		a QRCode object.

	.PARAMETER disalowEccUpgrade
		If this switch is present, the QRCode will specificaly be generated with the
		specified ECC level, even if it would be possible to have a better ECC at the
		same size.
	
	.PARAMETER asString
		Instead of a QRCode object, the output will be a string suitable for displaying
		the QRCode directly as a console output. The same result can be obtained with
		the toString() funtion of a QRCode object.
	
	.PARAMETER asSvgString
		Instead of a QRCode object, the output will be a SVG-formated string wich can
		be put in a file to make a SVG version of the QRCode. The same result can be
		obtained with the toSvgString() funtion of a QRCode object.
	
	.PARAMETER asBrailleString
		Instead of a QRCode object, the output will be a Unicode string using Braille
		characters for displaying the QRCode directly as a console output.
		Note: The default spacing of most terminal applications can make it unreadable.
		The same result can be obtained with the toSvgString() funtion of a QRCode object.
	
	.PARAMETER noMask
		This noMask switch parameter generates an invalid QRCode and must only be used for
		educational purpose.
		Note: This is equivalent to -forceMask -2
	
	.INPUTS
		The Text parameter can get it's value from the pipeline
	
	.OUTPUTS
		Unless specified otherwise, the output is a QRCode object, and if this object is converted
		into a string, it will be as a Console-Printable QRCode.
	
	.EXAMPLE
		New-QrCode -text "GLD DEMO" -AsString
	
	.LINK
		https://github.com/GregoireLD/Powershell-QrCodeGenerator
	
	.NOTES
		This Cmdlet can make use of New-QrBitBuffer and New-QrSegment Cmdlets.
    #>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(ParameterSetName="FromString",ValueFromPipeline=$true)][string] $text="Sample",
		[Parameter(ParameterSetName="FromSegments")][QrSegment[]] $segments,
		[ValidateSet("LOW","MEDIUM","QUARTILE","HIGH")][string] $minimumEcc="LOW",
		[string] $toSvg,
		[string] $toPng,
		[string] $toBmp,
		[ValidateRange(1,1000)][int] $scale=10,
		[ValidateRange(-2,7)][int] $forceMask=-1,
		[Alias("borderSize")][int] $quietZone=-1,
		[switch] $invert,
		[switch] $disalowEccUpgrade,
		[switch] $asString,
		[switch] $asSvgString,
  		[switch] $asBrailleString,
		[switch] $noMask
	)

	if((([int]([bool]$asString)) + ([int]([bool]$asSvgString)) + ([int]([bool]$asBrailleString))) -gt 1){throw "asString, asSvgString, asBrailleString and are mutually exclusive"}
	if($quietZone -lt 0){throw "quietZone (borderSize) must be equal or greater than zero"}

	[Ecc] $ecl = New-Object 'Ecc' $minimumEcc
	
	[QrCode] $tmpQr = $null

	if($noMask){
		$forceMask = -2
	}

	if($segments)
	{
		$tmpQr = [QrCode]::encodeSegments($segments, $ecl,$forceMask,-not $disalowEccUpgrade)
	}
	else
	{
		$tmpQr = [QrCode]::encodeText($text, $ecl,$forceMask,-not $disalowEccUpgrade)
	}

	if($invert){
		$tmpQr.invert()
	}

	if($quietZone -ne -1){
		$tmpQr.setQuietZone($quietZone)
	} else {
		$tmpQr.setQuietZone([QrCode]::DEFAULT_QUIET_ZONE_SIZE)
	}

	if($toSvg){
		$tmpQr.saveAsSvg($toSvg)
	}

	if($toPng){
		$tmpQr.saveAsPng($toPng,$scale)
	}

	if($toBmp){
		$tmpQr.saveAsBmp($toBmp,$scale)
	}

	if($asString)
	{
		return ($tmpQr.toString())
	}
	
	if($asSvgString)
	{
		return ($tmpQr.toSvgString())
	}

 	if($asBrailleString)
	{
		return ($tmpQr.toBrailleString())
	}
 	
	return ($tmpQr)
}

function New-QrBitBuffer {
	[CmdletBinding()]
	param (
		[string] $binaryString="0000000000000"
	)

	if (-not($binaryString -match [QrCode]::BINARY_REGEX))
		{
			throw "binaryString to use is not a binary string"
		}
	
	return (New-Object 'QrBitBuffer' $binaryString)
}

function New-QrSegment
{
	[CmdletBinding()]
	param (
		[ValidateSet("AUTO","NUMERIC","ALPHANUMERIC","BYTE","KANJI","ECI")][string] $Type="AUTO",
		[QrBitBuffer] $KanjiData,
		[string] $StringData,
		[int] $EciType
	)
	
	if(($Type -eq "KANJI") -and (-not $KanjiData)){throw "KanjiData is mandatory in Kanji mode"}
	if(($Type -eq "ECI") -and (-not $EciType)){throw "EciType is mandatory in ECI mode"}
	if((($Type -eq "AUTO") -or ($Type -eq "NUMERIC") -or ($Type -eq "ALPHANUMERIC") -or ($Type -eq "BYTE")) -and (-not $StringData)){throw "StringData is mandatory in this mode"}

	switch ($Type) {
		"KANJI" {
			[QrMode] $qrmd = New-Object 'QrMode' "KANJI"
			[int]$kanjiLen = [math]::Truncate($KanjiData.getBitLength()/13)
			return (New-Object 'QrSegment' $qrmd, $kanjiLen, $KanjiData)
			}
		"ECI" {
			return [QrSegment]::makeEci($EciType)
			}
		"BYTE" {
			return [QrSegment]::makeBytes( ([system.Text.Encoding]::UTF8).GetBytes($StringData) )
			}
		"NUMERIC" {
			return [QrSegment]::makeNumeric($StringData)
			}
		"ALPHANUMERIC" {
			return [QrSegment]::makeAlphanumeric($StringData)
			}
		Default {} # AUTO
	}

	return ([QrSegment]::makeSegments($StringData))
}
