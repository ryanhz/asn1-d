/**
    Distinguished Encoding Rules (DER) is a standard for encoding ASN.1 data.
    DER is often used for cryptgraphically-signed data, such as X.509
    certificates, because DER's defining feature is that there is only one way
    to encode each data type, which means that two encodings of the same data
    could not have different cryptographic signatures. For this reason, DER
    is generally regarded as the most secure encoding standard for ASN.1.
    Like Basic Encoding Rules (BER), Canonical Encoding Rules (CER), and
    Packed Encoding Rules (PER), Distinguished Encoding Rules (DER) is a
    specification created by the
    $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union),
    and specified in
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

    Authors:
    $(UL
        $(LI $(PERSON Jonathan M. Wilbur, jonathan@wilbur.space, http://jonathan.wilbur.space))
    )
    Copyright: Copyright (C) Jonathan M. Wilbur
    License: $(LINK https://mit-license.org/, MIT License)
    Standards:
    $(UL
        $(LI $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)))
        $(LI $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules))
    )
    See_Also:
    $(UL
        $(LI $(LINK https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1))
        $(LI $(LINK https://en.wikipedia.org/wiki/X.690, The Wikipedia Page on X.690))
        $(LI $(LINK https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words))
        $(LI $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems))
    )
*/
module asn1.codecs.der;
public import asn1.codec;
public import asn1.interfaces : Byteable;
public import asn1.types.identification;

///
public alias derOID = distinguishedEncodingRulesObjectIdentifier;
///
public alias derObjectID = distinguishedEncodingRulesObjectIdentifier;
///
public alias derObjectIdentifier = distinguishedEncodingRulesObjectIdentifier;
/**
    The object identifier assigned to the Distinguished Encoding Rules (DER), per the
    $(LINK https://www.itu.int/en/pages/default.aspx,
        International Telecommunications Union)'s,
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

    $(MONO {joint-iso-itu-t asn1(1) ber-derived(2) distinguished-encoding(1)} )
*/
public immutable OID distinguishedEncodingRulesObjectIdentifier = cast(immutable(OID)) new OID(2, 1, 2, 1);

///
public alias DERElement = DistinguishedEncodingRulesElement;
/**
    The unit of encoding and decoding for Distinguished Encoding Rules (DER).

    There are three parts to an element encoded according to the Distinguished
    Encoding Rules (DER):

    $(UL
        $(LI A Type Tag, which specifies what data type is encoded)
        $(LI A Length Tag, which specifies how many subsequent bytes encode the data)
        $(LI The Encoded Value)
    )

    They appear in the binary encoding in that order, and as such, the encoding
    scheme is sometimes described as "TLV," which stands for Type-Length-Value.

    This class provides a properties for getting and setting bit fields of
    the type tag, but most of it is functionality for encoding data per
    the specification.

    As an example, this is what encoding a simple INTEGER looks like:

    ---
    DERElement dv = new DERElement();
    dv.tagNumber = 0x02u; // "2" means this is an INTEGER
    dv.integer = 1433; // Now the data is encoded.
    transmit(cast(ubyte[]) dv); // transmit() is a made-up function.
    ---

    And this is what decoding looks like:

    ---
    ubyte[] data = receive(); // receive() is a made-up function.
    DERElement dv2 = new DERElement(data);

    long x;
    if (dv.tagNumber == 0x02u) // it is an INTEGER
    {
        x = dv.integer;
    }
    // Now x is 1433!
    ---
*/
/* FIXME:
    This class should be "final," but a bug in the DMD compiler produces
    unlinkable objects if a final class inherits an alias to an internal
    member of a parent class.

    I have reported this to the D Language Foundation's Bugzilla site on
    17 October, 2017, and this bug can be viewed here:
    https://issues.dlang.org/show_bug.cgi?id=17909
*/
public
class DistinguishedEncodingRulesElement : ASN1Element!DERElement, Byteable
{
    @system
    unittest
    {
        writeln("Running unit tests for codec: " ~ typeof(this).stringof);
    }

    /**
        "Decodes" an $(MONO END OF CONTENT), by which I mean: returns nothing, but
        throws exceptions if the element is not correct.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are any content octets)
        )
    */
    override public @property @safe
    void endOfContent() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an END OF CONTENT");

        if (this.value.length != 0u)
            throw new ASN1ValueSizeException
            (0u, 0u, this.value.length, "decode an END OF CONTENT");
    }

    /**
        Decodes a $(D bool).

        A $(D 0xFF) byte will be interpreted as $(MONO TRUE). A zero byte
        ($(D 0x00)) will be interpreted as $(MONO FALSE). Any other value,
        or any length other than 1 byte will throw an exception.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the encoded value is not exactly 1 byte in size)
            $(LI $(D ASN1ValueException)
                if the encoded value is not either 0xFF or 0x00)
        )
    */
    override public @property @safe
    bool boolean() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a BOOLEAN");

        if (this.value.length != 1u)
            throw new ASN1ValueSizeException
            (1u, 1u, this.value.length, "decode a BOOLEAN");

        switch (this.value[0])
        {
            case (0xFFu): return true;
            case (0x00u): return false;
            default:
                throw new ASN1ValueException
                (
                    "This exception was thrown because you attempted to decode a BOOLEAN " ~
                    "that was encoded on a byte that was not 0xFF or 0x00 using the DER " ~
                    "codec. Any encoding of a boolean other than 0xFF (true) or 0x00 " ~
                    "(false) is restricted by the DER codec. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
    }

    /// Encodes a $(D bool)
    override public @property @safe nothrow
    void boolean(in bool value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = [(value ? 0xFFu : 0x00u)];
    }

    @safe
    unittest
    {
        DERElement dv = new DERElement();
        dv.value = [ 0xFFu ];
        assert(dv.boolean == true);
        dv.value = [ 0x00u ];
        assert(dv.boolean == false);
        dv.value = [ 0x01u, 0x00u ];
        assertThrown!ASN1ValueSizeException(dv.boolean);
        dv.value = [];
        assertThrown!ASN1ValueSizeException(dv.boolean);
        dv.value = [ 0x01u ];
        assertThrown!ASN1ValueException(dv.boolean);
    }

    /**
        Decodes a signed integer.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the value is too big to decode to a signed integral type,
                or if the value is zero bytes)
            $(LI $(D ASN1ValuePaddingException)
                if there are padding bytes)
        )
    */
    public @property @system
    T integer(T)() const
    if ((isIntegral!T && isSigned!T) || is(T == BigInt))
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an INTEGER");

        if (this.value.length == 1u)
        {
            static if (is(T == BigInt))
                return BigInt(cast(byte) this.value[0]);
            else
                return cast(T) cast(byte) this.value[0];
        }

        if (this.value.length == 0u)
            throw new ASN1ValueSizeException
            (1u, long.sizeof, this.value.length, "decode an INTEGER");

        static if (!is(T == BigInt))
        {
            if (this.value.length > T.sizeof)
                throw new ASN1ValueSizeException
                (1u, long.sizeof, this.value.length, "decode an INTEGER");
        }

        if
        (
            (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
            (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
        )
            throw new ASN1ValuePaddingException
            (
                "This exception was thrown because you attempted to decode " ~
                "an INTEGER that was encoded on more than the minimum " ~
                "necessary bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        static if (is(T == BigInt))
        {
            /*
                The most significant bit of the most significant byte
                determines the sign of the resulting INTEGER. So we have to
                treat the first byte specially. After that, all remaining
                bytes are just added after the BigInt has been shifted by
                a byte.
            */
            BigInt ret = BigInt(0);
            ret += cast(byte) (this.value[0] & 0x80u);
            ret += (this.value[0] & cast(ubyte) 0x7Fu);
            foreach (immutable ubyte b; this.value[1 .. $])
            {
                ret <<= 8;
                ret += b;
            }
            return ret;
        }
        else // it is a native integral type
        {
            /* NOTE:
                Because the INTEGER is stored in two's complement form, you
                can't just apppend 0x00u to the big end of it until it is as long
                as T in bytes, then cast to T. Instead, you have to first determine
                if the encoded integer is negative or positive. If it is negative,
                then you actually want to append 0xFFu to the big end until it is
                as big as T, so you get the two's complement form of whatever T
                you choose.

                The line immediately below this determines whether the padding byte
                should be 0xFF or 0x00 based on the most significant bit of the
                most significant byte (which, since DER encodes big-endian, will
                always be the first byte). If set (1), the number is negative, and
                hence, the padding byte should be 0xFF. If not, it is positive,
                and the padding byte should be 0x00.
            */
            immutable ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
            ubyte[] value = this.value.dup; // Duplication is necessary to prevent modifying the source bytes
            while (value.length < T.sizeof)
                value = (paddingByte ~ value);
            version (LittleEndian) reverse(value);
            version (unittest) assert(value.length == T.sizeof);
            return *cast(T *) value.ptr;
        }
    }

    /// Encodes a signed integral type
    public @property @system // nothrow (Can't be nothrow because of BigInt.opCast)
    void integer(T)(in T value)
    if ((isIntegral!T && isSigned!T) || is(T == BigInt))
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        if (value <= byte.max && value >= byte.min)
        {
            this.value = [ cast(ubyte) cast(byte) value ];
            return;
        }

        ubyte[] ub;
        static if (is(T == BigInt))
        {
            if (value.uintLength > (size_t.max >> 5u))
                throw new ASN1ValueSizeException
                (1u, (size_t.max >> 2u), (value.uintLength << 2u), "encode an INTEGER from a BigInt");

            // "+ 1u" because we are going to set the last byte to 00 or FF to indicate sign
            ub.length = ((value.uintLength * uint.sizeof) + 1u);

            /*
                Since there is no easy way to obtain the bytes of the BigInt,
                we have to incrementally shift, mask, and cast to bytes, one
                uint at a time. This loop shifts the supplied BigInt by 32 more
                bits with each iteration, then masks with FFFFFFFF. The resulting
                value can then be cast to a uint without overflow, which can then
                be written to the appropriate "slot" in the pre-allocated array.
            */
            for (size_t i = 0u; i < value.uintLength; i++)
            {
                *cast(uint *) &ub[i << 2u] = cast(uint) ((value >> (i << 5u)) & uint.max);
            }

            /*
                When the BigInt is converted to bytes, unlike a signed integer,
                it might not have the most significant bit set to correctly
                indicate its sign, because the bytes of the BigInt are obtained
                from the internal array of *uints* in the BigInt. So here, we
                append a 00 or FF byte to correct this.
            */
            if (value >= 0)
                ub[$-1] = 0x00u;
            else
                ub[$-1] = 0xFFu;
        }
        else // it is a native integral type
        {
            ub.length = T.sizeof;
            *cast(T *)&ub[0] = value;
        }
        version (LittleEndian) reverse(ub);

        /*
            An INTEGER must be encoded on the fewest number of bytes than can
            encode it. The loops below identify how many bytes can be
            truncated from the start of the INTEGER, with one loop for positive
            and another loop for negative numbers.

            From X.690, Section 8.3.2:

            If the contents octets of an integer value encoding consist of more
            than one octet, then the bits of the first octet and bit 8 of the
            second octet:
                a) shall not all be ones; and
                b) shall not all be zero.
                NOTE – These rules ensure that an integer value is always
                encoded in the smallest possible number of octets.
        */
        size_t startOfNonPadding = 0u;
        static if (T.sizeof > 1u)
        {
            if (value >= 0)
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0x00u) break;
                    if (!(ub[i+1] & 0x80u)) startOfNonPadding++;
                }
            }
            else
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0xFFu) break;
                    if (ub[i+1] & 0x80u) startOfNonPadding++;
                }
            }
        }
        this.value = ub[startOfNonPadding .. $];
    }

    @system
    unittest
    {
        DERElement el = new DERElement();
        BigInt b1 = BigInt("18446744073709551619"); // ulong.max + 4
        BigInt b2 = BigInt(uint.max);
        BigInt b3 = BigInt(0);
        BigInt b4 = BigInt(3);
        BigInt b5 = BigInt(-3);

        el.integer = b1;
        assert(el.value == [
            0x01u, 0x00u, 0x00u, 0x00u,
            0x00u, 0x00u, 0x00u, 0x00u,
            0x03u
        ]);

        el.integer = b2;
        assert(el.value == [
            0x00u, 0xFFu, 0xFFu, 0xFFu,
            0xFFu
        ]);

        el.integer = b3;
        assert(el.value == [
            0x00u
        ]);

        el.integer = b4;
        assert(el.value == [
            0x03u
        ]);

        el.integer = b5;
        assert(el.value == [
            0xFDu
        ]);
    }

    // Ensure that INTEGER 0 gets encoded on a single null byte.
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.integer!byte = cast(byte) 0x00;
        assert(el.value == [ 0x00u ]);

        el.integer!short = cast(short) 0x0000;
        assert(el.value == [ 0x00u ]);

        el.integer!int = cast(int) 0;
        assert(el.value == [ 0x00u ]);

        el.integer!long = cast(long) 0;
        assert(el.value == [ 0x00u ]);

        el.value = [];
        assertThrown!ASN1ValueSizeException(el.integer!byte);
        assertThrown!ASN1ValueSizeException(el.integer!short);
        assertThrown!ASN1ValueSizeException(el.integer!int);
        assertThrown!ASN1ValueSizeException(el.integer!long);
    }

    // Test encoding -0 for the sake of CVE-2016-2108
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.integer!byte = -0;
        assertNotThrown!RangeError(el.integer!byte);
        assertNotThrown!ASN1Exception(el.integer!byte);

        el.integer!short = -0;
        assertNotThrown!RangeError(el.integer!short);
        assertNotThrown!ASN1Exception(el.integer!short);

        el.integer!int = -0;
        assertNotThrown!RangeError(el.integer!int);
        assertNotThrown!ASN1Exception(el.integer!int);

        el.integer!long = -0;
        assertNotThrown!RangeError(el.integer!long);
        assertNotThrown!ASN1Exception(el.integer!long);
    }

    /**
        Decodes an array of $(D bool)s representing a string of bits.

        Returns: an array of $(D bool)s, where each $(D bool) represents a bit
            in the encoded bit string

        Throws:
        $(UL
            $(LI $(D ASN1ValueSizeException)
                if the any primitive contains 0 bytes)
            $(LI $(D ASN1ValueException)
                if the first byte has a value greater
                than seven, or if the first byte indicates the presence of
                padding bits when no subsequent bytes exist, or if any primitive
                but the last in a constructed BIT STRING uses padding bits, or
                if any of the padding bits are set)
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )
    */
    override public @property
    bool[] bitString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a BIT STRING");

        if (this.value.length == 0u)
            throw new ASN1ValueSizeException
            (1u, size_t.max, 0u, "decode a BIT STRING");

        if (this.value[0] > 0x07u)
            throw new ASN1ValueException
            (
                "In Distinguished Encoding Rules (DER), the first byte of the encoded " ~
                "binary value (after the type and length bytes, of course) " ~
                "is used to indicate how many unused bits there are at the " ~
                "end of the BIT STRING. Since everything is encoded in bytes " ~
                "in Distinguished Encoding Rules (DER), but a BIT STRING may not " ~
                "necessarily encode a number of bits, divisible by eight " ~
                "there may be bits at the end of the BIT STRING that will " ~
                "need to be identified as padding instead of meaningful data." ~
                "Since a byte is eight bits, the largest number that the " ~
                "first byte should encode is 7, since, if you have eight " ~
                "unused bits or more, you may as well truncate an entire " ~
                "byte from the encoded data. This exception was thrown because " ~
                "you attempted to decode a BIT STRING whose first byte " ~
                "had a value greater than seven. The value was: " ~
                text(this.value[0]) ~ ". " ~ notWhatYouMeantText ~
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );

        if (this.value[0] > 0x00u && this.value.length <= 1u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode a " ~
                "BIT STRING that had a misleading first byte, which indicated " ~
                "that there were more than zero padding bits, but there were " ~
                "no subsequent octets supplied, which contain the octet-" ~
                "aligned bits and padding. This may have been a mistake on " ~
                "the part of the encoder, but this looks really suspicious: " ~
                "it is likely that an attempt was made to hack your systems " ~
                "by inducing an out-of-bounds read from an array. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        bool[] ret;
        ret.length = ((this.value.length - 1u) << 3u);
        const ubyte[] allButTheFirstByte = this.value[1 .. $];
        foreach (immutable size_t i, immutable ubyte b; allButTheFirstByte)
        {
            ret[((i << 3u) + 0u)] = cast(bool) (b & 0b10000000u);
            ret[((i << 3u) + 1u)] = cast(bool) (b & 0b01000000u);
            ret[((i << 3u) + 2u)] = cast(bool) (b & 0b00100000u);
            ret[((i << 3u) + 3u)] = cast(bool) (b & 0b00010000u);
            ret[((i << 3u) + 4u)] = cast(bool) (b & 0b00001000u);
            ret[((i << 3u) + 5u)] = cast(bool) (b & 0b00000100u);
            ret[((i << 3u) + 6u)] = cast(bool) (b & 0b00000010u);
            ret[((i << 3u) + 7u)] = cast(bool) (b & 0b00000001u);
        }

        foreach (immutable bit; ret[$-this.value[0] .. $])
        {
            if (bit == true)
                throw new ASN1ValueException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a BIT STRING whose padding bits were not entirely zeroes. " ~
                    "If you were using the Basic Encoding Rules (BER), this " ~
                    "would not be a problem, but under Distinguished Encoding " ~
                    "Rules (DER), padding the BIT STRING with anything other " ~
                    "zeroes is forbidden. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }

        ret.length -= this.value[0];
        return ret;
    }

    /// Encodes an array of $(D bool)s representing a string of bits.
    override public @property
    void bitString(in bool[] value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        ubyte[] ub;
        ub.length = ((value.length / 8u) + (value.length % 8u ? 2u : 1u));
        foreach (immutable size_t i, immutable bool b; value)
        {
            if (!b) continue;
            ub[((i >> 3u) + 1u)] |= (0b10000000u >> (i % 8u));
        }

        // REVIEW: I feel like there is a more efficient way to do this.
        ub[0] = cast(ubyte) (8u - (value.length % 8u));
        if (ub[0] == 0x08u) ub[0] = 0x00u;
        this.value = ub;
    }

    // Ensure that 1s in the padding get PUNISHED with an exception
    @system
    unittest
    {
        DERElement el = new DERElement();
        el.value = [ 0x07u, 0b11000000u ];
        assertThrown!ASN1ValueException(el.bitString);

        el.value = [ 0x01u, 0b11111111u ];
        assertThrown!ASN1ValueException(el.bitString);

        el.value = [ 0x00u, 0b11111111u ];
        assertNotThrown!ASN1ValueException(el.bitString);
    }

    // Test a BIT STRING with a deceptive first byte.
    @system
    unittest
    {
        DERElement el = new DERElement();
        el.value = [ 0x01u ];
        assertThrown!ASN1ValueException(el.bitString);
    }

    /**
        Decodes an $(MONO OCTET STRING) into an unsigned byte array.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )
    */
    override public @property @safe
    ubyte[] octetString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an OCTET STRING");

        return this.value.dup;
    }

    /// Encodes an $(MONO OCTET STRING) from an unsigned byte ($(D ubyte)) array.
    override public @property @safe
    void octetString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    /**
        "Decodes" a $(D null), by which I mean: returns nothing, but
        throws exceptions if the element is not correct.

        Note:
            I had to name this method $(D nill), because $(D null) is a keyword in D.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are any content octets)
        )
    */
    override public @property @safe
    void nill() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a NULL");

        if (this.value.length != 0u)
            throw new ASN1ValueSizeException
            (0u, 0u, this.value.length, "decode a NULL");
    }

    /**
        Decodes an $(MONO OBJECT IDENTIFIER).
        See $(MONO source/types/universal/objectidentifier.d) for information about
        the $(D ObjectIdentifier) class (aliased as $(D OID)).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are no value bytes)
            $(LI $(D ASN1ValuePaddingException) if a single OID number is encoded with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1ValueOverflowException) if a single OID number is too big to
                decode to a $(D size_t))
            $(LI $(D ASN1TruncationException) if a single OID number is "cut off")
        )

        Standards:
        $(UL
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
    */
    override public @property @system
    OID objectIdentifier() const
    out (value)
    {
        assert(value.length >= 2u);
    }
    do
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an OBJECT IDENTIFIER");

        if (this.value.length == 0u)
            throw new ASN1ValueSizeException
            (1u, size_t.max, 0u, "decode an OBJECT IDENTIFIER");

        size_t[] numbers = [ 0u, 0u ];
        if (this.value[0] >= 0x50u)
        {
            numbers[0] = 2u;
            numbers[1] = (this.value[0] - 0x50u);
        }
        else if (this.value[0] >= 0x28u)
        {
            numbers[0] = 1u;
            numbers[1] = (this.value[0] - 0x28u);
        }
        else
        {
            numbers[0] = 0u;
            numbers[1] = this.value[0];
        }

        if (this.value.length == 1u)
            return new OID(numbers);

        if ((this.value[$-1] & 0x80u) == 0x80u)
            throw new ASN1TruncationException
            (size_t.max, this.value.length, "decode an OBJECT IDENTIFIER");

        size_t components = 2u;
        const ubyte[] allButTheFirstByte = this.value[1 .. $];
        foreach (immutable size_t i, immutable ubyte b; allButTheFirstByte)
        {
            if (!(b & 0x80u)) components++;
        }
        numbers.length = components;

        size_t currentNumber = 2u;
        ubyte bytesUsedInCurrentNumber = 0u;
        foreach (immutable ubyte b; allButTheFirstByte)
        {
            if (bytesUsedInCurrentNumber == 0u && b == 0x80u)
                throw new ASN1ValuePaddingException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OBJECT IDENTIFIER that contained a number that was " ~
                    "encoded on more than the minimum necessary octets. This " ~
                    "is indicated by an occurrence of the octet 0x80, which " ~
                    "is the encoded equivalent of a leading zero. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            if (numbers[currentNumber] > (size_t.max >> 7))
                throw new ASN1ValueOverflowException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a OBJECT IDENTIFIER that encoded a number that is too big to " ~
                    "decode to a native integral type. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            numbers[currentNumber] <<= 7;
            numbers[currentNumber] |= cast(size_t) (b & 0x7Fu);

            if (!(b & 0x80u))
            {
                currentNumber++;
                bytesUsedInCurrentNumber = 0u;
            }
            else
            {
                bytesUsedInCurrentNumber++;
            }
        }

        return new OID(numbers);
    }

    /**
        Encodes an $(MONO OBJECT IDENTIFIER).
        See $(MONO source/types/universal/objectidentifier.d) for information about
        the $(D ObjectIdentifier) class (aliased as $(OID)).

        Standards:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
    */
    override public @property @system
    void objectIdentifier(in OID value)
    in
    {
        assert(value.length >= 2u);
        assert(value.numericArray[0] <= 2u);
        if (value.numericArray[0] == 2u)
            assert(value.numericArray[1] <= 175u);
        else
            assert(value.numericArray[1] <= 39u);
    }
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        size_t[] numbers = value.numericArray();
        this.value = [ cast(ubyte) (numbers[0] * 40u + numbers[1]) ];
        if (numbers.length > 2u)
        {
            foreach (number; numbers[2 .. $])
            {
                if (number < 128u)
                {
                    this.value ~= cast(ubyte) number;
                    continue;
                }

                ubyte[] encodedOIDNode;
                while (number != 0u)
                {
                    ubyte[] numberBytes;
                    numberBytes.length = size_t.sizeof;
                    *cast(size_t *) numberBytes.ptr = number;
                    if ((numberBytes[0] & 0x80u) == 0u) numberBytes[0] |= 0x80u;
                    encodedOIDNode = numberBytes[0] ~ encodedOIDNode;
                    number >>= 7u;
                }

                encodedOIDNode[$-1] &= 0x7Fu;
                this.value ~= encodedOIDNode;
            }
        }
    }

    @system
    unittest
    {
        DERElement element = new DERElement();

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0xFFu; i++)
        {
            element.value = [ i ];
            assertNotThrown!Exception(element.objectIdentifier);
        }

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0xFFu; i++)
        {
            element.value = [ i, 0x14u ];
            assertNotThrown!Exception(element.objectIdentifier);
        }
    }

    @system
    unittest
    {
        DERElement element = new DERElement();

        // Tests for the "leading zero byte," 0x80
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValuePaddingException(element.objectIdentifier);

        // This one is fine, because the null byte is in the middle of a number.
        element.value = [ 0x29u, 0x84u, 0x80u, 0x01u ];
        assertNotThrown!ASN1CodecException(element.objectIdentifier);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);

        // This one should not fail. 0x80u is valid for the first octet.
        element.value = [ 0x80u, 0x14u, 0x14u ];
        assertNotThrown!ASN1ValuePaddingException(element.objectIdentifier);
    }

    /**
        Decodes an $(D ObjectDescriptor), which is a string consisting of only
        graphical characters. In fact, $(D ObjectDescriptor) is actually implicitly
        just a $(MONO GraphicString)! The formal specification for an $(D ObjectDescriptor)
        is:

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        $(MONO GraphicString) is just a string containing only characters between
        and including $(D 0x20) and $(D 0x7E), therefore ObjectDescriptor is just
        $(D 0x20) and $(D 0x7E).

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if the encoded value contains any character outside of
                $(D 0x20) to $(D 0x7E), which means any control characters or $(MONO DELETE))
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string objectDescriptor() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an ObjectDescriptor");

        foreach (immutable character; this.value)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "ObjectDescriptor");
            }
        }
        return cast(string) this.value;
    }

    /**
        Encodes an $(D ObjectDescriptor), which is a string consisting of only
        graphical characters. In fact, $(D ObjectDescriptor) is actually implicitly
        just a $(MONO GraphicString)! The formal specification for an $(D ObjectDescriptor)
        is:

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        $(MONO GraphicString) is just a string containing only characters between
        and including $(D 0x20) and $(D 0x7E), therefore ObjectDescriptor is just
        $(D 0x20) and $(D 0x7E).

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if the string value contains any character outside of
                $(D 0x20) to $(D 0x7E), which means any control characters or $(MONO DELETE))
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    void objectDescriptor(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if ((!character.isGraphical) && (character != ' '))
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "ObjectDescriptor");
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes an $(MONO EXTERNAL).

        According to the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)),
        the abstract definition for an $(MONO EXTERNAL), after removing the comments in the
        specification, is as follows:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        Note that the abstract syntax resembles that of $(MONO EmbeddedPDV) and
        $(MONO CharacterString), except with a $(MONO WITH COMPONENTS) constraint that removes some
        of our choices of $(MONO identification).
        As can be seen on page 303 of Olivier Dubuisson's
        $(I $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF,
            ASN.1: Communication Between Heterogeneous Systems)),
        after applying the $(MONO WITH COMPONENTS) constraint, our reduced syntax becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER } },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        But, according to the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules),
        section 8.18, when encoded using Basic Encoding Rules (BER), is encoded as
        follows, for compatibility reasons:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                direct-reference  OBJECT IDENTIFIER OPTIONAL,
                indirect-reference  INTEGER OPTIONAL,
                data-value-descriptor  ObjectDescriptor  OPTIONAL,
                encoding  CHOICE {
                    single-ASN1-type  [0] ANY,
                    octet-aligned     [1] IMPLICIT OCTET STRING,
                    arbitrary         [2] IMPLICIT BIT STRING } }
        )

        The definition above is the pre-1994 definition of $(MONO EXTERNAL). The $(MONO syntax)
        field of the post-1994 definition maps to the $(MONO direct-reference) field of
        the pre-1994 definition. The $(MONO presentation-context-id) field of the post-1994
        definition maps to the $(MONO indirect-reference) field of the pre-1994 definition.
        If $(MONO context-negotiation) is used, per the abstract syntax, then the
        $(MONO presentation-context-id) field of the $(MONO context-negotiation) $(MONO SEQUENCE) in the
        post-1994 definition maps to the $(MONO indirect-reference) field of the pre-1994
        definition, and the $(MONO transfer-syntax) field of the $(MONO context-negotiation)
        $(MONO SEQUENCE) maps to the $(MONO direct-reference) field of the pre-1994 definition.

        The following additional constraints are applied to the abstract syntax
        when using Canonical Encoding Rules or Distinguished Encoding Rules,
        which are also defined in the
        $(LINK https://www.itu.int/en/pages/default.aspx,
        International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

        $(PRE
            EXTERNAL ( WITH COMPONENTS {
                ... ,
                identification ( WITH COMPONENTS {
                    ... ,
                    presentation-context-id ABSENT,
                    context-negotiation ABSENT } ) } )
        )

        The stated purpose of the constraints shown above is to restrict the use of
        the $(MONO presentation-context-id), either by itself or within the
        $(MONO context-negotiation), which makes the following the effective abstract
        syntax of $(MONO EXTERNAL) when using Canonical Encoding Rules or
        Distinguished Encoding Rules:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            presentation-context-id ABSENT,
                            context-negotiation ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        With the constraints applied, the abstract syntax for $(MONO EXTERNAL)s encoded
        using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        Upon removing the $(MONO CHOICE) tag (since you have no choice but to use syntax
        at this point), the encoding definition when using
        Canonical Encoding Rules or Distinguished Encoding Rules:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                syntax OBJECT IDENTIFIER,
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        Returns: an instance of $(D types.universal.external.External)

        Throws:
        $(UL
            $(LI $(D ASN1ValueException)
                if the SEQUENCE does not contain two to four elements)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not have the correct tag class)
            $(LI $(D ASN1ConstructionException)
                if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not have the correct tag number)
            $(LI $(D ASN1ValueCharactersException)
                if a data-value-descriptor is supplied with invalid characters)
            $(LI $(D ASN1ConstructionException) if the element is not marked as "constructed")
        )
    */
    deprecated override public @property @system
    External external() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode an EXTERNAL");

        const DERElement[] components = this.sequence;
        External ext = External();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length < 2u || components.length > 3u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL that contained too many or too few elements. " ~
                "An EXTERNAL should have either two and three elements: " ~
                "a direct-reference (syntax), an optional " ~
                "data-value-descriptor, and an encoding (data-value). " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        // Every component except the last must be universal class
        foreach (const component; components[0 .. $-1])
        {
            if (component.tagClass != ASN1TagClass.universal)
                throw new ASN1TagClassException
                ([ ASN1TagClass.universal ], component.tagClass, "decode all but the last component of an EXTERNAL");
        }

        // The last tag must be context-specific class
        if (components[$-1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            ([ ASN1TagClass.contextSpecific ], components[$-1].tagClass, "decode the last component of an EXTERNAL");

        // The first component should always be primitive
        if (components[0].construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (components[0].construction, "decode the first component of an EXTERNAL");

        if (components[0].tagNumber != ASN1UniversalType.objectIdentifier)
            throw new ASN1TagNumberException
            ([ 2u, 6u ], components[0].tagNumber, "decode the first component of an EXTERNAL");

        identification.directReference = components[0].objectIdentifier;
        if (components.length == 3u)
        {
            if (components[1].tagNumber != ASN1UniversalType.objectDescriptor)
                throw new ASN1TagNumberException
                (
                    [ ASN1UniversalType.objectDescriptor ],
                    components[1].tagNumber,
                    "decode the second of three subcomponents of an EXTERNAL"
                );

            ext.dataValueDescriptor = components[1].objectDescriptor;
        }

        switch (components[$-1].tagNumber)
        {
            case (0u): // single-ASN1-value
            {
                ext.encoding = ASN1ExternalEncodingChoice.singleASN1Type;
                break;
            }
            case (1u): // octet-aligned
            {
                ext.encoding = ASN1ExternalEncodingChoice.octetAligned;
                break;
            }
            case (2u): // arbitrary
            {
                ext.encoding = ASN1ExternalEncodingChoice.arbitrary;
                break;
            }
            default:
                throw new ASN1TagNumberException
                ([ 0u, 1u, 2u ], components[$-1].tagNumber, "decode an EXTERNAL identification");
        }

        ext.dataValue = components[$-1].value.dup;
        ext.identification = identification;
        return ext;
    }

    /**
        Encodes an $(MONO EXTERNAL).

        According to the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)),
        the abstract definition for an $(MONO EXTERNAL), after removing the comments in the
        specification, is as follows:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        Note that the abstract syntax resembles that of $(MONO EmbeddedPDV) and
        $(MONO CharacterString), except with a $(MONO WITH COMPONENTS) constraint that removes some
        of our choices of $(MONO identification).
        As can be seen on page 303 of Olivier Dubuisson's
        $(I $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF,
            ASN.1: Communication Between Heterogeneous Systems)),
        after applying the $(MONO WITH COMPONENTS) constraint, our reduced syntax becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER } },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        But, according to the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules),
        section 8.18, when encoded using Basic Encoding Rules (BER), is encoded as
        follows, for compatibility reasons:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                direct-reference  OBJECT IDENTIFIER OPTIONAL,
                indirect-reference  INTEGER OPTIONAL,
                data-value-descriptor  ObjectDescriptor  OPTIONAL,
                encoding  CHOICE {
                    single-ASN1-type  [0] ANY,
                    octet-aligned     [1] IMPLICIT OCTET STRING,
                    arbitrary         [2] IMPLICIT BIT STRING } }
        )

        The definition above is the pre-1994 definition of $(MONO EXTERNAL). The $(MONO syntax)
        field of the post-1994 definition maps to the $(MONO direct-reference) field of
        the pre-1994 definition. The $(MONO presentation-context-id) field of the post-1994
        definition maps to the $(MONO indirect-reference) field of the pre-1994 definition.
        If $(MONO context-negotiation) is used, per the abstract syntax, then the
        $(MONO presentation-context-id) field of the $(MONO context-negotiation) $(MONO SEQUENCE) in the
        post-1994 definition maps to the $(MONO indirect-reference) field of the pre-1994
        definition, and the $(MONO transfer-syntax) field of the $(MONO context-negotiation)
        $(MONO SEQUENCE) maps to the $(MONO direct-reference) field of the pre-1994 definition.

        The following additional constraints are applied to the abstract syntax
        when using Canonical Encoding Rules or Distinguished Encoding Rules,
        which are also defined in the
        $(LINK https://www.itu.int/en/pages/default.aspx,
        International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

        $(PRE
            EXTERNAL ( WITH COMPONENTS {
                ... ,
                identification ( WITH COMPONENTS {
                    ... ,
                    presentation-context-id ABSENT,
                    context-negotiation ABSENT } ) } )
        )

        The stated purpose of the constraints shown above is to restrict the use of
        the $(MONO presentation-context-id), either by itself or within the
        $(MONO context-negotiation), which makes the following the effective abstract
        syntax of $(MONO EXTERNAL) when using Canonical Encoding Rules or
        Distinguished Encoding Rules:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            presentation-context-id ABSENT,
                            context-negotiation ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        With the constraints applied, the abstract syntax for $(MONO EXTERNAL)s encoded
        using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        Upon removing the $(MONO CHOICE) tag (since you have no choice but to use syntax
        at this point), the encoding definition when using
        Canonical Encoding Rules or Distinguished Encoding Rules:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
                syntax OBJECT IDENTIFIER,
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        Returns: an instance of $(D types.universal.external.External)

        Throws:
        $(UL
            $(LI $(D ASN1ValueException)
                if something other than $(D syntax) is used for $(MONO identification))
            $(LI $(D ASN1ValueCharactersException)
                if a data-value-descriptor is supplied with invalid characters)
        )
    */
    deprecated override public @property @system
    void external(in External value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.constructed;
        DERElement[] components = [];

        if (!(value.identification.syntax.isNull))
        {
            DERElement directReference = new DERElement();
            directReference.tagNumber = ASN1UniversalType.objectIdentifier;
            directReference.objectIdentifier = value.identification.directReference;
            components ~= directReference;
        }
        else // it must be the presentationContextID / indirectReference INTEGER
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to encode an " ~
                "EXTERNAL that used something other than syntax as the CHOICE " ~
                "of identification, which is not permitted when using " ~
                "Distinguished Encoding Rules (DER). " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        DERElement dataValueDescriptor = new DERElement();
        dataValueDescriptor.tagNumber = ASN1UniversalType.objectDescriptor;
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;
        components ~= dataValueDescriptor;

        DERElement dataValue = new DERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = value.encoding;
        dataValue.value = value.dataValue.dup;

        components ~= dataValue;
        this.sequence = components;
    }

    /*
        Since a DER-encoded EXTERNAL can only use the syntax field for
        the CHOICE of identification, this unit test ensures that an
        exception if thrown if an alternative identification is supplied.
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        External input = External();
        input.identification = id;
        input.dataValueDescriptor = "external";
        input.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        DERElement el = new DERElement();
        assertThrown!ASN1ValueException(el.external = input);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] external = [ // This is valid
            0x08u, 0x09u, // EXTERNAL, Length 9
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];

        // Valid values for octet[2]: 02 06
        for (ubyte i = 0x07u; i < 0x1Eu; i++)
        {
            external[2] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, external);
            assertThrown!ASN1Exception(el.external);
        }

        // Valid values for octet[5]: 80 - 82 (Anything else is an invalid value)
        for (ubyte i = 0x82u; i < 0x9Eu; i++)
        {
            external[5] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, external);
            assertThrown!ASN1Exception(el.external);
        }
    }

    // Assert that duplicate elements throw exceptions
    @system
    unittest
    {
        ubyte[] external;

        external = [ // This is invalid
            0x08u, 0x0Cu, // EXTERNAL, Length 12
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x81, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new DERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x0Eu, // EXTERNAL, Length 14
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x81, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new DERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x12u, // EXTERNAL, Length 18
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new DERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x14u, // EXTERNAL, Length 20
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u, // OCTET STRING 1,2,3,4
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new DERElement(external)).external);
    }

    /**
        Decodes a floating-point type.

        Note that this method assumes that your machine uses
        $(LINK http://ieeexplore.ieee.org/document/4610935/, IEEE 754-2008)
        floating point format.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1TruncationException) if the value appears to be "cut off")
            $(LI $(D ConvException) if character-encoding cannot be converted to
                the selected floating-point type, T)
            $(LI $(D ConvOverflowException) if the character-encoding encodes a
                number that is too big for the selected floating-point
                type to express)
            $(LI $(D ASN1ValueSizeException) if the binary-encoding contains fewer
                bytes than the information byte purports, or if the
                binary-encoded mantissa is too big to be expressed by an
                unsigned long integer)
            $(LI $(D ASN1ValueException) if a complicated-form exponent or a
                non-zero-byte mantissa encodes a zero or even number, of if a base-10
                (character-encoded) REAL is has something wrong that is not
                covered by $(D ASN1ValueCharactersException) or
                $(D ASN1ValuePaddingException))
            $(LI $(D ASN1ValueUndefinedException) if both bits indicating the base in the
                information byte of a binary-encoded $(MONO REAL)'s information byte
                are set, which would indicate an invalid base, or if a special
                value has been indicated that is not defined by the specification)
            $(LI $(D ASN1ValuePaddingException) if a base-10 (character-encoded)
                REAL is encoded with leading zeroes, or trailing zeroes on the
                mantissa, or if the mantissa is encoded on more than the minimal
                necessary octets)
            $(LI $(D ASN1ValueCharactersException) if a base-10 (character-encoded)
                REAL is encoded with characters that are not numeric, a decimal, E,
                or plus or minus)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 400-402.)
            $(LI $(LINK https://www.iso.org/standard/12285.html, ISO 6093))
        )
    */
    public @property @system
    T realNumber(T)() const
    if (isFloatingPoint!T)
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a REAL");

        if (this.value.length == 0u) return cast(T) 0.0;
        switch (this.value[0] & 0b11000000u)
        {
            case (0b01000000u):
            {
                if (this.value[0] == ASN1SpecialRealValue.notANumber) return T.nan;
                if (this.value[0] == ASN1SpecialRealValue.minusZero) return -0.0;
                if (this.value[0] == ASN1SpecialRealValue.plusInfinity) return T.infinity;
                if (this.value[0] == ASN1SpecialRealValue.minusInfinity) return -T.infinity;
                throw new ASN1ValueUndefinedException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a REAL whose information byte indicated a special value " ~
                    "not recognized by the specification. The only special " ~
                    "values recognized by the specification are PLUS-INFINITY, " ~
                    "MINUS-INFINITY, NOT-A-NUMBER, and minus zero, identified " ~
                    "by information bytes of 0x40, 0x41 0x42, 0x43 respectively. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
            }
            case (0b00000000u): // Character Encoding
            {
                /* NOTE:
                    Specification X.690 lays out very strict standards for the
                    Canonical Encoding Rules (CER) and Distinguished Encoding
                    Rules (DER) base-10-encoded REAL.

                    The character encoding form must be NR3, from ISO 6093, but
                    with even more restrictions applied.

                    It must be encoded like so:
                    * No whitespace whatsoever
                    * No leading zeroes under any circumstance.
                    * No trailing zeroes under any circumstance.
                    * No plus sign unless exponent is 0.

                    A valid encoding looks like this: 22.E-5
                */
                import std.conv : to;
                import std.string : indexOf;

                immutable string invalidNR3RealMessage =
                    "This exception was thrown because you attempted to decode " ~
                    "a base-10 encoded REAL that was encoded with improper " ~
                    "format. When using Canonical Encoding Rules (CER) or " ~
                    "Distinguished Encoding Rules (DER), the base-10 encoded " ~
                    "REAL must be encoded in the NR3 format specified in " ~
                    "ISO 6093. Further, there may be no whitespace, no leading " ~
                    "zeroes, no trailing zeroes on the mantissa, before or " ~
                    "after the decimal point, and no plus sign should ever " ~
                    "appear, unless the exponent is 0, in which case, the " ~
                    "exponent should read '+0'. Further, there must be a " ~
                    "decimal point, immediately followed by a capital 'E'." ~
                    "Your problem, in this case, was that your encoded value ";

                // Smallest possible is '#.E#'. Decimal is necessary.
                if (this.value.length < 5u)
                    throw new ASN1ValueSizeException
                    (5u, size_t.max, this.value.length, "decode a base-10 encoded REAL");

                if (this.value[0] != 0b00000011u)
                    throw new ASN1ValueException
                    (invalidNR3RealMessage ~ "was not NR3 format at all.");

                string valueString = cast(string) this.value[1 .. $];

                foreach (character; valueString)
                {
                    import std.ascii : isWhite;
                    if
                    (
                        character.isWhite ||
                        character == ',' ||
                        character == '_'
                    )
                        throw new ASN1ValueCharactersException
                        ("1234567890+-.E", character, "decode a base-10 encoded REAL");
                }

                if
                (
                    valueString[0] == '0' ||
                    (valueString[0] == '-' && valueString[1] == '0')
                )
                    throw new ASN1ValuePaddingException
                    (invalidNR3RealMessage ~ "contained a leading zero.");

                ptrdiff_t indexOfDecimalPoint = valueString.indexOf(".");
                if (indexOfDecimalPoint == -1)
                    throw new ASN1ValueException
                    (invalidNR3RealMessage ~ "contained no decimal point.");

                if (valueString[indexOfDecimalPoint+1] != 'E')
                    throw new ASN1ValueException
                    (invalidNR3RealMessage ~ "contained no 'E'.");

                if (valueString[indexOfDecimalPoint-1] == '0')
                    throw new ASN1ValuePaddingException
                    (invalidNR3RealMessage ~ "contained a trailing zero on the mantissa.");

                if (valueString[$-2 .. $] != "+0" && canFind(valueString, '+'))
                    throw new ASN1ValueException
                    (invalidNR3RealMessage ~ "contained an illegitimate plus sign.");

                if (canFind(valueString, "E0") || canFind(valueString, "E-0"))
                    throw new ASN1ValuePaddingException
                    (invalidNR3RealMessage ~ "contained a leading zero on the exponent.");

                return to!(T)(valueString);
            }
            case 0b10000000u, 0b11000000u: // Binary Encoding
            {
                ulong mantissa;
                short exponent;
                ubyte scale;
                ubyte base;
                size_t startOfMantissa;

                switch (this.value[0] & 0b00000011u)
                {
                    case 0b00000000u: // Exponent on the following octet
                    {
                        if (this.value.length < 3u)
                            throw new ASN1TruncationException
                            (3u, this.value.length, "decode a REAL exponent");

                        exponent = cast(short) cast(byte) this.value[1];
                        startOfMantissa = 2u;
                        break;
                    }
                    case 0b00000001u: // Exponent on the following two octets
                    {
                        if (this.value.length < 4u)
                            throw new ASN1TruncationException
                            (4u, this.value.length, "decode a REAL exponent");

                        ubyte[] exponentBytes = this.value[1 .. 3].dup;
                        version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ];
                        exponent = *cast(short *) exponentBytes.ptr;

                        if (exponent <= byte.max && exponent >= byte.min)
                            throw new ASN1ValuePaddingException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a binary-encoded REAL whose exponent " ~
                                "was encoded on more bytes than necessary. This " ~
                                "would not be a problem if you were using the " ~
                                "Basic Encoding Rules (BER), but the Canonical " ~
                                "Encoding Rules (CER) and Distinguished Encoding " ~
                                "Rules (DER) require that the exponent be " ~
                                "encoded on the fewest possible bytes. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~
                                debugInformationText ~ reportBugsText
                            );

                        startOfMantissa = 3u;
                        break;
                    }
                    case 0b00000010u: // Exponent on the following three octets
                    case 0b00000011u: // Complicated
                    {
                        throw new ASN1ValueOverflowException
                        (
                            "This exception was thrown because, according to " ~
                            "section 11.3.1 of specification X.690, a REAL's " ~
                            "exponent must be encoded on the fewest possible " ~
                            "octets, but you attempted to decode one that was " ~
                            "either too big to fit in an IEEE 754 floating " ~
                            "point type, or would have had unnecessary leading " ~
                            "bytes if it could. "
                        );
                    }
                    default: assert(0, "Impossible binary exponent encoding on REAL type");
                }

                if (this.value.length - startOfMantissa > ulong.sizeof)
                    throw new ASN1ValueOverflowException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL whose mantissa was encoded on too many " ~
                        "bytes to decode to the largest unsigned integral data " ~
                        "type. "
                    );

                ubyte[] mantissaBytes = this.value[startOfMantissa .. $].dup;

                if (mantissaBytes[0] == 0x00u)
                    throw new ASN1ValuePaddingException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "a REAL mantissa that was encoded on more than the minimum " ~
                        "necessary bytes. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                while (mantissaBytes.length < ulong.sizeof)
                    mantissaBytes = (0x00u ~ mantissaBytes);
                version (LittleEndian) reverse(mantissaBytes);
                version (unittest) assert(mantissaBytes.length == ulong.sizeof);
                mantissa = *cast(ulong *) mantissaBytes.ptr;

                if (mantissa == 0u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL that was encoded on more than zero " ~
                        "bytes, but whose mantissa encoded a zero. This " ~
                        "is prohibited by specification X.690. If the " ~
                        "abstract value encoded is a real number of zero, " ~
                        "the REAL must be encoded upon zero bytes. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );



                switch (this.value[0] & 0b00110000u)
                {
                    case (0b00000000u):
                    {
                        /* NOTE:
                            Section 11.3.1 of X.690 states that, for Canonical Encoding Rules
                            (CER) and Distinguished Encoding Rules (DER), the mantissa must be
                            zero or odd.
                        */
                        if (!(mantissa & 1u))
                            throw new ASN1ValueException
                            (
                                "This exception was thrown because you attempted to " ~
                                "decode a base-2 encoded REAL whose mantissa was " ~
                                "not zero or odd. Both Canonical Encoding Rules (CER) " ~
                                "and Distinguished Encoding Rules (DER) require that " ~
                                "a base-2 encoded REAL's mantissa be shifted so that " ~
                                "it is either zero or odd. "
                            );

                        base = 0x02u;
                        break;
                    }
                    case (0b00010000u): base = 0x08u; break;
                    case (0b00100000u): base = 0x10u; break;
                    default:
                        throw new ASN1ValueUndefinedException
                        (
                            "This exception was thrown because you attempted to " ~
                            "decode a REAL that had both base bits in the " ~
                            "information block set, the meaning of which is " ~
                            "not specified. " ~
                            notWhatYouMeantText ~ forMoreInformationText ~
                            debugInformationText ~ reportBugsText
                        );
                }

                if (this.value[0] & 0b00001100u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL whose scale was not zero. This would " ~
                        "not be a problem if you were using the Basic " ~
                        "Encoding Rules (BER), but specification X.690 " ~
                        "says that, when using the Canonical Encoding Rules " ~
                        "(CER) or Distinguished Encoding Rules (DER), the " ~
                        "scale must be zero. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                /*
                    For some reason that I have yet to discover, you must
                    cast the exponent to T. If you do not, specifically
                    any usage of realNumber!T() outside of this library will
                    produce a "floating point exception 8" message and
                    crash. For some reason, all of the tests pass within
                    this library without doing this.
                */
                return (
                    ((this.value[0] & 0b01000000u) ? -1.0 : 1.0) *
                    cast(T) mantissa *
                    (cast(T) base)^^(cast(T) exponent) // base must be cast
                );
            }
            default: assert(0, "Impossible information byte value appeared!");
        }
    }

    /**
        Encodes a floating-point type, using base-2 binary encoding.

        Note that this method assumes that your machine uses
        $(LINK http://ieeexplore.ieee.org/document/4610935/, IEEE 754-2008)
        floating point format.

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 400-402.)
            $(LI $(LINK https://www.iso.org/standard/12285.html, ISO 6093))
        )
    */
    public @property @system
    void realNumber(T)(in T value)
    if (isFloatingPoint!T)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        /* NOTE:
            You must use isIdentical() to compare FP types to negative zero,
            because the basic == operator does not distinguish between zero
            and negative zero.

            isNaN() must be used to compare NaNs, because comparison using ==
            does not work for that at all.

            Also, this cannot go in a switch statement, because FP types
            cannot be the switch value.
        */
        if (isIdentical(value, 0.0))
        {
            this.value = [];
            return;
        }
        else if (isIdentical(value, -0.0))
        {
            this.value = [ ASN1SpecialRealValue.minusZero ];
            return;
        }
        else if (value.isNaN)
        {
            this.value = [ ASN1SpecialRealValue.notANumber ];
            return;
        }
        else if (value == T.infinity)
        {
            this.value = [ ASN1SpecialRealValue.plusInfinity ];
            return;
        }
        else if (value == -T.infinity)
        {
            this.value = [ ASN1SpecialRealValue.minusInfinity ];
            return;
        }

        real realValue = cast(real) value;
        bool positive = true;
        ulong mantissa;
        short exponent;

        /*
            Per the IEEE specifications, the exponent of a floating-point
            type is stored with a bias, meaning that the exponent counts
            up from a negative number, the reaches zero at the bias. We
            subtract the bias from the raw binary exponent to get the
            actual exponent encoded in the IEEE floating-point number.
            In the case of an x86 80-bit extended-precision floating-point
            type, the bias is 16383. In the case of double-precision, it is
            1023. For single-precision, it is 127.

            We then subtract the number of bits in the fraction from the
            exponent, which is equivalent to having had multiplied the
            fraction enough to have made it an integer represented by the
            same sequence of bits.
        */
        ubyte[] realBytes;
        realBytes.length = real.sizeof;
        *cast(real *)&realBytes[0] = realValue;

        version (BigEndian)
        {
            static if (real.sizeof > 10u) realBytes = realBytes[real.sizeof-10 .. $];
            positive = ((realBytes[0] & 0x80u) ? false : true);
        }
        else version (LittleEndian)
        {
            static if (real.sizeof > 10u) realBytes.length = 10u;
            positive = ((realBytes[$-1] & 0x80u) ? false : true);
        }
        else assert(0, "Could not determine endianness");

        static if (real.mant_dig == 64) // x86 Extended Precision
        {
            version (BigEndian)
            {
                exponent = (((*cast(short *) &realBytes[0]) & 0x7FFF) - 16383 - 63); // 16383 is the bias
                mantissa = *cast(ulong *) &realBytes[2];
            }
            else version (LittleEndian)
            {
                exponent = (((*cast(short *) &realBytes[8]) & 0x7FFF) - 16383 - 63); // 16383 is the bias
                mantissa = *cast(ulong *) &realBytes[0];
            }
            else assert(0, "Could not determine endianness");
        }
        else if (T.mant_dig == 53) // Double Precision
        {
            /*
                The IEEE 754 double-precision floating point type only stores
                the fractional part of the mantissa, because there is an
                implicit 1 prior to the fractional part. To retrieve the actual
                mantissa encoded, we flip the bit that comes just before the
                most significant bit of the fractional part of the number.
            */
            version (BigEndian)
            {
                exponent = (((*cast(short *) &realBytes[0]) & 0x7FFF) - 1023 - 53); // 1023 is the bias
                mantissa = (((*cast(ulong *) &realBytes[2]) & 0x000FFFFFFFFFFFFFu) | 0x0010000000000000u);
            }
            else version (LittleEndian)
            {
                exponent = (((*cast(short *) &realBytes[8]) & 0x7FFF) - 1023 - 53); // 1023 is the bias
                mantissa = (((*cast(ulong *) &realBytes[0]) & 0x000FFFFFFFFFFFFFu) | 0x0010000000000000u);
            }
            else assert(0, "Could not determine endianness");
        }
        else if (T.mant_dig == 24) // Single Precision
        {
            /*
                The IEEE 754 single-precision floating point type only stores
                the fractional part of the mantissa, because there is an
                implicit 1 prior to the fractional part. To retrieve the actual
                mantissa encoded, we flip the bit that comes just before the
                most significant bit of the fractional part of the number.
            */
            version (BigEndian)
            {
                exponent = ((((*cast(short *) &realBytes[0]) & 0x7F80) >> 7) - 127 - 23); // 127 is the bias
                mantissa = cast(ulong) (((*cast(uint *) &realBytes[2]) & 0x007FFFFFu) | 0x00800000u);
            }
            else version (LittleEndian)
            {
                exponent = ((((*cast(short *) &realBytes[8]) & 0x7F80) >> 7) - 127 - 23); // 127 is the bias
                mantissa = cast(ulong) (((*cast(uint *) &realBytes[0]) & 0x007FFFFFu) | 0x00800000u);
            }
            else assert(0, "Could not determine endianness");
        }
        else assert(0, "Unrecognized real floating-point format.");

        /* NOTE:
            Section 11.3.1 of X.690 states that, for Canonical Encoding Rules
            (CER) and Distinguished Encoding Rules (DER), the mantissa must be
            zero or odd.
        */
        if (mantissa != 0u)
        {
            while (!(mantissa & 1u))
            {
                mantissa >>= 1;
                exponent++;
            }
            version(unittest) assert(mantissa & 1u);
        }

        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ]; // Manual reversal (optimization)
        if
        (
            (exponentBytes[0] == 0x00u && (!(exponentBytes[1] & 0x80u))) || // Unnecessary positive leading bytes
            (exponentBytes[0] == 0xFFu && (exponentBytes[1] & 0x80u)) // Unnecessary negative leading bytes
        )
            exponentBytes = exponentBytes[1 .. 2];

        ubyte[] mantissaBytes;
        mantissaBytes.length = ulong.sizeof;
        *cast(ulong *)mantissaBytes.ptr = cast(ulong) mantissa;
        version (LittleEndian) reverse(mantissaBytes);

        size_t startOfNonPadding = 0u;
        for (size_t i = 0u; i < mantissaBytes.length-1; i++)
        {
            if (mantissaBytes[i] != 0x00u) break;
            startOfNonPadding++;
        }
        mantissaBytes = mantissaBytes[startOfNonPadding .. $];

        ubyte infoByte =
            0x80u | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00u : 0x40u) | // 1 = negative, 0 = positive
            // Scale = 0
            cast(ubyte) (exponentBytes.length == 1u ?
                ASN1RealExponentEncoding.followingOctet :
                ASN1RealExponentEncoding.following2Octets);

        this.value = (infoByte ~ exponentBytes ~ mantissaBytes);
    }

    @system
    unittest
    {
        DERElement el = new DERElement();

        // float
        el.realNumber!float = cast(float) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(float) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(float) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(float) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);

        // double
        el.realNumber!float = cast(float) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(double) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(double) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(double) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);

        // real
        el.realNumber!float = cast(float) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(real) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(real) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(real) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
    }

    // Positive Testing Base-10 (Character-Encoded) REALs
    @system
    unittest
    {
        immutable string[] tests = [
            "1.E1",
            "2.E10",
            "4.E100",
            "1.E-1",
            "2.E-10",
            "4.E-100",
            "-1.E1",
            "-2.E10",
            "-4.E100",
            "-1.E-1",
            "-2.E-10",
            "-4.E-100",
            "19.E1",
            "29.E10",
            "49.E100",
            "19.E-1",
            "29.E-10",
            "49.E-100",
            "-19.E1",
            "-29.E10",
            "-49.E100",
            "-19.E-1",
            "-29.E-10",
            "-49.E-100",
            "33.E+0"
        ];

        DERElement el = new DERElement();

        foreach (test; tests)
        {
            el.value = [ 0b00000011u ];
            el.value ~= cast(ubyte[]) test;
            assertNotThrown!ASN1ValueException(el.realNumber!float);
            assertNotThrown!ASN1ValueException(el.realNumber!double);
            assertNotThrown!ASN1ValueException(el.realNumber!real);
        }
    }

    // Negative Testing Base-10 (Character-Encoded) REALs
    @system
    unittest
    {
        immutable string[] tests = [
            " 1.E1", // Leading whitespace
            "1.E1 ", // Trailing whitespace
            "1 .E1", // Internal whitespace
            "1. E1", // Internal whitespace
            "1.E 1", // Internal whitespace
            "+1.E1", // Leading plus sign
            "01.E1", // Leading zero
            "10.E1", // Trailing zero
            "1.0E1", // Fractional zero
            "1.E+1", // Leading plus sign
            "1.E01", // Leading zero
            "1E100", // No decimal point
            "1.1",   // No 'E'
            ""       // Empty string
        ];

        DERElement el = new DERElement();

        foreach (test; tests)
        {
            el.value = [ 0b00000011u ];
            el.value ~= cast(ubyte[]) test;
            assertThrown!ASN1ValueException(el.realNumber!float);
            assertThrown!ASN1ValueException(el.realNumber!double);
            assertThrown!ASN1ValueException(el.realNumber!real);
        }
    }

    /**
        Decodes a signed integer, which represents a selection from an
        $(MONO ENUMERATION) of choices.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the value is too big to decode to a signed integral type,
                or if the value is zero bytes)
            $(LI $(D ASN1ValuePaddingException)
                if there are padding bytes)
        )
    */
    public @property @system
    T enumerated(T)() const
    if (isIntegral!T && isSigned!T)
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an ENUMERATED");

        if (this.value.length == 1u)
            return cast(T) cast(byte) this.value[0];

        if (this.value.length == 0u || this.value.length > T.sizeof)
            throw new ASN1ValueSizeException
            (1u, long.sizeof, this.value.length, "decode an ENUMERATED");

        if
        (
            (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
            (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
        )
            throw new ASN1ValuePaddingException
            (
                "This exception was thrown because you attempted to decode " ~
                "an ENUMERATED that was encoded on more than the minimum " ~
                "necessary bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /* NOTE:
            Because the ENUMERATED is stored in two's complement form, you
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the
            most significant byte (which, since DER encodes big-endian, will
            always be the first byte). If set (1), the number is negative, and
            hence, the padding byte should be 0xFF. If not, it is positive,
            and the padding byte should be 0x00.
        */
        immutable ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        ubyte[] value = this.value.dup; // Duplication is necessary to prevent modifying the source bytes
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);
        version (LittleEndian) reverse(value);
        version (unittest) assert(value.length == T.sizeof);
        return *cast(T *) value.ptr;
    }

    /// Encodes an $(MONO ENUMERATED) type from an integer.
    public @property @system nothrow
    void enumerated(T)(in T value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        if (value <= byte.max && value >= byte.min)
        {
            this.value = [ cast(ubyte) cast(byte) value ];
            return;
        }

        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian) reverse(ub);

        /*
            An ENUMERATED must be encoded on the fewest number of bytes than can
            encode it. The loops below identify how many bytes can be
            truncated from the start of the ENUMERATED, with one loop for positive
            and another loop for negative numbers. ENUMERATED is encoded in the
            same exact way that INTEGER is encoded.

            From X.690, Section 8.3.2:

            If the contents octets of an integer value encoding consist of more
            than one octet, then the bits of the first octet and bit 8 of the
            second octet:
                a) shall not all be ones; and
                b) shall not all be zero.
                NOTE – These rules ensure that an integer value is always
                encoded in the smallest possible number of octets.
        */
        size_t startOfNonPadding = 0u;
        if (T.sizeof > 1u)
        {
            if (value >= 0)
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0x00u) break;
                    if (!(ub[i+1] & 0x80u)) startOfNonPadding++;
                }
            }
            else
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0xFFu) break;
                    if (ub[i+1] & 0x80u) startOfNonPadding++;
                }
            }
        }

        this.value = ub[startOfNonPadding .. $];
    }

    // Ensure that ENUMERATED 0 gets encoded on a single null byte.
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.enumerated!byte = cast(byte) 0x00;
        assert(el.value == [ 0x00u ]);

        el.enumerated!short = cast(short) 0x0000;
        assert(el.value == [ 0x00u ]);

        el.enumerated!int = cast(int) 0;
        assert(el.value == [ 0x00u ]);

        el.enumerated!long = cast(long) 0;
        assert(el.value == [ 0x00u ]);

        el.value = [];
        assertThrown!ASN1ValueSizeException(el.enumerated!byte);
        assertThrown!ASN1ValueSizeException(el.enumerated!short);
        assertThrown!ASN1ValueSizeException(el.enumerated!int);
        assertThrown!ASN1ValueSizeException(el.enumerated!long);
    }

    // Test encoding -0 for the sake of CVE-2016-2108
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.enumerated!byte = -0;
        assertNotThrown!RangeError(el.enumerated!byte);
        assertNotThrown!ASN1Exception(el.enumerated!byte);

        el.enumerated!short = -0;
        assertNotThrown!RangeError(el.enumerated!short);
        assertNotThrown!ASN1Exception(el.enumerated!short);

        el.enumerated!int = -0;
        assertNotThrown!RangeError(el.enumerated!int);
        assertNotThrown!ASN1Exception(el.enumerated!int);

        el.enumerated!long = -0;
        assertNotThrown!RangeError(el.enumerated!long);
        assertNotThrown!ASN1Exception(el.enumerated!long);
    }

    /**
        Decodes an $(MONO EmbeddedPDV), which is a constructed data type, defined in
            the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO EmbeddedPDV) as:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        The following additional constraints are applied to the abstract syntax
        when using Canonical Encoding Rules or Distinguished Encoding Rules,
        which are also defined in the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

        $(PRE
            EmbeddedPDV ( WITH COMPONENTS {
                ... ,
                identification ( WITH COMPONENTS {
                    ... ,
                    presentation-context-id ABSENT,
                    context-negotiation ABSENT } ) } )
        )

        The stated purpose of the constraints shown above is to restrict the use of
        the $(MONO presentation-context-id), either by itself or within the
        context-negotiation, which makes the following the effective abstract
        syntax of $(MONO EmbeddedPDV) when using Canonical Encoding Rules or
        Distinguished Encoding Rules:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            presentation-context-id ABSENT,
                            context-negotiation ABSENT } ) } )
        )

        With the constraints applied, the abstract syntax for $(MONO EmbeddedPDV)s encoded
        using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        Returns: an instance of $(D types.universal.embeddedpdv.EmbeddedPDV)

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements)
            $(LI $(D ASN1ValueSizeException) if encoded INTEGER is too large to decode)
            $(LI $(D ASN1RecursionException) if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException) if any nested primitives do not have the
                correct tag class)
            $(LI $(D ASN1ConstructionException) if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException) if any nested primitives do not have the
                correct tag number)
        )
    */
    override public @property @system
    EmbeddedPDV embeddedPresentationDataValue() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a EmbeddedPDV");

        const DERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EmbeddedPDV that contained too many or too few elements. " ~
                "An EmbeddedPDV should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (components[0].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[0].tagClass,
                "decode the first component of an EmbeddedPDV"
            );

        if (components[1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[1].tagClass,
                "decode the second component of an EmbeddedPDV"
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u)
            throw new ASN1TagNumberException
            ([ 0u ], components[0].tagNumber, "decode the first component of an EmbeddedPDV");

        if (components[1].tagNumber != 2u)
            throw new ASN1TagNumberException
            ([ 2u ], components[1].tagNumber, "decode the second component of an EmbeddedPDV");

        ubyte[] bytes = components[0].value.dup;
        const DERElement identificationChoice = new DERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the syntaxes component of an EmbeddedPDV");

                const DERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EmbeddedPDV whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                // Class Validation
                if (syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[0].tagClass,
                        "decode the first syntaxes component of an EmbeddedPDV"
                    );

                if (syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[1].tagClass,
                        "decode the second syntaxes component of an EmbeddedPDV"
                    );

                // Construction Validation
                if (syntaxesComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[0].construction, "decode the first syntaxes component of an EmbeddedPDV");

                if (syntaxesComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[1].construction, "decode the second syntaxes component of an EmbeddedPDV");

                // Number Validation
                if (syntaxesComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        syntaxesComponents[0].tagNumber,
                        "decode the first syntaxes component of an EmbeddedPDV"
                    );

                if (syntaxesComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        syntaxesComponents[1].tagNumber,
                        "decode the second syntaxes component of an EmbeddedPDV"
                    );

                identification.syntaxes  = ASN1Syntaxes(
                    syntaxesComponents[0].objectIdentifier,
                    syntaxesComponents[1].objectIdentifier
                );

                break;
            }
            case (1u): // syntax
            {
                identification.syntax = identificationChoice.objectIdentifier;
                break;
            }
            case (4u): // transfer-syntax
            {
                identification.transferSyntax = identificationChoice.objectIdentifier;
                break;
            }
            case (5u): // fixed
            {
                identification.fixed = true;
                break;
            }
            default:
                throw new ASN1TagNumberException
                (
                    [ 0u, 1u, 4u, 5u ],
                    identificationChoice.tagNumber,
                    "decode an EmbeddedPDV identification"
                );
        }

        EmbeddedPDV pdv = EmbeddedPDV();
        pdv.identification = identification;
        pdv.dataValue = components[1].octetString;
        return pdv;
    }

    /**
        Encodes an $(MONO EmbeddedPDV), which is a constructed data type, defined in
            the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO EmbeddedPDV) as:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        The following additional constraints are applied to the abstract syntax
        when using Canonical Encoding Rules or Distinguished Encoding Rules,
        which are also defined in the
        $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

        $(PRE
            EmbeddedPDV ( WITH COMPONENTS {
                ... ,
                identification ( WITH COMPONENTS {
                    ... ,
                    presentation-context-id ABSENT,
                    context-negotiation ABSENT } ) } )
        )

        The stated purpose of the constraints shown above is to restrict the use of
        the $(MONO presentation-context-id), either by itself or within the
        context-negotiation, which makes the following the effective abstract
        syntax of $(MONO EmbeddedPDV) when using Canonical Encoding Rules or
        Distinguished Encoding Rules:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            presentation-context-id ABSENT,
                            context-negotiation ABSENT } ) } )
        )

        With the constraints applied, the abstract syntax for $(MONO EmbeddedPDV)s encoded
        using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

        $(PRE
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        If the supplied $(MONO identification) for the EmbeddedPDV is a
        $(MONO presentation-context-id) or a $(MONO context-negotiation),
        no exception will be thrown; the $(MONO identification) will be set to
        $(MONO fixed) silently.

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded ObjectDescriptor contains invalid characters)
        )
    */
    override public @property @system
    void embeddedPresentationDataValue(in EmbeddedPDV value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.constructed;
        DERElement identification = new DERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        DERElement identificationChoice = new DERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            DERElement abstractSyntax = new DERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            DERElement transferSyntax = new DERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationChoice.construction = ASN1Construction.constructed;
            identificationChoice.tagNumber = 0u;
            identificationChoice.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationChoice.tagNumber = 1u;
            identificationChoice.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        DERElement dataValue = new DERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = 2u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of presentation-context-id in EmbeddedPDV.

        This unit test ensures that, if you attempt to create an EmbeddedPDV
        with presentation-context-id as the CHOICE of identification, the
        encoded EmbeddedPDV's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        DERElement el = new DERElement();
        el.tagNumber = 0x08u;
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of context-negotiation in EmbeddedPDV.

        This unit test ensures that, if you attempt to create an EmbeddedPDV
        with context-negotiation as the CHOICE of identification, the
        encoded EmbeddedPDV's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextNegotiation cn = ASN1ContextNegotiation();
        cn.presentationContextID = 27L;
        cn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.contextNegotiation = cn;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x13u, 0x15u, 0x17u, 0x19u ];

        DERElement el = new DERElement();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x13u, 0x15u, 0x17u, 0x19u ]);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] data = [ // This is valid.
            0x0Bu, 0x0Au, // EmbeddedPDV, Length 11
                0x80u, 0x02u, // CHOICE
                    0x85u, 0x00u, // NULL
                0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ]; // OCTET STRING

        // Valid values for data[2]: 80
        for (ubyte i = 0x81u; i < 0x9Eu; i++)
        {
            data[2] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }

        // Valid values for data[4]: 80-85
        for (ubyte i = 0x86u; i < 0x9Eu; i++)
        {
            data[4] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }

        // Valid values for data[6]: 82
        for (ubyte i = 0x83u; i < 0x9Eu; i++)
        {
            data[6] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }
    }

    /**
        Decodes the value to UTF-8 characters.

        Throws:
        $(UL
            $(LI $(D UTF8Exception)
                if the encoded value does not decode to UTF-8)
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )
    */
    override public @property @system
    string unicodeTransformationFormat8String() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a UTF8String");

        return cast(string) this.value;
    }

    /// Encodes a UTF-8 string to bytes.
    override public @property @system nothrow
    void unicodeTransformationFormat8String(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a $(MONO RELATIVE OBJECT IDENTIFIER).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValuePaddingException) if a single OID number is encoded with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1ValueOverflowException) if a single OID number is too big to
                decode to a $(D size_t))
            $(LI $(D ASN1TruncationException) if a single OID number is "cut off")
        )

        Standards:
        $(UL
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
    */
    override public @property @system
    OIDNode[] relativeObjectIdentifier() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a RELATIVE OID");

        if (this.value.length == 0u) return [];

        if (this.value[$-1] > 0x80u)
            throw new ASN1TruncationException
            (size_t.max, this.value.length, "decode a RELATIVE OID");

        size_t[] numbers;
        size_t components = 0u;
        foreach (immutable size_t i, immutable ubyte b; this.value)
        {
            if (!(b & 0x80u)) components++;
        }
        numbers.length = components;

        size_t currentNumber = 0u;
        ubyte bytesUsedInCurrentNumber = 0u;
        foreach (immutable ubyte b; this.value)
        {
            if (bytesUsedInCurrentNumber == 0u && b == 0x80u)
                throw new ASN1ValuePaddingException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that contained a number that was " ~
                    "encoded on more than the minimum necessary octets. This " ~
                    "is indicated by an occurrence of the octet 0x80, which " ~
                    "is the encoded equivalent of a leading zero. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            if (numbers[currentNumber] > (size_t.max >> 7))
                throw new ASN1ValueOverflowException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that encoded a number that is too big to " ~
                    "decode to a native integral type. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            numbers[currentNumber] <<= 7;
            numbers[currentNumber] |= cast(size_t) (b & 0x7Fu);

            if (!(b & 0x80u))
            {
                currentNumber++;
                bytesUsedInCurrentNumber = 0u;
            }
            else
            {
                bytesUsedInCurrentNumber++;
            }
        }

        // Constructs the array of OIDNodes from the array of numbers.
        OIDNode[] nodes;
        nodes.length = numbers.length;
        foreach (immutable size_t i, immutable size_t number; numbers)
        {
            nodes[i] = OIDNode(number);
        }

        return nodes;
    }

    /**
        Encodes a $(MONO RELATIVE OBJECT IDENTIFIER).

        Standards:
            $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    override public @property @system nothrow
    void relativeObjectIdentifier(in OIDNode[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value.length = 0u;
        foreach (node; value)
        {
            size_t number = node.number;
            if (number < 128u)
            {
                this.value ~= cast(ubyte) number;
                continue;
            }

            ubyte[] encodedOIDNode;
            while (number != 0u)
            {
                ubyte[] numberBytes;
                numberBytes.length = size_t.sizeof;
                *cast(size_t *) numberBytes.ptr = number;
                if ((numberBytes[0] & 0x80u) == 0u) numberBytes[0] |= 0x80u;
                encodedOIDNode = numberBytes[0] ~ encodedOIDNode;
                number >>= 7u;
            }

            encodedOIDNode[$-1] &= 0x7Fu;
            this.value ~= encodedOIDNode;
        }
    }

    @system
    unittest
    {
        DERElement element = new DERElement();

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0x80u; i++)
        {
            element.value = [ i ];
            assertNotThrown!Exception(element.roid);
        }

        // All values of octet[0] should pass.
        for (ubyte i = 0x81u; i < 0xFFu; i++)
        {
            element.value = [ i, 0x14u ];
            assertNotThrown!Exception(element.roid);
        }
    }

    @system
    unittest
    {
        DERElement element = new DERElement();

        // Tests for the "leading zero byte," 0x80
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1TruncationException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1TruncationException(element.roid);
    }

    /**
        Decodes a sequence of elements

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "primitive")
            $(LI And all of the exceptions thrown by the constructor)
        )
    */
    override public @property @system
    DERElement[] sequence() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a SEQUENCE");

        size_t i = 0u;
        Appender!(DERElement[]) result = appender!(DERElement[])();
        while (i < this.value.length)
            result.put(new DERElement(i, this.value));
        return result.data;
    }

    /// Encodes a sequence of elements
    override public @property @system
    void sequence(in DERElement[] value)
    {
        scope(success) this.construction = ASN1Construction.constructed;
        Appender!(ubyte[]) result = appender!(ubyte[])();
        foreach (element; value)
        {
            result.put(element.toBytes);
        }
        this.value = result.data;
    }

    /**
        Decodes a set of elements

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "primitive")
            $(LI And all of the exceptions thrown by the constructor)
        )
    */
    override public @property @system
    DERElement[] set() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a SET");

        size_t i = 0u;
        Appender!(DERElement[]) result = appender!(DERElement[])();
        while (i < this.value.length)
            result.put(new DERElement(i, this.value));
        return result.data;
    }

    /// Encodes a set of elements
    override public @property @system
    void set(in DERElement[] value)
    {
        scope(success) this.construction = ASN1Construction.constructed;
        Appender!(ubyte[]) result = appender!(ubyte[])();
        foreach (element; value)
        {
            result.put(element.toBytes);
        }
        this.value = result.data;
    }

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and $(MONO SPACE).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException) if any character other than 0-9 or space is encoded.)
        )
    */
    override public @property @system
    string numericString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a NumericString");

        foreach (immutable character; this.value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueCharactersException
                ("1234567890 ", character, "NumericString");
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any character other than 0-9 or space is supplied.)
        )
    */
    override public @property @system
    void numericString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueCharactersException
                ("1234567890 ", character, "NumericString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException)
                if any character other than a-z, A-Z,
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                encoded)
        )
    */
    override public @property @system
    string printableString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a PrintableString");

        foreach (immutable character; this.value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueCharactersException
                (printableStringCharacters, character, "PrintableString");
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string that may only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.

        Throws:
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException) if any character other than a-z, A-Z,
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                supplied)
    */
    override public @property @system
    void printableString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueCharactersException
                (printableStringCharacters, character, "PrintableString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a T.61 character.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )
    */
    override public @property @safe
    ubyte[] teletexString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a TeletexString (T61String)");

        return this.value.dup;
    }

    /// Literally just sets the value bytes.
    override public @property @safe nothrow
    void teletexString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a Videotex character.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
        )
    */
    override public @property @safe
    ubyte[] videotexString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a VideotexString");

        return this.value.dup;
    }

    /// Literally just sets the value bytes.
    override public @property @safe nothrow
    void videotexString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    /**
        Decodes a string that only contains ASCII characters.

        $(MONO IA5String) differs from ASCII ever so slightly: IA5 is international,
        leaving 10 characters up to be locale-specific:

        $(TABLE
            $(TR $(TH Byte) $(TH ASCII Character))
            $(TR $(TD 0x40) $(TD @))
            $(TR $(TD 0x5B) $(TD [))
            $(TR $(TD 0x5C) $(TD \))
            $(TR $(TD 0x5D) $(TD ]))
            $(TR $(TD 0x5E) $(TD ^))
            $(TR $(TD 0x60) $(TD `))
            $(TR $(TD 0x7B) $(TD {))
            $(TR $(TD 0x7C) $(TD /))
            $(TR $(TD 0x7D) $(TD }))
            $(TR $(TD 0x7E) $(TD ~))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )
    */
    override public @property @system
    string internationalAlphabetNumber5String() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an IA5String");

        string ret = cast(string) this.value;
        foreach (immutable character; ret)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "IA5String");
        }
        return ret;
    }

    /**
        Encodes a string that may only contain ASCII characters.

        $(MONO IA5String) differs from ASCII ever so slightly: IA5 is international,
        leaving 10 characters up to be locale-specific:

        $(TABLE
            $(TR $(TH Byte) $(TH ASCII Character))
            $(TR $(TD 0x40) $(TD @))
            $(TR $(TD 0x5B) $(TD [))
            $(TR $(TD 0x5C) $(TD \))
            $(TR $(TD 0x5D) $(TD ]))
            $(TR $(TD 0x5E) $(TD ^))
            $(TR $(TD 0x60) $(TD `))
            $(TR $(TD 0x7B) $(TD {))
            $(TR $(TD 0x7C) $(TD /))
            $(TR $(TD 0x7D) $(TD }))
            $(TR $(TD 0x7E) $(TD ~))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )
    */
    override public @property @system
    void internationalAlphabetNumber5String(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "IA5String");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of the UTC-formatted timestamp.

        An UTC Timestamp looks like:
        $(UL
            $(LI $(MONO 9912312359Z))
            $(LI $(MONO 991231235959+0200))
        )

        If the first digit of the two-digit year is 7, 6, 5, 4, 3, 2, 1, or 0,
        meaning that the date refers to the first 80 years of the century, this
        assumes we are talking about the 21st century and prepend '20' when
        creating the ISO Date String. Otherwise, it assumes we are talking
        about the 20th century, and prepend '19' when creating the string.

        See_Also:
        $(UL
            $(LI $(LINK https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime))
            $(LI $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueException) if the encoded value does not end with a 'Z')
            $(LI $(D ASN1ValueCharactersException) if any character is not valid in a $(MONO Visiblestring))
            $(LI $(D DateTimeException) if the encoded string cannot be decoded to a DateTime)
        )
    */
    override public @property @system
    DateTime coordinatedUniversalTime() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a UTCTime");

        // Mandated in X.690, section 11.8.2
        if (this.value.length != 13u) // YYMMDDhhmmssZ
            throw new ASN1ValueSizeException(13u, 13u, this.value.length, "decode a UTCTime");

        // Mandated in X.690, section 11.8.1
        if (this.value[$-1] != 'Z')
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "a UTCTime whose encoding did not terminate with a 'Z', as " ~
                "is expected by the Canonical Encoding Rules (CER) and " ~
                "Distinguished Encoding Rules (DER). " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        immutable string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of
        the UTC-formatted timestamp.

        An UTC Timestamp looks like:
        $(UL
            $(LI $(MONO 9912312359Z))
            $(LI $(MONO 991231235959+0200))
        )

        See_Also:
            $(LINK https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime)
    */
    override public @property @system
    void coordinatedUniversalTime(in DateTime value)
    out
    {
        // YYMMDDhhmmssZ is the only acceptable format for DER
        assert(this.value.length == 13u);
        assert(this.value[$-1] == 'Z');
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString()[2 .. $].replace("T", ""));
    }

    @system
    unittest
    {
        DERElement el = new DERElement();
        el.utcTime = DateTime(2017, 10, 3);
        assert(el.visibleString == "171003000000Z");
    }

    /**
        Decodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of
        the $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like:
        $(UL
            $(LI $(MONO 19851106210627.3))
            $(LI $(MONO 19851106210627.3Z))
            $(LI $(MONO 19851106210627.3-0500))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueException) if the encoded value did not end with a 'Z'
                or contained a misplaced or unnecessary decimal point)
            $(LI $(D ASN1ValueCharactersException) if any character is not valid in a $(MONO Visiblestring))
            $(LI $(D DateTimeException) if the encoded string cannot be decoded to a DateTime)
            $(LI $(D ASN1ValuePaddingException) if the seconds fraction contains trailing zeroes)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )

        Standards:
        $(UL
            $(LI $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601))
        )
    */
    override public @property @system
    DateTime generalizedTime() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a GeneralizedTime");

        if (this.value.length < 15u)
            throw new ASN1ValueSizeException(15u, size_t.max, this.value.length, "decode a GeneralizedTime");

        // Inferred, because YYYYMMDDhhmmss.Z could not be valid.
        if (this.value.length == 16u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode a " ~
                "GeneralizedTime that was encoded on too few bytes to be " ~
                "correct. A valid GeneralizedTime cannot be 16 bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        // Mandated in X.690, section 11.7.1
        if (this.value[$-1] != 'Z')
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "a GeneralizedTime whose encoding did not terminate with a 'Z', " ~
                "as is expected by the Canonical Encoding Rules (CER) and " ~
                "Distinguished Encoding Rules (DER). " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        ptrdiff_t indexOfDecimalPoint = (cast(string) this.value).indexOf('.');
        if (indexOfDecimalPoint != -1)
        {
            if (this.value[$-2] == '0')
                throw new ASN1ValuePaddingException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a GeneralizedTime that contained trailing zeroes in the " ~
                    "fraction-of-seconds part. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            if (indexOfDecimalPoint != 14)
                throw new ASN1ValueException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a GeneralizedTime whose decimal point was misplaced. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }
        else
        {
            if ((cast(string) this.value).indexOf(',') != -1)
                throw new ASN1ValueCharactersException
                ("1234567890Z.", ',', "decode a GeneralizedTime");
        }

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        immutable string dt = cast(string) this.value;
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).

        The value is just the ASCII character representation of
        the $(LINK https://www.iso.org/iso-8601-date-and-time-format.html,
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like:
        $(UL
            $(LI $(MONO 19851106210627.3))
            $(LI $(MONO 19851106210627.3Z))
            $(LI $(MONO 19851106210627.3-0500))
        )

        Standards:
        $(UL
            $(LI $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601))
        )
    */
    override public @property @system
    void generalizedTime(in DateTime value)
    out
    {
        assert(this.value.length > 0u);
        assert((cast(string) this.value).indexOf("T") == -1);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.primitive;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString().replace("T", ""));
    }

    // Positive tests
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.generalizedTime = DateTime(2017, 10, 3);
        assert(el.visibleString == "20171003000000Z");

        el.visibleString = "20171003000000.003Z";
        assertNotThrown!Exception(el.generalizedTime);

        el.visibleString = "20171003000000.0000003Z";
        assertNotThrown!Exception(el.generalizedTime);
    }

    // Negative tests
    @system
    unittest
    {
        DERElement el = new DERElement();

        el.visibleString = "20171003000000.Z";
        assertThrown!ASN1Exception(el.generalizedTime);

        el.visibleString = "20171003000000.0Z";
        assertThrown!ASN1Exception(el.generalizedTime);

        el.visibleString = "20171003000000.000000Z";
        assertThrown!ASN1Exception(el.generalizedTime);

        el.visibleString = "0171003000000Z";
        assertThrown!ASN1Exception(el.generalizedTime);

        el.visibleString = "2017100300000Z"; // Missing 1 trailing zero.
        assertThrown!ASN1Exception(el.generalizedTime);
    }

    /**
        Decodes an ASCII string that contains only characters between and
        including $(D 0x20) and $(D 0x75). Deprecated, according to page 182 of the
        Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException) if any non-graphical character (including space) is encoded)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string graphicString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a GraphicString");

        string ret = cast(string) this.value;
        foreach (immutable character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "GraphicString");
        }
        return ret;
    }

    /**
        Encodes an ASCII string that may contain only characters between and
        including $(D 0x20) and $(D 0x75). Deprecated, according to page 182
        of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any non-graphical character (including space) is supplied)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    void graphicString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "GraphicString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string that only contains characters between and including
        $(D 0x20) and $(D 0x7E). (Honestly, I don't know how this differs from
        $(MONO GraphicalString).)

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException)
                if any non-graphical character (including space) is encoded)
        )
    */
    override public @property @system
    string visibleString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a VisibleString");

        string ret = cast(string) this.value;
        foreach (immutable character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "VisibleString");
        }
        return ret;
    }

    /**
        Encodes a string that only contains characters between and including
        $(D 0x20) and $(D 0x7E). (Honestly, I don't know how this differs from
        $(MONO GraphicalString).)

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if any non-graphical character (including space) is supplied.)
        )
    */
    override public @property @system
    void visibleString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "VisibleString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string containing only ASCII characters. Deprecated, according
        to page 182 of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, p. 182.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string generalString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a GeneralString");

        string ret = cast(string) this.value;
        foreach (immutable character; ret)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "GeneralString");
        }
        return ret;
    }

    /**
        Encodes a string containing only ASCII characters. Deprecated,
        according to page 182 of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, p. 182.)
        )
    */
    override public @property @system
    void generalString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "GeneralString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a $(MONO dstring) of UTF-32 characters.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueException)
                if the encoded bytes is not evenly divisible by four)
        )
    */
    override public @property @system
    dstring universalString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a UniversalString");

        if (this.value.length == 0u) return ""d;
        if (this.value.length % 4u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you tried to decode " ~
                "a UniversalString that contained a number of bytes that " ~
                "is not divisible by four. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        version (BigEndian)
        {
            return cast(dstring) this.value;
        }
        else version (LittleEndian)
        {
            dchar[] ret;
            ret.length = (this.value.length >> 2);
            foreach (immutable size_t i, ref dchar c; ret)
            {
                immutable size_t byteIndex = (i << 2);
                *cast(ubyte[4] *) &c = [
                    this.value[(byteIndex + 3u)],
                    this.value[(byteIndex + 2u)],
                    this.value[(byteIndex + 1u)],
                    this.value[(byteIndex + 0u)]
                ];
            }
            return cast(dstring) ret;
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /// Encodes a $(MONO dstring) of UTF-32 characters.
    override public @property @system
    void universalString(in dstring value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value.dup;
        }
        else version (LittleEndian)
        {
            foreach(immutable character; value)
            {
                ubyte[] charBytes = cast(ubyte[]) *cast(char[4] *) &character;
                reverse(charBytes);
                this.value ~= charBytes;
            }
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /**
        Decodes a $(MONO CharacterString), which is a constructed data type, defined
        in the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO CharacterString) as:

        $(PRE
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        Returns: an instance of $(D types.universal.characterstring.CharacterString).

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded $(MONO CharacterString) has too few or too many
                elements, or if $(MONO syntaxes) or $(MONO context-negotiation) element has
                too few or too many elements)
            $(LI $(D ASN1ValueSizeException) if encoded $(MONO INTEGER) is too large to decode)
            $(LI $(D ASN1RecursionException) if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException) if any nested primitives do not have the
                correct tag class)
            $(LI $(D ASN1ConstructionException) if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException) if any nested primitives do not have the
                correct tag number)
        )
    */
    override public @property @system
    CharacterString characterString() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a CharacterString");

        const DERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "a CharacterString that contained too many or too few elements. " ~
                "A CharacterString should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (components[0].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[0].tagClass,
                "decode the first component of a CharacterString"
            );

        if (components[1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[1].tagClass,
                "decode the second component of a CharacterString"
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u)
            throw new ASN1TagNumberException
            ([ 0u ], components[0].tagNumber, "decode the first component of a CharacterString");

        if (components[1].tagNumber != 2u)
            throw new ASN1TagNumberException
            ([ 2u ], components[1].tagNumber, "decode the second component of a CharacterString");

        ubyte[] bytes = components[0].value.dup;
        const DERElement identificationChoice = new DERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the syntaxes component of a CharacterString");

                const DERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                // Class Validation
                if (syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[0].tagClass,
                        "decode the first syntaxes component of a CharacterString"
                    );

                if (syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[1].tagClass,
                        "decode the second syntaxes component of a CharacterString"
                    );

                // Construction Validation
                if (syntaxesComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[0].construction, "decode the first syntaxes component of a CharacterString");

                if (syntaxesComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[1].construction, "decode the second syntaxes component of a CharacterString");

                // Number Validation
                if (syntaxesComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        syntaxesComponents[0].tagNumber,
                        "decode the first syntaxes component of a CharacterString"
                    );

                if (syntaxesComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        syntaxesComponents[1].tagNumber,
                        "decode the second syntaxes component of a CharacterString"
                    );

                identification.syntaxes  = ASN1Syntaxes(
                    syntaxesComponents[0].objectIdentifier,
                    syntaxesComponents[1].objectIdentifier
                );

                break;
            }
            case (1u): // syntax
            {
                identification.syntax = identificationChoice.objectIdentifier;
                break;
            }
            case (4u): // transfer-syntax
            {
                identification.transferSyntax = identificationChoice.objectIdentifier;
                break;
            }
            case (5u): // fixed
            {
                identification.fixed = true;
                break;
            }
            default:
                throw new ASN1TagNumberException
                (
                    [ 0u, 1u, 4u, 5u ],
                    identificationChoice.tagNumber,
                    "decode a CharacterString identification"
                );
        }

        CharacterString cs = CharacterString();
        cs.identification = identification;
        cs.stringValue = components[1].octetString;
        return cs;
    }

    /**
        Encodes a $(MONO CharacterString), which is a constructed data type, defined
        in the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO CharacterString) as:

        $(PRE
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.
    */
    override public @property @system
    void characterString(in CharacterString value)
    out
    {
        assert(this.value.length > 0u);
    }
    do
    {
        scope(success) this.construction = ASN1Construction.constructed;
        DERElement identification = new DERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        DERElement identificationChoice = new DERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            DERElement abstractSyntax = new DERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            DERElement transferSyntax = new DERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationChoice.construction = ASN1Construction.constructed;
            identificationChoice.tagNumber = 0u;
            identificationChoice.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationChoice.tagNumber = 1u;
            identificationChoice.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        DERElement stringValue = new DERElement();
        stringValue.tagClass = ASN1TagClass.contextSpecific;
        stringValue.tagNumber = 2u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of context-negotiation in CharacterString.

        This unit test ensures that, if you attempt to create a CharacterString
        with context-negotiation as the CHOICE of identification, the
        encoded CharacterString's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextNegotiation cn = ASN1ContextNegotiation();
        cn.presentationContextID = 27L;
        cn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.contextNegotiation = cn;

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        DERElement el = new DERElement();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.fixed == true);
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] data = [ // This is valid.
            0x1Eu, 0x0Au, // CharacterString, Length 11
                0x80u, 0x02u, // CHOICE
                    0x85u, 0x00u, // NULL
                0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ]; // OCTET STRING

        // Valid values for data[2]: 80
        for (ubyte i = 0x81u; i < 0x9Eu; i++)
        {
            data[2] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }

        // Valid values for data[4]: 80-85
        for (ubyte i = 0x86u; i < 0x9Eu; i++)
        {
            data[4] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }

        // Valid values for data[6]: 82
        for (ubyte i = 0x83u; i < 0x9Eu; i++)
        {
            data[6] = i;
            size_t x = 0u;
            DERElement el = new DERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }
    }

    /**
        Decodes a $(MONO wstring) of UTF-16 characters.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueException)
                if the encoded bytes is not evenly divisible by two)
        )
    */
    override public @property @system
    wstring basicMultilingualPlaneString() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a BMPString");

        if (this.value.length == 0u) return ""w;
        if (this.value.length % 2u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you tried to decode " ~
                "a BMPString that contained a number of bytes that " ~
                "is not divisible by two. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        version (BigEndian)
        {
            return cast(wstring) this.value;
        }
        else version (LittleEndian)
        {
            wchar[] ret;
            ret.length = (this.value.length >> 1);
            foreach (immutable size_t i, ref wchar c; ret)
            {
                immutable size_t byteIndex = (i << 1);
                *cast(ubyte[2] *) &c = [
                    this.value[(byteIndex + 1u)],
                    this.value[(byteIndex + 0u)]
                ];
            }
            return cast(wstring) ret;
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /// Encodes a $(MONO wstring) of UTF-16 characters.
    override public @property @system
    void basicMultilingualPlaneString(in wstring value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value.dup;
        }
        else version (LittleEndian)
        {
            foreach(immutable character; value)
            {
                ubyte[] charBytes = cast(ubyte[]) *cast(char[2] *) &character;
                reverse(charBytes);
                this.value ~= charBytes;
            }
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /// Creates an $(MONO END OF CONTENT) by default
    public @safe @nogc nothrow
    this
    (
        ASN1TagClass tagClass = ASN1TagClass.universal,
        ASN1Construction construction = ASN1Construction.primitive,
        size_t tagNumber = 0u
    )
    {
        this.tagClass = tagClass;
        this.construction = construction;
        this.tagNumber = tagNumber;
        this.value = [];
    }

    /**
        Creates a $(D DERElement) from the supplied bytes, inferring that the first
        byte is the type tag. The supplied $(D ubyte[]) array is "chomped" by
        reference, so the original array will grow shorter as $(D DERElement)s are
        generated.

        Throws:
            All of the same exceptions as $(D fromBytes())

        Examples:
        ---
        // Decoding looks like:
        DERElement[] result;
        while (bytes.length > 0)
            result ~= new DERElement(bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (dv; dervalues)
        {
            result ~= cast(ubyte[]) dv;
        }
        ---
    */
    public @system
    this (ref ubyte[] bytes)
    {
        immutable size_t bytesRead = this.fromBytes(bytes);
        bytes = bytes[bytesRead .. $];
    }

    /**
        Creates a $(D DERElement) from the supplied bytes, inferring that the first
        byte is the type tag. Unlike the construct that accepts a $(D ubyte[])
        reference, this constructor does not "chomp" the array. This constructor
        expects the encoded bytes to encode only one $(DERElement). If there are
        any remaining bytes after decoding, an exception is thrown.

        Throws:
            All of the same exceptions as $(D fromBytes()), but also throws an
            $(D ASN1LengthException) if there are excess bytes.
    */
    public @system
    this (in ubyte[] bytes)
    {
        immutable size_t bytesRead = this.fromBytes(bytes);
        if (bytesRead != bytes.length)
            throw new ASN1LengthException
            (
                "This exception was thrown because you attempted to decode " ~
                "a single ASN.1 element that was encoded on too many bytes. " ~
                "The entire element was decoded from " ~ text(bytesRead) ~ " " ~
                "bytes, but " ~ text(bytes.length) ~ " bytes were supplied to " ~
                "decode."
            );
    }

    /**
        Creates a $(D DERElement) from the supplied bytes, inferring that the first
        byte is the type tag. The supplied $(D ubyte[]) array is read, starting
        from the index specified by $(D bytesRead), and increments
        $(D bytesRead) by the number of bytes read.

        Throws:
            All of the same exceptions as $(D fromBytes())

        Examples:
        ---
        // Decoding looks like:
        DERElement[] result;
        size_t i = 0u;
        while (i < bytes.length)
            result ~= new DERElement(i, bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (dv; dervalues)
        {
            result ~= cast(ubyte[]) dv;
        }
        ---
    */
    public @system
    this (ref size_t bytesRead, in ubyte[] bytes)
    {
        bytesRead += this.fromBytes(bytes[bytesRead .. $].dup);
    }

    /**
        Returns: the number of bytes read

        Throws:
        $(UL
            $(LI $(D ASN1TagPaddingException) if the tag number is "padded" with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1TagOverflowException) if the tag number is too large to
                fit into a $(D size_t))
            $(LI $(D ASN1LengthUndefinedException) if the reserved length byte of
                $(D 0xFF) is encountered)
            $(LI $(D ASN1LengthOverflowException) if the length is too large to fit
                into a $(D size_t))
            $(LI $(D ASN1TruncationException) if the tag, length, or value appear to
                be truncated)
            $(LI $(D ASN1ConstructionException) if the length is indefinite, but the
                element is marked as being encoded primitively)
            $(LI $(D ASN1LengthException) if indefinite-length encoding is encountered)
        )
    */
    public
    size_t fromBytes (in ubyte[] bytes)
    {
        if (bytes.length < 2u)
            throw new ASN1TruncationException
            (
                2u,
                bytes.length,
                "decode the tag of a Distinguished Encoding Rules (DER) encoded element"
            );

        // Index of what we are currently parsing.
        size_t cursor = 0u;

        switch (bytes[cursor] & 0b11000000u)
        {
            case (0b00000000u): this.tagClass = ASN1TagClass.universal; break;
            case (0b01000000u): this.tagClass = ASN1TagClass.application; break;
            case (0b10000000u): this.tagClass = ASN1TagClass.contextSpecific; break;
            case (0b11000000u): this.tagClass = ASN1TagClass.privatelyDefined; break;
            default: assert(0, "Impossible tag class appeared!");
        }

        this.construction = ((bytes[cursor] & 0b00100000u) ?
            ASN1Construction.constructed : ASN1Construction.primitive);

        this.tagNumber = (bytes[cursor] & 0b00011111u);
        cursor++;
        if (this.tagNumber >= 31u)
        {
            /* NOTE:
                Section 8.1.2.4.2, point C of the International
                Telecommunications Union's X.690 specification says:

                "bits 7 to 1 of the first subsequent octet shall not all be zero."

                in reference to the bytes used to encode the tag number in long
                form, which happens when the least significant five bits of the
                first byte are all set.

                This essentially means that the long-form tag number must be
                encoded on the fewest possible octets. If the first byte is
                0x80, then it is not encoded on the fewest possible octets.
            */
            if (bytes[cursor] == 0b10000000u)
                throw new ASN1TagPaddingException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a Distinguished Encoding Rules (DER) encoded element whose tag " ~
                    "number was encoded in long form in the octets following " ~
                    "the first octet of the type tag, and whose tag number " ~
                    "was encoded with a 'leading zero' byte, 0x80. When " ~
                    "using Distinguished Encoding Rules (DER), the tag number must " ~
                    "be encoded on the smallest number of octets possible, " ~
                    "which the inclusion of leading zero bytes necessarily " ~
                    "contradicts. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );

            this.tagNumber = 0u;

            // This loop looks for the end of the encoded tag number.
            immutable size_t limit = ((bytes.length-1 >= size_t.sizeof) ? size_t.sizeof : bytes.length-1);
            while (cursor < limit)
            {
                if (!(bytes[cursor++] & 0x80u)) break;
            }

            if (bytes[cursor-1] & 0x80u)
            {
                if (limit == bytes.length-1)
                {
                    throw new ASN1TruncationException
                    (size_t.max, bytes.length, "decode an ASN.1 tag number");
                }
                else
                {
                    throw new ASN1TagOverflowException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "a Distinguished Encoding Rules (DER) encoded element that encoded " ~
                        "a tag number that was either too large to decode or " ~
                        "terminated prematurely."
                    );
                }
            }

            for (size_t i = 1; i < cursor; i++)
            {
                this.tagNumber <<= 7;
                this.tagNumber |= cast(size_t) (bytes[i] & 0x7Fu);
            }
        }

        // Length
        if ((bytes[cursor] & 0x80u) == 0x80u)
        {
            immutable ubyte numberOfLengthOctets = (bytes[cursor] & 0x7Fu);
            if (numberOfLengthOctets) // Definite Long or Reserved
            {
                if (numberOfLengthOctets == 0b01111111u) // Reserved
                    throw new ASN1LengthUndefinedException();

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1LengthOverflowException();

                if (cursor + numberOfLengthOctets >= bytes.length)
                    throw new ASN1TruncationException
                    (
                        numberOfLengthOctets,
                        ((bytes.length - 1) - cursor), // FIXME: You can increment the cursor before this.
                        "decode the length of a Distinguished Encoding Rules (DER) encoded element"
                    );

                if (bytes[++cursor] == 0x00u)
                    throw new ASN1LengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Distinguished Encoding Rules (DER) encoded " ~
                        "element whose length was encoded in definite long " ~
                        "form, and encoded on more octets than necessary, " ~
                        "which is prohibited by the specification for " ~
                        "Distinguished Encoding Rules (DER). " ~
                        forMoreInformationText ~ debugInformationText ~ reportBugsText
                    );

                ubyte[] lengthNumberOctets;
                lengthNumberOctets.length = size_t.sizeof;
                for (ubyte i = numberOfLengthOctets; i > 0u; i--)
                {
                    lengthNumberOctets[size_t.sizeof-i] = bytes[cursor+numberOfLengthOctets-i];
                }
                version (LittleEndian) reverse(lengthNumberOctets);
                size_t length = *cast(size_t *) lengthNumberOctets.ptr;

                if (length <= 127u)
                    throw new ASN1LengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Distinguished Encoding Rules (DER) encoded " ~
                        "element whose length was encoded in definite long " ~
                        "form, and encoded on more octets than necessary, " ~
                        "which is prohibited by the specification for " ~
                        "Distinguished Encoding Rules (DER). Specifically, it " ~
                        "was encoded in definite-long form when it was less " ~
                        "than or equal to 127, which could have been encoded " ~
                        "in definite-short form. " ~
                        forMoreInformationText ~ debugInformationText ~ reportBugsText
                    );

                if ((cursor + length) < cursor) // This catches an overflow.
                    throw new ASN1LengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Disinguished Encoding Rules (DER) encoded element " ~
                        "that indicated that it was exceedingly large--so " ~
                        "large, in fact, that it cannot be stored on this " ~
                        "computer (18 exabytes if you are on a 64-bit system). " ~
                        "This may indicate that the data you attempted to " ~
                        "decode was either corrupted, malformed, or deliberately " ~
                        "crafted to hack you. You would be wise to ensure that " ~
                        "you are running the latest stable version of this " ~
                        "library. "
                    );

                cursor += (numberOfLengthOctets);

                if ((cursor + length) > bytes.length)
                    throw new ASN1TruncationException
                    (
                        length,
                        (bytes.length - cursor),
                        "decode the value of a Distinguished Encoding Rules (DER) encoded element"
                    );

                this.value = bytes[cursor .. cursor+length].dup;
                return (cursor + length);
            }
            else // Indefinite
            {
                throw new ASN1LengthException
                (
                    "This exception was thrown because an invalid length tag " ~
                    "was encountered. Distinguished Encoding Rules (DER) do not " ~
                    "permit indefinite-length encoded data. Are you sure you are " ~
                    "using the correct codec?"
                );
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[cursor++] & 0x7Fu);

            if ((cursor + length) > bytes.length)
                throw new ASN1TruncationException
                (
                    length,
                    ((bytes.length - 1) - cursor),
                    "decode the value of a Distinguished Encoding Rules (DER) encoded element"
                );

            this.value = bytes[cursor .. cursor+length].dup;
            return (cursor + length);
        }
    }

    /**
        This differs from $(D this.value) in that
        $(D this.value) only returns the value octets, whereas
        $(D this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D this.opCast!(ubyte[])()).

        Returns: type tag, length tag, and value, all concatenated as a $(D ubyte) array.
    */
    public @property @system nothrow
    ubyte[] toBytes() const
    {
        ubyte[] tagBytes = [ 0x00u ];
        tagBytes[0] |= cast(ubyte) this.tagClass;
        tagBytes[0] |= cast(ubyte) this.construction;

        if (this.tagNumber < 31u)
        {
            tagBytes[0] |= cast(ubyte) this.tagNumber;
        }
        else
        {
            /*
                Per section 8.1.2.4 of X.690:
                The last five bits of the first byte being set indicate that
                the tag number is encoded in base-128 on the subsequent octets,
                using the first bit of each subsequent octet to indicate if the
                encoding continues on the next octet, just like how the
                individual numbers of OBJECT IDENTIFIER and RELATIVE OBJECT
                IDENTIFIER are encoded.
            */
            tagBytes[0] |= cast(ubyte) 0b00011111u;
            size_t number = this.tagNumber; // We do not want to modify by reference.
            ubyte[] encodedNumber;
            while (number != 0u)
            {
                ubyte[] numberbytes;
                numberbytes.length = size_t.sizeof+1;
                *cast(size_t *) numberbytes.ptr = number;
                if ((numberbytes[0] & 0x80u) == 0u) numberbytes[0] |= 0x80u;
                encodedNumber = numberbytes[0] ~ encodedNumber;
                number >>= 7u;
            }
            tagBytes ~= encodedNumber;
            tagBytes[$-1] &= 0x7Fu; // Set first bit of last byte to zero.
        }

        ubyte[] lengthOctets = [ 0x00u ];
        if (this.length < 127u)
        {
            lengthOctets = [ cast(ubyte) this.length ];
        }
        else
        {
            size_t length = cast(size_t) this.value.length;
            ubyte[] lengthNumberOctets = cast(ubyte[]) *cast(ubyte[size_t.sizeof] *) &length;
            version (LittleEndian) reverse(lengthNumberOctets);
            size_t startOfNonPadding = 0u;
            for (size_t i = 0u; i < size_t.sizeof; i++)
            {
                if (lengthNumberOctets[i] != 0x00u) break;
                startOfNonPadding++;
            }
            lengthNumberOctets = lengthNumberOctets[startOfNonPadding .. $];
            lengthOctets = [ cast(ubyte) (0x80u + lengthNumberOctets.length) ];
            lengthOctets ~= lengthNumberOctets;
        }

        return (tagBytes ~ lengthOctets ~ this.value);
    }

    /**
        This differs from $(D this.value) in that
        $(D this.value) only returns the value octets, whereas
        $(D this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D this.toBytes()).

        Returns: type tag, length tag, and value, all concatenated as a $(D ubyte) array.
    */
    public @system nothrow
    ubyte[] opCast(T = ubyte[])()
    {
        return this.toBytes();
    }

}

// Tests of all types using definite-short encoding.
@system
unittest
{
    // Test data
    immutable ubyte[] dataEndOfContent = [ 0x00u, 0x00u ];
    immutable ubyte[] dataBoolean = [ 0x01u, 0x01u, 0xFFu ];
    immutable ubyte[] dataInteger = [ 0x02u, 0x01u, 0x1Bu ];
    immutable ubyte[] dataBitString = [ 0x03u, 0x03u, 0x07u, 0xF0u, 0x80u ];
    immutable ubyte[] dataOctetString = [ 0x04u, 0x04u, 0xFF, 0x00u, 0x88u, 0x14u ];
    immutable ubyte[] dataNull = [ 0x05u, 0x00u ];
    immutable ubyte[] dataOID = [ 0x06u, 0x04u, 0x2Bu, 0x06u, 0x04u, 0x01u ];
    immutable ubyte[] dataOD = [ 0x07u, 0x05u, 'H', 'N', 'E', 'L', 'O' ];
    immutable ubyte[] dataExternal = [
        0x28u, 0x0Bu, 0x06u, 0x03u, 0x29u, 0x05u, 0x07u, 0x82u,
        0x04u, 0x01u, 0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    immutable ubyte[] dataEnum = [ 0x0Au, 0x01u, 0x3Fu ];
    immutable ubyte[] dataEmbeddedPDV = [
        0x2Bu, 0x0Au, 0x80u, 0x02u, 0x85u, 0x00u, 0x82u, 0x04u,
        0x01u, 0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataUTF8 = [ 0x0Cu, 0x05u, 'H', 'E', 'N', 'L', 'O' ];
    immutable ubyte[] dataROID = [ 0x0Du, 0x03u, 0x06u, 0x04u, 0x01u ];
    // sequence
    // set
    immutable ubyte[] dataNumeric = [ 0x12u, 0x07u, '8', '6', '7', '5', '3', '0', '9' ];
    immutable ubyte[] dataPrintable = [ 0x13u, 0x06u, '8', '6', ' ', 'b', 'f', '8' ];
    immutable ubyte[] dataTeletex = [ 0x14u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    immutable ubyte[] dataVideotex = [ 0x15u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    immutable ubyte[] dataIA5 = [ 0x16u, 0x08u, 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S' ];
    immutable ubyte[] dataUTC = [ 0x17u, 0x0Du, '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0', 'Z' ];
    immutable ubyte[] dataGT = [ 0x18u, 0x0Fu, '2', '0', '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0', 'Z' ];
    immutable ubyte[] dataGraphic = [ 0x19u, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataVisible = [ 0x1Au, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataGeneral = [ 0x1Bu, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataUniversal = [
        0x1Cu, 0x10u,
        0x00u, 0x00u, 0x00u, 0x61u,
        0x00u, 0x00u, 0x00u, 0x62u,
        0x00u, 0x00u, 0x00u, 0x63u,
        0x00u, 0x00u, 0x00u, 0x64u
    ]; // Big-endian "abcd"
    immutable ubyte[] dataCharacter = [
        0x3Du, 0x0Fu, 0x80u, 0x06u, 0x81u, 0x04u, 0x29u, 0x06u,
        0x04u, 0x01u, 0x82u, 0x05u, 0x48u, 0x45u, 0x4Eu, 0x4Cu,
        0x4Fu ];
    immutable ubyte[] dataBMP = [ 0x1Eu, 0x08u, 0x00u, 0x61u, 0x00u, 0x62u, 0x00u, 0x63u, 0x00u, 0x64u ]; // Big-endian "abcd"

    // Combine it all
    ubyte[] data =
        (dataEndOfContent ~
        dataBoolean ~
        dataInteger ~
        dataBitString ~
        dataOctetString ~
        dataNull ~
        dataOID ~
        dataOD ~
        dataExternal ~
        dataReal ~
        dataEnum ~
        dataEmbeddedPDV ~
        dataUTF8 ~
        dataROID ~
        dataNumeric ~
        dataPrintable ~
        dataTeletex ~
        dataVideotex ~
        dataIA5 ~
        dataUTC ~
        dataGT ~
        dataGraphic ~
        dataVisible ~
        dataGeneral ~
        dataUniversal ~
        dataCharacter ~
        dataBMP).dup;

    DERElement[] result;

    size_t i = 0u;
    while (i < data.length)
        result ~= new DERElement(i, data);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPresentationDataValue;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 27L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.syntax == new OID(1u, 1u, 5u, 7u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realNumber!float == 0.15625);
    assert(result[9].realNumber!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
    assert((m.identification.fixed == true) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[12].utf8String == "HENLO");
    assert(result[13].relativeObjectIdentifier == [ OIDNode(6), OIDNode(4), OIDNode(1) ]);
    assert(result[14].numericString == "8675309");
    assert(result[15].printableString ==  "86 bf8");
    assert(result[16].teletexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[17].videotexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[18].ia5String == "BORTHERS");
    assert(result[19].utcTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[20].generalizedTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[21].graphicString == "PowerThirst");
    assert(result[22].visibleString == "PowerThirst");
    assert(result[23].generalString == "PowerThirst");
    assert(result[24].universalString == "abcd"d);
    assert((c.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (c.stringValue == "HENLO"w));

    result = [];
    while (data.length > 0)
        result ~= new DERElement(data);

    // Pre-processing
    x = result[8].external;
    m = result[11].embeddedPresentationDataValue;
    c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 27L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.syntax == new OID(1u, 1u, 5u, 7u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realNumber!float == 0.15625);
    assert(result[9].realNumber!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
    assert((m.identification.fixed == true) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[12].utf8String == "HENLO");
    assert(result[13].relativeObjectIdentifier == [ OIDNode(6), OIDNode(4), OIDNode(1) ]);
    assert(result[14].numericString == "8675309");
    assert(result[15].printableString ==  "86 bf8");
    assert(result[16].teletexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[17].videotexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[18].ia5String == "BORTHERS");
    assert(result[19].utcTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[20].generalizedTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[21].graphicString == "PowerThirst");
    assert(result[22].visibleString == "PowerThirst");
    assert(result[23].generalString == "PowerThirst");
    assert(result[24].universalString == "abcd"d);
    assert((c.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (c.stringValue == "HENLO"w));
}

// Test of definite-long encoding
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x0Cu, 0x81u, 0xC0u,
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n'
    ];

    data = (data ~ data ~ data); // Triple the data, to catch any bugs that arise with subsequent values.

    DERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new DERElement(i, data);

    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new DERElement(data);

    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');
}

// Test that indefinite-length encoding throws an exception.
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x0Cu, 0x80u,
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x00u, 0x00u
    ];

    data = (data ~ data ~ data); // Triple the data, to catch any bugs that arise with subsequent values.

    size_t i = 0u;
    assertThrown!ASN1LengthException(new DERElement(i, data));
    assertThrown!ASN1LengthException(new DERElement(data));
}

/*
    Test of OCTET STRING encoding on 500 bytes (+4 for type and length tags)

    The number 500 was specifically selected for this test because CER
    uses 1000 as the threshold after which OCTET STRING must be represented
    as a constructed sequence of definite-length-encoded OCTET STRINGS,
    followed by an EOC element, but 500 is also big enough to require
    the length to be encoded on two octets in definite-long form.
*/
@system
unittest
{
    ubyte[] test;
    test.length = 504u;
    test[0] = cast(ubyte) ASN1UniversalType.octetString;
    test[1] = 0b10000010u; // Length is encoded on next two octets
    test[2] = 0x01u; // Most significant byte of length
    test[3] = 0xF4u; // Least significant byte of length
    test[4] = 0x0Au; // First byte of the encoded value
    test[5 .. $-1] = 0x0Bu;
    test[$-1] = 0x0Cu;

    DERElement el;
    assertNotThrown!Exception(el = new DERElement(test));
    ubyte[] output = el.octetString;
    assert(output.length == 500u);
    assert(output[0] == 0x0Au);
    assert(output[1] == 0x0Bu);
    assert(output[$-2] == 0x0Bu);
    assert(output[$-1] == 0x0Cu);
}

// Assert all single-byte encodings do not decode successfully.
@system
unittest
{
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        ubyte[] data = [i];
        assertThrown!Exception(new DERElement(data)); // FIXME: Narrow down the exception
    }

    size_t index;
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        immutable ubyte[] data = [i];
        assertThrown!Exception(new DERElement(index, data));
    }
}

// Test long-form tag number (when # >= 31) with leading zero bytes (0x80)
@system
unittest
{
    ubyte[] invalid;
    invalid = [ 0b10011111u, 0b10000000u ];
    assertThrown!ASN1TagException(new DERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000000u ];
    assertThrown!ASN1TagException(new DERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000111u ];
    assertThrown!ASN1TagException(new DERElement(invalid));
}

// Test long-form tag numbers do not encode with leading zeroes
@system
unittest
{
    ubyte[] invalid;
    DERElement element = new DERElement();
    element.tagNumber = 73u;
    assert((element.toBytes)[1] != 0x80u);
}

// Test that a value that is a byte too short does not throw a RangeError.
@system
unittest
{
    ubyte[] test = [ 0x00u, 0x03u, 0x00u, 0x00u ];
    assertThrown!ASN1TruncationException(new DERElement(test));
}

// Test that a misleading definite-long length byte does not throw a RangeError.
@system
unittest
{
    ubyte[] invalid = [ 0b00000000u, 0b10000001u ];
    assertThrown!ASN1TruncationException(new DERElement(invalid));
}

// Test that leading zeroes in definite long length encodings throw exceptions
@system
unittest
{
    ubyte[] invalid = [ 0b00000000u, 0b10000010u, 0b00000000u, 0b00000001u ];
    assertThrown!ASN1LengthException(new DERElement(invalid));
}

// Test that a very large value does not cause a segfault or something
@system
unittest
{
    size_t biggest = cast(size_t) int.max;
    ubyte[] big = [ 0x00u, 0x80u ];
    big[1] += cast(ubyte) int.sizeof;
    big ~= cast(ubyte[]) *cast(ubyte[int.sizeof] *) &biggest;
    big ~= [ 0x01u, 0x02u, 0x03u ]; // Plus some arbitrary data.
    assertThrown!ASN1TruncationException(new DERElement(big));
}

// Test that the largest possible item does not cause a segfault or something
@system
unittest
{
    size_t biggest = size_t.max;
    ubyte[] big = [ 0x00u, 0x80u ];
    big[1] += cast(ubyte) size_t.sizeof;
    big ~= cast(ubyte[]) *cast(ubyte[size_t.sizeof] *) &biggest;
    big ~= [ 0x01u, 0x02u, 0x03u ]; // Plus some arbitrary data.
    assertThrown!ASN1LengthException(new DERElement(big));
}

// Test that a valueless long-form definite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x00u, 0x82, 0x00u, 0x01u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1LengthException(new DERElement(bytesRead, naughty));
}

// PyASN1 Comparison Testing
@system
unittest
{
    DERElement e = new DERElement();
    e.boolean = false;
    assert(e.value == [ 0x00u ]);
    e.integer = 5;
    assert(e.value == [ 0x05u ]);
    e.bitString = [
        true, false, true, true, false, false, true, true,
        true, false, false, false ];
    assert(e.value == [ 0x04u, 0xB3u, 0x80u ]);
    e.bitString = [
        true, false, true, true, false, true, false, false ];
    assert(e.value == [ 0x00u, 0xB4u ]);
    e.objectIdentifier = new OID(1, 2, 0, 256, 79999, 7);
    assert(e.value == [
        0x2Au, 0x00u, 0x82u, 0x00u, 0x84u, 0xF0u, 0x7Fu, 0x07u ]);
    e.enumerated = 5;
    assert(e.value == [ 0x05u ]);
    e.enumerated = 90000;
    assert(e.value == [ 0x01u, 0x5Fu, 0x90u ]);
}

// Test that all data types that cannot have value length = 0 throw exceptions.
// See CVE-2015-5726.
@system
unittest
{
    DERElement el = new DERElement();
    assertThrown!ASN1Exception(el.boolean);
    assertThrown!ASN1Exception(el.integer!byte);
    assertThrown!ASN1Exception(el.integer!short);
    assertThrown!ASN1Exception(el.integer!int);
    assertThrown!ASN1Exception(el.integer!long);
    assertThrown!ASN1Exception(el.bitString);
    assertThrown!ASN1Exception(el.objectIdentifier);
    assertThrown!ASN1Exception(el.enumerated!byte);
    assertThrown!ASN1Exception(el.enumerated!short);
    assertThrown!ASN1Exception(el.enumerated!int);
    assertThrown!ASN1Exception(el.enumerated!long);
    assertThrown!ASN1Exception(el.generalizedTime);
    assertThrown!ASN1Exception(el.utcTime);
}