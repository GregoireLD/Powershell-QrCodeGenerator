enum EccEnum{
    LOW = 1
    MEDIUM = 0
    QUARTILE = 3
    HIGH = 2
}

class Ecc{

	hidden [EccEnum] $ecl

    [int] getValue(){
        [int] $tmpEcl = 1

        switch ($this.ecl) {
            "HIGH" { $tmpEcl = 2 }
            "QUARTILE" { $tmpEcl = 3 }
            "MEDIUM" { $tmpEcl = 0 }
            Default { $tmpEcl = 1 }
        }
        return $tmpEcl
    }

    [int] getOrdinal(){
        [int] $tmpEcl = 0

        switch ($this.ecl) {
            "HIGH" { $tmpEcl = 3 }
            "QUARTILE" { $tmpEcl = 2 }
            "MEDIUM" { $tmpEcl = 1 }
            Default { $tmpEcl = 0 }
        }
        return $tmpEcl
    }

    [Ecc] getHigherEcc(){
        [Ecc] $tmpEcl = New-Object 'Ecc' 1

        switch ($this.ecl) {
            "LOW" { $tmpEcl.setLevelValue(0) }
            "MEDIUM" { $tmpEcl.setLevelValue(3) }
            "QUARTILE" { $tmpEcl.setLevelValue(2) }
            Default {
                # TODO_throw
                # TODO_New
                # throw overHigh
            }
        }
        return $tmpEcl
    }

    [Ecc] getLowerEcc(){
        [Ecc] $tmpEcl = New-Object 'Ecc' 1

        switch ($this.ecl) {
            "HIGH" { $tmpEcl.setLevelValue(3)}
            "QUARTILE" { $tmpEcl.setLevelValue(0) }
            "MEDIUM" { $tmpEcl.setLevelValue(1) }
            Default {
                # TODO_throw
                # TODO_New
                # throw underLow
            }
        }
        return $tmpEcl
    }

    [bool] isMax(){
        if ($this.ecl -eq [EccEnum]::HIGH) {
            return $true
        }
        return $false
    }

    [bool] isMin(){
        if ($this.ecl -eq [EccEnum]::LOW) {
            return $true
        }
        return $false
	}
	
	setLevelValue([int] $val){
		$this.ecl = $val
	}

	Ecc([EccEnum] $val){
		$this.ecl = $val
	}

	Ecc([Ecc] $val){
		$this.ecl = $val.getValue()
	}

}

# Describes how a segment's data bits are interpreted.
enum ModeEnum{
	# -- Constants --
	
	NUMERIC      = @(0x1, 10, 12, 14)
	ALPHANUMERIC = @(0x2,  9, 11, 13)
	BYTE         = @(0x4,  8, 16, 16)
	KANJI        = @(0x8,  8, 10, 12)
	ECI          = @(0x7,  0,  0,  0)
}


class Mode{
	# -- Fields --
	
	# The mode indicator bits, which is a uint4 value (range 0 to 15).
	# [int] modeBits
	
	# Number of character count bits for three different version ranges.
	# hidden [int[]] numBitsCharCount
		
		
	# 	/*-- Constructor --*/
		
	# 	private Mode(int mode, int... ccbits) {
	# 		modeBits = mode;
	# 		numBitsCharCount = ccbits;
	# 	}
		
		
	# 	/*-- Method --*/
		
	# 	// Returns the bit width of the character count field for a segment in this mode
	# 	// in a QR Code at the given version number. The result is in the range [0, 16].
	# 	int numCharCountBits(int ver) {
	# 		assert QrCode.MIN_VERSION <= ver && ver <= QrCode.MAX_VERSION;
	# 		return numBitsCharCount[(ver + 7) / 17];
	# 	}
		
}

class QrCodeGlobal {

    # The minimum version number  (1) supported in the QR Code Model 2 standard.
    static [int] $MIN_VERSION = 1

    # The maximum version number (40) supported in the QR Code Model 2 standard.
    static [int] $MAX_VERSION = 40


    # For use in getPenaltyScore(), when evaluating which mask is best.
    static $PENALTY_N = @(0,3,3,40,10)
    # $PENALTY_N[0] =  0 # Unused, for readability
    # $PENALTY_N[1] =  3
    # $PENALTY_N[2] =  3
    # $PENALTY_N[3] = 40
    # $PENALTY_N[4] = 10


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
}

class BitBuffer {
	# ---- Fields ----

	hidden [string] $data
	hidden [int] $bitLength # Non-negative

	# ---- Constructor ----

	# Constructs an empty bit buffer (length 0).
	BitBuffer()
	{
		$this.data = New-Object 'BitSet'
		$this.bitLength = 0
	}
	
	
	
	# ---- Methods ----
	
	# Returns the length of this sequence, which is a non-negative value.
	# @return the length of this sequence
	[int] bitLength()
	{
		if($this.bitLength -lt 0)
		{
			# ToDo_throw
			# ToDo_new
			# throw AssertNegativeBitLength
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
			# ToDo_throw
			# throw IndexOutOfBoundsException
		}
		$retVal = 0
		if($this.data[$index] -eq "1"){$retVal = 1}
		return $retVal
	}
	
	[string] getAllData()
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
			# ToDo_throw
			# throw IllegalArgumentException("Value out of range")
		}
		if (([int]::MaxValue - $this.bitLength) -lt $len)
		{
			# ToDo_throw
			# throw IllegalStateException("Maximum length reached")
		}
		# for (int i = len - 1; i >= 0; i--, bitLength++)  // Append bit by bit
		# 	data.set(bitLength, QrCode.getBit(val, i));
		$this.data += [Convert]::ToString($val, 2).PadLeft($len, '0')
	}
	
	
	# Appends the content of the specified bit buffer to this buffer.
	# @param bb the bit buffer whose data to append (not {@code null})
	# @throws NullPointerException if the bit buffer is {@code null}
	# @throws IllegalStateException if appending the data
	# would make bitLength exceed Integer.MAX_VALUE
	appendData([BitBuffer] $bb)
	{
		if (-not $bb)
        {
            # TODO_throw
            # TODO_New
            # throw emptyBb
        }
		if (([int]::MaxValue - $this.bitLength) -lt $bb.bitLength)
		{
			# ToDo_throw
			# throw IllegalStateException("Maximum length reached")
		}
		$this.data += $bb.getAllData()
	}
	
	
	# Returns a new copy of this buffer.
	# @return a new copy of this buffer (not {@code null})
	[BitBuffer] clone()
	{
		return (New-Object 'BitBuffer' $this.getAllData())
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
            # TODO_throw
            # TODO_New
            # throw emptyData
		}
		[BitBuffer] $bb = New-Object 'BitBuffer'
	# 	for (byte b : data)
	# 		bb.appendBits(b & 0xFF, 8);

	# 	return new QrSegment(Mode.BYTE, data.length, bb);
		return (New-Object 'QrSegment' [Mode]::BYTE,$data.Length,$bb )
	}
	
	
	# /**
	#  * Returns a segment representing the specified string of decimal digits encoded in numeric mode.
	#  * @param digits the text (not {@code null}), with only digits from 0 to 9 allowed
	#  * @return a segment (not {@code null}) containing the text
	#  * @throws NullPointerException if the string is {@code null}
	#  * @throws IllegalArgumentException if the string contains non-digit characters
	#  */
	# public static QrSegment makeNumeric(String digits) {
	# 	Objects.requireNonNull(digits);
	# 	if (!NUMERIC_REGEX.matcher(digits).matches())
	# 		throw new IllegalArgumentException("String contains non-numeric characters");
		
	# 	BitBuffer bb = new BitBuffer();
	# 	for (int i = 0; i < digits.length(); ) {  // Consume up to 3 digits per iteration
	# 		int n = Math.min(digits.length() - i, 3);
	# 		bb.appendBits(Integer.parseInt(digits.substring(i, i + n)), n * 3 + 1);
	# 		i += n;
	# 	}
	# 	return new QrSegment(Mode.NUMERIC, digits.length(), bb);
	# }
	
	
	# /**
	#  * Returns a segment representing the specified text string encoded in alphanumeric mode.
	#  * The characters allowed are: 0 to 9, A to Z (uppercase only), space,
	#  * dollar, percent, asterisk, plus, hyphen, period, slash, colon.
	#  * @param text the text (not {@code null}), with only certain characters allowed
	#  * @return a segment (not {@code null}) containing the text
	#  * @throws NullPointerException if the string is {@code null}
	#  * @throws IllegalArgumentException if the string contains non-encodable characters
	#  */
	# public static QrSegment makeAlphanumeric(String text) {
	# 	Objects.requireNonNull(text);
	# 	if (!ALPHANUMERIC_REGEX.matcher(text).matches())
	# 		throw new IllegalArgumentException("String contains unencodable characters in alphanumeric mode");
		
	# 	BitBuffer bb = new BitBuffer();
	# 	int i;
	# 	for (i = 0; i <= text.length() - 2; i += 2) {  // Process groups of 2
	# 		int temp = ALPHANUMERIC_CHARSET.indexOf(text.charAt(i)) * 45;
	# 		temp += ALPHANUMERIC_CHARSET.indexOf(text.charAt(i + 1));
	# 		bb.appendBits(temp, 11);
	# 	}
	# 	if (i < text.length())  // 1 character remaining
	# 		bb.appendBits(ALPHANUMERIC_CHARSET.indexOf(text.charAt(i)), 6);
	# 	return new QrSegment(Mode.ALPHANUMERIC, text.length(), bb);
	# }
	
	
	# /**
	#  * Returns a list of zero or more segments to represent the specified Unicode text string.
	#  * The result may use various segment modes and switch modes to optimize the length of the bit stream.
	#  * @param text the text to be encoded, which can be any Unicode string
	#  * @return a new mutable list (not {@code null}) of segments (not {@code null}) containing the text
	#  * @throws NullPointerException if the text is {@code null}
	#  */
	# public static List<QrSegment> makeSegments(String text) {
	# 	Objects.requireNonNull(text);
		
	# 	// Select the most efficient segment encoding automatically
	# 	List<QrSegment> result = new ArrayList<>();
	# 	if (text.equals(""));  // Leave result empty
	# 	else if (NUMERIC_REGEX.matcher(text).matches())
	# 		result.add(makeNumeric(text));
	# 	else if (ALPHANUMERIC_REGEX.matcher(text).matches())
	# 		result.add(makeAlphanumeric(text));
	# 	else
	# 		result.add(makeBytes(text.getBytes(StandardCharsets.UTF_8)));
	# 	return result;
	# }
	
	
	# /**
	#  * Returns a segment representing an Extended Channel Interpretation
	#  * (ECI) designator with the specified assignment value.
	#  * @param assignVal the ECI assignment number (see the AIM ECI specification)
	#  * @return a segment (not {@code null}) containing the data
	#  * @throws IllegalArgumentException if the value is outside the range [0, 10<sup>6</sup>)
	#  */
	# public static QrSegment makeEci(int assignVal) {
	# 	BitBuffer bb = new BitBuffer();
	# 	if (assignVal < 0)
	# 		throw new IllegalArgumentException("ECI assignment value out of range");
	# 	else if (assignVal < (1 << 7))
	# 		bb.appendBits(assignVal, 8);
	# 	else if (assignVal < (1 << 14)) {
	# 		bb.appendBits(2, 2);
	# 		bb.appendBits(assignVal, 14);
	# 	} else if (assignVal < 1_000_000) {
	# 		bb.appendBits(6, 3);
	# 		bb.appendBits(assignVal, 21);
	# 	} else
	# 		throw new IllegalArgumentException("ECI assignment value out of range");
	# 	return new QrSegment(Mode.ECI, 0, bb);
	# }
	
	
	
	# /*---- Instance fields ----*/
	
	# /** The mode indicator of this segment. Not {@code null}. */
	# public final Mode mode;
	
	# /** The length of this segment's unencoded data. Measured in characters for
	#  * numeric/alphanumeric/kanji mode, bytes for byte mode, and 0 for ECI mode.
	#  * Always zero or positive. Not the same as the data's bit length. */
	# public final int numChars;
	
	# // The data bits of this segment. Not null. Accessed through getData().
	# final BitBuffer data;
	
	
	# /*---- Constructor (low level) ----*/
	
	# /**
	#  * Constructs a QR Code segment with the specified attributes and data.
	#  * The character count (numCh) must agree with the mode and the bit buffer length,
	#  * but the constraint isn't checked. The specified bit buffer is cloned and stored.
	#  * @param md the mode (not {@code null})
	#  * @param numCh the data length in characters or bytes, which is non-negative
	#  * @param data the data bits (not {@code null})
	#  * @throws NullPointerException if the mode or data is {@code null}
	#  * @throws IllegalArgumentException if the character count is negative
	#  */
	# public QrSegment(Mode md, int numCh, BitBuffer data) {
	# 	mode = Objects.requireNonNull(md);
	# 	Objects.requireNonNull(data);
	# 	if (numCh < 0)
	# 		throw new IllegalArgumentException("Invalid value");
	# 	numChars = numCh;
	# 	this.data = data.clone();  // Make defensive copy
	# }
	
	
	# /*---- Methods ----*/
	
	# /**
	#  * Returns the data bits of this segment.
	#  * @return a new copy of the data bits (not {@code null})
	#  */
	# public BitBuffer getData() {
	# 	return data.clone();  // Make defensive copy
	# }
	
	
	# // Calculates the number of bits needed to encode the given segments at the given version.
	# // Returns a non-negative number if successful. Otherwise returns -1 if a segment has too
	# // many characters to fit its length field, or the total bits exceeds Integer.MAX_VALUE.
	# static int getTotalBits(List<QrSegment> segs, int version) {
	# 	Objects.requireNonNull(segs);
	# 	long result = 0;
	# 	for (QrSegment seg : segs) {
	# 		Objects.requireNonNull(seg);
	# 		int ccbits = seg.mode.numCharCountBits(version);
	# 		if (seg.numChars >= (1 << ccbits))
	# 			return -1;  // The segment's length doesn't fit the field's bit width
	# 		result += 4L + ccbits + seg.data.bitLength();
	# 		if (result > Integer.MAX_VALUE)
	# 			return -1;  // The sum will overflow an int type
	# 	}
	# 	return (int)result;
	# }
	
	
	# /*---- Constants ----*/
	
	# /** Describes precisely all strings that are encodable in numeric mode. To test whether a
	#  * string {@code s} is encodable: {@code boolean ok = NUMERIC_REGEX.matcher(s).matches();}.
	#  * A string is encodable iff each character is in the range 0 to 9.
	#  * @see #makeNumeric(String) */
	# public static final Pattern NUMERIC_REGEX = Pattern.compile("[0-9]*");
	
	# /** Describes precisely all strings that are encodable in alphanumeric mode. To test whether a
	#  * string {@code s} is encodable: {@code boolean ok = ALPHANUMERIC_REGEX.matcher(s).matches();}.
	#  * A string is encodable iff each character is in the following set: 0 to 9, A to Z
	#  * (uppercase only), space, dollar, percent, asterisk, plus, hyphen, period, slash, colon.
	#  * @see #makeAlphanumeric(String) */
	# public static final Pattern ALPHANUMERIC_REGEX = Pattern.compile("[A-Z0-9 $%*+./:-]*");
	
	# // The set of all legal characters in alphanumeric mode, where
	# // each character value maps to the index in the string.
	# static final String ALPHANUMERIC_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

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
    static [QrCode] encodeText([string] $text, [Ecc] $ecl)
    {
        if (-not $text)
        {
            # TODO_throw
            # TODO_New
            # throw emptyText
        }
        if (-not $ecl)
        {
            # TODO_throw
            # TODO_New
            # throw emptyEcl
        }
        # TODO_Func makeSegments
		[QrSegment[]] $segs = [QrSegment]::makeSegments($text)
        return encodeSegments($segs, $ecl)
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
    static [QrCode] encodeBinary([byte[]] $data, [Ecc] $ecl)
    {
		if (-not $data)
        {
            # TODO_throw
            # TODO_New
            # throw emptyData
        }
        if (-not $ecl)
        {
            # TODO_throw
            # TODO_New
            # throw emptyEcl
        }
        # TODO_Func makeBytes
		[QrSegment] $seg = [QrSegment]::makeBytes($data)
        return encodeSegments($seg, $ecl)
	}
	
	
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
	static [QrCode] encodeSegments([QrSegment[]] $segs, [Ecc] $ecl) {
        return encodeSegments($segs, $ecl, [QrCodeGlobal]::MIN_VERSION, [QrCodeGlobal]::MAX_VERSION, -1, $true)
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
            # TODO_throw
            # TODO_New
            # throw emptySegs
        }
        if (-not $ecl)
        {
            # TODO_throw
            # TODO_New
            # throw emptyEcl
        }

        if ( -not ((([QrCodeGlobal]::MIN_VERSION -le $minVersion) -and ($minVersion -le $maxVersion) -and ($maxVersion -le [QrCodeGlobal]::MAX_VERSION)) -or ($mask -lt -1) -or ($mask -gt 7)))
        {
            # TODO_throw
            # throw new IllegalArgumentException("Invalid value");
        }
		
		
		# Find the minimal version number to use
        [int] $tmpVersion = 0
        [int] $dataUsedBits = 0

        $continueLoop = $true
        $tmpVersion = $minVersion - 1
        while ($continueLoop) {
            $tmpVersion++

		    [int] $dataCapacityBits = [QrCode]::getNumDataCodewords($tmpVersion, $ecl) * 8 # Number of data bits available
            # TODO_Func getTotalBits
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
                    
                    # TODO_throw
                    # throw new DataTooLongException($msg);
                }
            }
        }

        if ($dataUsedBits -eq -1)
        {
            # TODO_throw
            # TODO_New
            # throw errorAssertDataUsedBits
        }
		
		# Increase the error correction level while the data still fits in the current version number
        if($boostEcl)
        {
            do {
                $nextEcl = $ecl.getHigherEcc()
                if ($dataUsedBits -le ([QrCode]::getNumDataCodewords($tmpVersion, $nextEcl) * 8))
                {
                    $ecl = $nextEcl
                }
            } until ($nextEcl.isMax())
        }
		
        # Concatenate all segments to create the data bit string
        
		[string] $bb = ""
        foreach ($seg in $segs)
        {
            $bb += $seg.mode.modeBits, 4
            $bb += [Convert]::ToString($seg.mode.modeBits, 2).PadLeft(4, '0')
            $bb += [Convert]::ToString($seg.numChars, 2).PadLeft($seg.mode.numCharCountBits($tmpVersion), '0')
			$bb += $seg.data
        }
        
        if ($false)
        {
            # TODO_throw
            # TODO_New
            # throw errorAssertbbbitLength
            # assert bb.bitLength() == dataUsedBits;
        }
		
        # Add terminator and pad up to a byte if applicable
		[int] $dataCapacityBits = [QrCode]::getNumDataCodewords($tmpVersion, $ecl) * 8

        if ($false)
        {
            # TODO_throw
            # TODO_New
            # throw errorAssertbbbitLength
            # assert bb.bitLength() <= dataCapacityBits;
        }
        $padSize = [Math]::Min(4,$dataCapacityBits - $bb.Length)
        $padSizeModulo = (8 - ($bb.Length % 8)) % 8

        $bb += [Convert]::ToString(0, 2).PadLeft($padSize, '0')
        $bb += [Convert]::ToString(0, 2).PadLeft($padSizeModulo, '0')

        if (($bb.Length % 8) -ne 0)
        {
            # TODO_throw
            # TODO_New
            # throw errorAssertBitLengthModulo
        }
		
		# Pad with alternating bytes until data capacity is reached
		for ([int] $padByte = 0xEC; $bb.Length -lt $dataCapacityBits; $padByte -bxor (0xEC -bxor 0x11))
        {
            $bb += [Convert]::ToString($padByte, 2).PadLeft(8, '0')
        }
		
		# Pack bits into bytes in big endian
		[byte[]] $dataCodewords = New-Object 'byte[]' ($bb.Length / 8)
        for ([int] $i = 0; $i -lt $bb.Length; $i++) {
            # $tmpValue = dataCodewords[i >>> 3] | bb.getBit(i) << (7 - (i & 7));
            $tmpValue = ($dataCodewords[ (($i -shr 1) -band 127) ] -bor [Convert]::ToInt16($bb[$i])) -shl (7 - ($i -band 7))
            $dataCodewords[ (($i -shr 1) -band 127) ] = $tmpValue
        }

		# Create the QR Code object
        return New-Object '[QrCode]' $tmpVersion, $ecl, $dataCodewords, $mask
	}
	
	
	
	# ---- Instance fields ----
	
	# Public immutable scalar parameters:
	
    # The version number of this QR Code, which is between 1 and 40 (inclusive).
	# This determines the size of this barcode.
    [int] $version

    # The width and height of this QR Code, measured in modules, between
	# 21 and 177 (inclusive). This is equal to version &#xD7; 4 + 17.
    [int] $size

    # /** The error correction level used in this QR Code, which is not {@code null}. */
	[Ecc] $errorCorrectionLevel
	
	# /** The index of the mask pattern used in this QR Code, which is between 0 and 7 (inclusive).
	#  * <p>Even if a QR Code is created with automatic masking requested (mask =
	#  * &#x2212;1), the resulting object still has a mask value between 0 and 7. */
	[int] $mask
	
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
        if (($ver -lt [QrCodeGlobal]::MIN_VERSION) -or ($ver -gt [QrCodeGlobal]::MAX_VERSION))
        {
            # TODO_throw
            # throw new IllegalArgumentException("Version value out of range");
        }
		
        if (($msk -lt -1) -or ($msk -gt 7))
        {
            # TODO_throw
            # throw new IllegalArgumentException("Mask value out of range");
        }

		$this.version = $ver
        $this.size = ($ver * 4) + 17
        $this.errorCorrectionLevel = New-Object 'Ecc' $ecl;
        if (-not $dataCodewords)
        {
            # TODO_throw
            # TODO_New
            # throw emptydataCodewords
        }
        $this.modules = New-Object 'boolean[][]' $this.size,$this.size # Initially all white
		$this.isFunction = New-Object 'boolean[][]' $this.size,$this.size
		
        # Compute ECC, draw modules, do masking
        $this.drawFunctionPatterns()
		[byte[]] $allCodewords = $this.addEccAndInterleave($dataCodewords)
        $this.drawCodewords($allCodewords)
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
	
	
	# Returns a raster image depicting this QR Code, with the specified module scale and border modules.
	# <p>For example, toImage(scale=10, border=4) means to pad the QR Code with 4 white
	# border modules on all four sides, and use 10&#xD7;10 pixels to represent each module.
	# The resulting image only contains the hex colors 000000 and FFFFFF.
	# @param scale the side length (measured in pixels, must be positive) of each module
	# @param border the number of border modules to add, which must be non-negative
	# @return a new image representing this QR Code, with padding and scaling
	# @throws IllegalArgumentException if the scale or border is out of range, or if
    # {scale, border, size} cause the image dimensions to exceed Integer.MAX_VALUE
    # ToDo Export PNG
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
	
	
	# Returns a string of SVG code for an image depicting this QR Code, with the specified number
	# of border modules. The string always uses Unix newlines (\n), regardless of the platform.
	# @param border the number of border modules to add, which must be non-negative
	# @return a string representing this QR Code as an SVG XML document
	# @throws IllegalArgumentException if the border is negative
    # ToDo Export SVG
	# public String toSvgString(int border) {
	# 	if (border < 0)
	# 		throw new IllegalArgumentException("Border must be non-negative");
	# 	long brd = border;
	# 	StringBuilder sb = new StringBuilder()
	# 		.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
	# 		.append("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n")
	# 		.append(String.format("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"0 0 %1$d %1$d\" stroke=\"none\">\n",
	# 			size + brd * 2))
	# 		.append("\t<rect width=\"100%\" height=\"100%\" fill=\"#FFFFFF\"/>\n")
	# 		.append("\t<path d=\"");
	# 	for (int y = 0; y < size; y++) {
	# 		for (int x = 0; x < size; x++) {
	# 			if (getModule(x, y)) {
	# 				if (x != 0 || y != 0)
	# 					sb.append(" ");
	# 				sb.append(String.format("M%d,%dh1v1h-1z", x + brd, y + brd));
	# 			}
	# 		}
	# 	}
	# 	return sb
	# 		.append("\" fill=\"#000000\"/>\n")
	# 		.append("</svg>\n")
	# 		.toString();
	# }
	
	
	
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
            for ([int] $j = 0; $j -lt $numAlign; $++)
            {
                # Don't draw on the three finder corners
                if ( -not (($i -eq 0) -and ($j -eq 0) -or ($i -eq 0) -and ($j -eq ($numAlign - 1)) -or ($i -eq ($numAlign - 1)) -and ($j -eq 0)))
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
        [int] $data = ($this.errorCorrectionLevel.getValue -shl 3) -bor $msk # errCorrLvl is uint2, mask is uint3
        [int] $rem = $data
        for ([int] $i = 0; $i -lt 10; $i++)
        {
            $rem = ($rem -shl 1) -bxor (($rem -shr 9) * 0x537)
        }
        
        [int] $bits = ($data -shl 10 -bor $rem) -bxor 0x5412 # uint15

        if (($bits -shr 15) -ne 0)
        {
            # TODO_throw
            # TODO_New
            # throw errorAssertBitsZeroed15
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
            # TODO_throw
            # TODO_New
            # throw errorAssertBitsZeroed18
        }
        
        # Draw two copies
        for ([int] $i = 0; $i -lt 18; $i++)
        {
            [boolean] $bit = [QrCode]::getBit($bits, $i)
            [int] $a = $this.size - 11 + ($i % 3)
            [int] $b = $i / 3
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
            # TODO_throw
            # TODO_New
            # throw emptyData
        }
        if ($data.length -ne [QrCode]::getNumDataCodewords($this.version, $this.errorCorrectionLevel))
        {
            # TODO_throw
            # throw IllegalArgumentException
        }
        
        # Calculate parameter numbers
        [int] $numBlocks = [QrCodeGlobal]::NUM_ERROR_CORRECTION_BLOCKS[$this.errorCorrectionLevel.getOrdinal()][$this.version]
        [int] $blockEccLen = [QrCodeGlobal]::ECC_CODEWORDS_PER_BLOCK[$this.errorCorrectionLevel.getOrdinal()][$this.version]
        [int] $rawCodewords = [QrCode]::getNumRawDataModules($this.version) / 8
        [int] $numShortBlocks = $numBlocks - ($rawCodewords % $numBlocks)
        [int] $shortBlockLen = $rawCodewords / $numBlocks
        
        # Split data into blocks and append ECC to each block
        [byte[][]] $blocks = New-Object 'byte[][]' $numBlocks
        [byte[]] $rsDiv = [QrCode]::reedSolomonComputeDivisor($blockEccLen)
        [int] $k = 0
        for ([int] $i = 0; $i -lt $numBlocks; $i++)
        {
            if($numShortBlocks){$boolNSB = 0}else{$boolNSB = 1}
            $newSize = $shortBlockLen - $blockEccLen + ($i -lt $boolNSB)
            [byte[]] $dat = New-Object 'byte[]' $newSize
            $loopSize = [Math]::Min($this.data, $newSize)
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
            # TODO_throw
            # TODO_New
            # throw emptyData
		}
		
		if ($this.data.length -ne ([QrCode]::getNumRawDataModules($this.version) / 8))
		{
			# TODO_throw
			# throw IllegalArgumentException();
		}

		[int] $i = 0 # Bit index into the data
		# Do the funny zigzag scan
		for ([int] $right = $this.size - 1; $right -ge 1; $right -= 2)
		{ # Index of right column in each column pair
			if ($right == 6){$right = 5}
			for ([int] $vert = 0; $vert -lt $this.size; $vert++)
			{ # Vertical counter
				for ([int] $j = 0; $j -lt 2; $j++)
				{
					[int] $x = $right - $j # Actual x coordinate
					[boolean] $upward = (($right + 1) -band 2) -eq 0
					[int] $y = $vert
					if ($upward) {$y = ($this.size - 1 - $vert)} # Actual y coordinate
					if ( -not (($this.isFunction[$y][$x] -and $i) -lt ($this.data.length * 8)))
					{
						$this.modules[$y][$x] = [QrCode]::getBit($this.data[($i -shr 3)], 7 - ($i -band 7))
						$i++
					}
					# If this QR Code has any remainder bits (0 to 7), they were assigned as
					# 0/false/white by the constructor and are left unchanged by this method
				}
			}
		}
		if ($i -ne ($this.data.length * 8))
		{
			# TODO_throw
			# TODO_New
			# throw errorAssertIDataLenght
		}
    }
	
	
	# // XORs the codeword modules in this QR Code with the given mask pattern.
	# // The function modules must be marked and the codeword bits must be drawn
	# // before masking. Due to the arithmetic of XOR, calling applyMask() with
	# // the same mask value a second time will undo the mask. A final well-formed
	# // QR Code needs exactly one (not zero, two, etc.) mask applied.
	# private void applyMask(int msk) {
	# 	if (msk < 0 || msk > 7)
	# 		throw new IllegalArgumentException("Mask value out of range");
	# 	for (int y = 0; y < size; y++) {
	# 		for (int x = 0; x < size; x++) {
	# 			boolean invert;
	# 			switch (msk) {
	# 				case 0:  invert = (x + y) % 2 == 0;                    break;
	# 				case 1:  invert = y % 2 == 0;                          break;
	# 				case 2:  invert = x % 3 == 0;                          break;
	# 				case 3:  invert = (x + y) % 3 == 0;                    break;
	# 				case 4:  invert = (x / 3 + y / 2) % 2 == 0;            break;
	# 				case 5:  invert = x * y % 2 + x * y % 3 == 0;          break;
	# 				case 6:  invert = (x * y % 2 + x * y % 3) % 2 == 0;    break;
	# 				case 7:  invert = ((x + y) % 2 + x * y % 3) % 2 == 0;  break;
	# 				default:  throw new AssertionError();
	# 			}
	# 			modules[y][x] ^= invert & !isFunction[y][x];
	# 		}
	# 	}
	# }
	
	
	# // A messy helper function for the constructor. This QR Code must be in an unmasked state when this
	# // method is called. The given argument is the requested mask, which is -1 for auto or 0 to 7 for fixed.
	# // This method applies and returns the actual mask chosen, from 0 to 7.
	# private int handleConstructorMasking(int msk) {
	# 	if (msk == -1) {  // Automatically choose best mask
	# 		int minPenalty = Integer.MAX_VALUE;
	# 		for (int i = 0; i < 8; i++) {
	# 			applyMask(i);
	# 			drawFormatBits(i);
	# 			int penalty = getPenaltyScore();
	# 			if (penalty < minPenalty) {
	# 				msk = i;
	# 				minPenalty = penalty;
	# 			}
	# 			applyMask(i);  // Undoes the mask due to XOR
	# 		}
	# 	}
	# 	assert 0 <= msk && msk <= 7;
	# 	applyMask(msk);  // Apply the final choice of mask
	# 	drawFormatBits(msk);  // Overwrite old format bits
	# 	return msk;  // The caller shall assign this value to the final-declared field
	# }
	
	
	# // Calculates and returns the penalty score based on state of this QR Code's current modules.
	# // This is used by the automatic mask choice algorithm to find the mask pattern that yields the lowest score.
	# private int getPenaltyScore() {
	# 	int result = 0;
		
	# 	// Adjacent modules in row having same color, and finder-like patterns
	# 	for (int y = 0; y < size; y++) {
	# 		boolean runColor = false;
	# 		int runX = 0;
	# 		int[] runHistory = new int[7];
	# 		for (int x = 0; x < size; x++) {
	# 			if (modules[y][x] == runColor) {
	# 				runX++;
	# 				if (runX == 5)
	# 					result += PENALTY_N1;
	# 				else if (runX > 5)
	# 					result++;
	# 			} else {
	# 				finderPenaltyAddHistory(runX, runHistory);
	# 				if (!runColor)
	# 					result += finderPenaltyCountPatterns(runHistory) * PENALTY_N3;
	# 				runColor = modules[y][x];
	# 				runX = 1;
	# 			}
	# 		}
	# 		result += finderPenaltyTerminateAndCount(runColor, runX, runHistory) * PENALTY_N3;
	# 	}
	# 	// Adjacent modules in column having same color, and finder-like patterns
	# 	for (int x = 0; x < size; x++) {
	# 		boolean runColor = false;
	# 		int runY = 0;
	# 		int[] runHistory = new int[7];
	# 		for (int y = 0; y < size; y++) {
	# 			if (modules[y][x] == runColor) {
	# 				runY++;
	# 				if (runY == 5)
	# 					result += PENALTY_N1;
	# 				else if (runY > 5)
	# 					result++;
	# 			} else {
	# 				finderPenaltyAddHistory(runY, runHistory);
	# 				if (!runColor)
	# 					result += finderPenaltyCountPatterns(runHistory) * PENALTY_N3;
	# 				runColor = modules[y][x];
	# 				runY = 1;
	# 			}
	# 		}
	# 		result += finderPenaltyTerminateAndCount(runColor, runY, runHistory) * PENALTY_N3;
	# 	}
		
	# 	// 2*2 blocks of modules having same color
	# 	for (int y = 0; y < size - 1; y++) {
	# 		for (int x = 0; x < size - 1; x++) {
	# 			boolean color = modules[y][x];
	# 			if (  color == modules[y][x + 1] &&
	# 			      color == modules[y + 1][x] &&
	# 			      color == modules[y + 1][x + 1])
	# 				result += PENALTY_N2;
	# 		}
	# 	}
		
	# 	// Balance of black and white modules
	# 	int black = 0;
	# 	for (boolean[] row : modules) {
	# 		for (boolean color : row) {
	# 			if (color)
	# 				black++;
	# 		}
	# 	}
	# 	int total = size * size;  // Note that size is odd, so black/total != 1/2
	# 	// Compute the smallest integer k >= 0 such that (45-5k)% <= black/total <= (55+5k)%
	# 	int k = (Math.abs(black * 20 - total * 10) + total - 1) / total - 1;
	# 	result += k * PENALTY_N4;
	# 	return result;
	# }
	
	
	
	# /*---- Private helper functions ----*/
	
	# // Returns an ascending list of positions of alignment patterns for this version number.
	# // Each position is in the range [0,177), and are used on both the x and y axes.
	# // This could be implemented as lookup table of 40 variable-length lists of unsigned bytes.
    hidden [int[]] getAlignmentPatternPositions()
    {
	# 	if (version == 1)
	# 		return new int[]{};
	# 	else {
	# 		int numAlign = version / 7 + 2;
	# 		int step;
	# 		if (version == 32)  // Special snowflake
	# 			step = 26;
	# 		else  // step = ceil[(size - 13) / (numAlign*2 - 2)] * 2
	# 			step = (version*4 + numAlign*2 + 1) / (numAlign*2 - 2) * 2;
	# 		int[] result = new int[numAlign];
	# 		result[0] = 6;
	# 		for (int i = result.length - 1, pos = size - 7; i >= 1; i--, pos -= step)
	# 			result[i] = pos;
	# 		return result;
    # 	}
        return $null
    }
	
	
	# // Returns the number of data bits that can be stored in a QR Code of the given version number, after
	# // all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
	# // The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
	# private static int getNumRawDataModules(int ver) {
	# 	if (ver < MIN_VERSION || ver > MAX_VERSION)
	# 		throw new IllegalArgumentException("Version number out of range");
		
	# 	int size = ver * 4 + 17;
	# 	int result = size * size;   // Number of modules in the whole QR Code square
	# 	result -= 8 * 8 * 3;        // Subtract the three finders with separators
	# 	result -= 15 * 2 + 1;       // Subtract the format information and black module
	# 	result -= (size - 16) * 2;  // Subtract the timing patterns (excluding finders)
	# 	// The five lines above are equivalent to: int result = (16 * ver + 128) * ver + 64;
	# 	if (ver >= 2) {
	# 		int numAlign = ver / 7 + 2;
	# 		result -= (numAlign - 1) * (numAlign - 1) * 25;  // Subtract alignment patterns not overlapping with timing patterns
	# 		result -= (numAlign - 2) * 2 * 20;  // Subtract alignment patterns that overlap with timing patterns
	# 		// The two lines above are equivalent to: result -= (25 * numAlign - 10) * numAlign - 55;
	# 		if (ver >= 7)
	# 			result -= 6 * 3 * 2;  // Subtract version information
	# 	}
	# 	assert 208 <= result && result <= 29648;
	# 	return result;
	# }
	
	
	# // Returns a Reed-Solomon ECC generator polynomial for the given degree. This could be
	# // implemented as a lookup table over all possible parameter values, instead of as an algorithm.
	# private static byte[] reedSolomonComputeDivisor(int degree) {
	# 	if (degree < 1 || degree > 255)
	# 		throw new IllegalArgumentException("Degree out of range");
	# 	// Polynomial coefficients are stored from highest to lowest power, excluding the leading term which is always 1.
	# 	// For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array {255, 8, 93}.
	# 	byte[] result = new byte[degree];
	# 	result[degree - 1] = 1;  // Start off with the monomial x^0
		
	# 	// Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
	# 	// and drop the highest monomial term which is always 1x^degree.
	# 	// Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
	# 	int root = 1;
	# 	for (int i = 0; i < degree; i++) {
	# 		// Multiply the current product by (x - r^i)
	# 		for (int j = 0; j < result.length; j++) {
	# 			result[j] = (byte)reedSolomonMultiply(result[j] & 0xFF, root);
	# 			if (j + 1 < result.length)
	# 				result[j] ^= result[j + 1];
	# 		}
	# 		root = reedSolomonMultiply(root, 0x02);
	# 	}
	# 	return result;
	# }
	
	
	# // Returns the Reed-Solomon error correction codeword for the given data and divisor polynomials.
	# private static byte[] reedSolomonComputeRemainder(byte[] data, byte[] divisor) {
	# 	Objects.requireNonNull(data);
	# 	Objects.requireNonNull(divisor);
	# 	byte[] result = new byte[divisor.length];
	# 	for (byte b : data) {  // Polynomial division
	# 		int factor = (b ^ result[0]) & 0xFF;
	# 		System.arraycopy(result, 1, result, 0, result.length - 1);
	# 		result[result.length - 1] = 0;
	# 		for (int i = 0; i < result.length; i++)
	# 			result[i] ^= reedSolomonMultiply(divisor[i] & 0xFF, factor);
	# 	}
	# 	return result;
	# }
	
	
	# // Returns the product of the two given field elements modulo GF(2^8/0x11D). The arguments and result
	# // are unsigned 8-bit integers. This could be implemented as a lookup table of 256*256 entries of uint8.
	# private static int reedSolomonMultiply(int x, int y) {
	# 	assert x >> 8 == 0 && y >> 8 == 0;
	# 	// Russian peasant multiplication
	# 	int z = 0;
	# 	for (int i = 7; i >= 0; i--) {
	# 		z = (z << 1) ^ ((z >>> 7) * 0x11D);
	# 		z ^= ((y >>> i) & 1) * x;
	# 	}
	# 	assert z >>> 8 == 0;
	# 	return z;
	# }
	
	
	# // Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
	# // QR Code of the given version number and error correction level, with remainder bits discarded.
	# // This stateless pure function could be implemented as a (40*4)-cell lookup table.
	# static int getNumDataCodewords(int ver, Ecc ecl) {
	# 	return getNumRawDataModules(ver) / 8
	# 		- ECC_CODEWORDS_PER_BLOCK    [ecl.ordinal()][ver]
	# 		* NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal()][ver];
	# }
	
	
	# // Can only be called immediately after a white run is added, and
	# // returns either 0, 1, or 2. A helper function for getPenaltyScore().
	# private int finderPenaltyCountPatterns(int[] runHistory) {
	# 	int n = runHistory[1];
	# 	assert n <= size * 3;
	# 	boolean core = n > 0 && runHistory[2] == n && runHistory[3] == n * 3 && runHistory[4] == n && runHistory[5] == n;
	# 	return (core && runHistory[0] >= n * 4 && runHistory[6] >= n ? 1 : 0)
	# 	     + (core && runHistory[6] >= n * 4 && runHistory[0] >= n ? 1 : 0);
	# }
	
	
	# // Must be called at the end of a line (row or column) of modules. A helper function for getPenaltyScore().
	# private int finderPenaltyTerminateAndCount(boolean currentRunColor, int currentRunLength, int[] runHistory) {
	# 	if (currentRunColor) {  // Terminate black run
	# 		finderPenaltyAddHistory(currentRunLength, runHistory);
	# 		currentRunLength = 0;
	# 	}
	# 	currentRunLength += size;  // Add white border to final run
	# 	finderPenaltyAddHistory(currentRunLength, runHistory);
	# 	return finderPenaltyCountPatterns(runHistory);
	# }
	
	
	# // Pushes the given value to the front and drops the last value. A helper function for getPenaltyScore().
	# private void finderPenaltyAddHistory(int currentRunLength, int[] runHistory) {
	# 	if (runHistory[0] == 0)
	# 		currentRunLength += size;  // Add white border to initial run
	# 	System.arraycopy(runHistory, 0, runHistory, 1, runHistory.length - 1);
	# 	runHistory[0] = currentRunLength;
	# }
	
	
	# Returns true iff the i'th bit of x is set to 1.
    static [boolean] getBit([int] $x, [int] $i)
    {
        return ((($x -shr $i) -band 1) -ne 0)
	}
}
