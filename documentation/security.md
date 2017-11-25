# ASN.1 D Library Security Review

## Security Review by A Security Firm

## Fuzz Testing

## CVE Review

Below are my reviews of all ASN.1-related CVEs, and how they might relate to 
my ASN.1 Library. If they are relevant, I detail what actions I will take or
have taken.

_Note: "Ethereal" referenced in the early 2000s CVEs below refers to the old name for WireShark._

### CVE-2017-11496

I can't find any information on this one.

### CVE-2017-9023

> The ASN.1 parser in strongSwan before 5.5.3 improperly handles `CHOICE` types when the x509 plugin is enabled, which allows remote attackers to cause a denial of service (infinite loop) via a crafted certificate.

From [StrongSwan's own website](https://strongswan.org/blog/2017/05/30/strongswan-vulnerability-(cve-2017-9023).html):

> Several extensions in X.509 certificates use `CHOICE` types to allow exactly one of several possible sub-elements. An extension that's defined like this, which strongSwan always supported, is `CRLDistributionPoints`, where the optional `distributionPoint` is defined as follows:

```asn1
DistributionPointName ::= CHOICE {
    fullName                [0]     GeneralNames,
    nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }
```

> So it may either be a `GeneralName` or an `RelativeDistinguishedName` but not both and one of them must be present if there is a `distributionPoint`. So far the x509 plugin and ASN.1 parser treated the choices simply as optional elements inside of a loop, without enforcing that exactly one of them was parsed (or that any of them were matched). This lead to the issue that if none of the options were found the parser was stuck in an infinite loop. Other extensions that are affected are `ipAddrBlocks` (supported since 4.3.6) and `CertificatePolicies` (since 4.5.1).

This concrete issue does not affect this library, but the implementations for `External`, `EmbeddedPDV`, and `CharacterString` need to be reviewed and tested for this vulnerability.

### CVE-2016-7053

Note: CMS = [Cryptographic Message Syntax](https://tools.ietf.org/html/rfc5652)

> In OpenSSL 1.1.0 before 1.1.0c, applications parsing invalid CMS structures can crash with a NULL pointer dereference. This is caused by a bug in the handling of the ASN.1 `CHOICE` type in OpenSSL 1.1.0 which can result in a `NULL` value being passed to the structure callback if an attempt is made to free certain invalid encodings. Only `CHOICE` structures using a callback which do not handle NULL value are affected.

I need to review [OpenSSL's Test for this vulnerability](https://github.com/openssl/openssl/blob/6a69e8694af23dae1d1927813932f4296d133416/test/recipes/25-test_d2i.t) as well as [OpenSSL version 1.1.0](https://github.com/openssl/openssl/blob/OpenSSL_1_1_0-stable/apps/cms.c).

### CVE-2016-6129

Review [this GitHub commit](https://github.com/libtom/libtomcrypt/commit/5eb9743410ce4657e9d54fef26a2ee31a1b5dd0).

Review the [Bleichenbacher's CCA Attack](https://crypto.stackexchange.com/questions/12688/can-you-explain-bleichenbachers-cca-attack-on-pkcs1-v1-5#12706).

### CVE-2016-9939

> Crypto++ (aka cryptopp and libcrypto++) 5.6.4 contained a bug in its ASN.1 BER decoding routine. The library will allocate a memory block based on the length field of the ASN.1 object. If there is not enough content octets in the ASN.1 object, then the function will fail and the memory block will be zeroed even if its unused. There is a noticeable delay during the wipe for a large allocation.

Does not apply, because the memory allocation is handled by the runtime.

### CVE-2016-6891

MatrixSSL before 3.8.6 allows remote attackers to cause a denial of service (out-of-bounds read) via a crafted ASN.1 Bit Field primitive in an X.509 certificate.

Review the changes in [MatrixSSL 3.8.6](https://github.com/matrixssl/matrixssl/blob/3-8-6-open/CHANGES.md).

### CVE-2016-5080

> Integer overflow in the rtxMemHeapAlloc function in asn1rt_a.lib in Objective Systems ASN1C for C/C++ before 7.0.2 allows context-dependent attackers to execute arbitrary code or cause a denial of service (heap-based buffer overflow), on a system running an application compiled by ASN1C, via crafted ASN.1 data.

There is a LOT of details out there on this one. I need to review this.

### CVE-2016-0758

> Integer overflow in `lib/asn1_decoder.c` in the Linux kernel before 4.6 allows local users to gain privileges via crafted ASN.1 data.

I need to review this [Linux Diff](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=23c8a812dc3c621009e4f0e5342aa4e2ede1ceaa).

### CVE-2015-5726

> The BER decoder in Botan 0.10.x before 1.10.10 and 1.11.x before 1.11.19 allows remote attackers to cause a denial of service (application crash) via an empty `BIT STRING` in ASN.1 data.

From the [Botan Security Advisory](https://botan.randombit.net/security.html):

> The BER decoder would crash due to reading from offset 0 of an empty vector if it encountered a `BIT STRING` which did not contain any data at all. This can be used to easily crash applications reading untrusted ASN.1 data, but does not seem exploitable for code execution.

### CVE-2016-2176

> The `X509_NAME_oneline` function in `crypto/x509/x509_obj.c` in OpenSSL before 1.0.1t and 1.0.2 before 1.0.2h allows remote attackers to obtain sensitive information from process stack memory or cause a denial of service (buffer over-read) via crafted EBCDIC ASN.1 data.

Review the [Git commit that fixed it](https://git.openssl.org/?p=openssl.git;a=commit;h=2919516136a4227d9e6d8f2fe66ef976aaf8c561).

### CVE-2016-2109

> The `asn1_d2i_read_bio` function in `crypto/asn1/a_d2i_fp.c` in the ASN.1 `BIO` implementation in OpenSSL before 1.0.1t and 1.0.2 before 1.0.2h allows remote attackers to cause a denial of service (memory consumption) via a short invalid encoding.

Review the [Git commit that fixed it](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=c62981390d6cf9e3d612c489b8b77c2913b25807;hp=ddc606c914e72e770dbe8293a65585b7c3017bba).

### CVE-2016-2108

> The ASN.1 implementation in OpenSSL before 1.0.1o and 1.0.2 before 1.0.2c allows remote attackers to execute arbitrary code or cause a denial of service (buffer underflow and memory corruption) via an `ANY` field in crafted serialized data, aka the "negative zero" issue.

Review the [Git commit that fixed it](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=3661bb4e7934668bd99ca777ea8b30eedfafa871;hp=e697a4c3d7d2267e9d82d88dbfa5084475794cb3).

### CVE-2016-2053

> The `asn1_ber_decoder` function in `lib/asn1_decoder.c` in the Linux kernel before 4.3 allows attackers to cause a denial of service (panic) via an ASN.1 BER file that lacks a public key, leading to mishandling by the `public_key_verify_signature` function in `crypto/asymmetric_keys/public_key.c`.

Review the [Git commit that fixed it](https://github.com/torvalds/linux/commit/0d62e9dd6da45bbf0f33a8617afc5fe774c8f45f).

### CVE-2016-4421

> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.12.x before 1.12.10 and 2.x before 2.0.2 allows remote attackers to cause a denial of service (deep recursion, stack consumption, and application crash) via a packet that specifies deeply nested data.

Review the [issues page](https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=11822).

### CVE-2016-4418

> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.12.x before 1.12.10 and 2.x before 2.0.2 allows remote attackers to cause a denial of service (buffer over-read and application crash) via a crafted packet that triggers an empty set.

Review the [issues page](https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=12106).

### CVE-2016-1950

> Heap-based buffer overflow in Mozilla Network Security Services (NSS) before 3.19.2.3 and 3.20.x and 3.21.x before 3.21.1, as used in Mozilla Firefox before 45.0 and Firefox ESR 38.x before 38.7, allows remote attackers to execute arbitrary code via crafted ASN.1 data in an X.509 certificate.

Go through this [nasty bug page](https://bugzilla.mozilla.org/show_bug.cgi?id=1245528).

### CVE-2016-2842

> The `doapr_outch` function in `crypto/bio/b_print.c` in OpenSSL 1.0.1 before 1.0.1s and 1.0.2 before 1.0.2g does not verify that a certain memory allocation succeeds, which allows remote attackers to cause a denial of service (out-of-bounds write or memory consumption) or possibly have unspecified other impact via a long string, as demonstrated by a large amount of ASN.1 data, a different vulnerability than CVE-2016-0799.

Review this [beast of a diff](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=578b956fe741bf8e84055547b1e83c28dd902c73;hp=259b664f950c2ba66fbf4b0fe5281327904ead21).

### CVE-2016-0799

> The `fmtstr` function in `crypto/bio/b_print.c` in OpenSSL 1.0.1 before 1.0.1s and 1.0.2 before 1.0.2g improperly calculates string lengths, which allows remote attackers to cause a denial of service (overflow and out-of-bounds read) or possibly have unspecified other impact via a long string, as demonstrated by a large amount of ASN.1 data, a different vulnerability than CVE-2016-2842.

Review this [diff](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=578b956fe741bf8e84055547b1e83c28dd902c73;hp=259b664f950c2ba66fbf4b0fe5281327904ead21).

### CVE-2016-2522

> The `dissect_ber_constrained_bitstring` function in `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 2.0.x before 2.0.2 does not verify that a certain length is nonzero, which allows remote attackers to cause a denial of service (out-of-bounds read and application crash) via a crafted packet.

Review this [diff](https://code.wireshark.org/review/gitweb?p=wireshark.git;a=blobdiff;f=epan/dissectors/packet-ber.c;h=319353f4187a2139dad594798f8b5b67ce6c2fde;hp=c049a5184010396a26058151fc504cf1160903a0;hb=9b2f3f7c5c9205381cb72e42b66e97d8ed3abf63;hpb=5d4a71a1a22aedc0a3ab9e81a627cf37e7d58e7f).

### CVE-2015-7540

> The LDAP server in the AD domain controller in Samba 4.x before 4.1.22 does not check return values to ensure successful ASN.1 memory allocation, which allows remote attackers to cause a denial of service (memory consumption and daemon crash) via crafted packets.

Review this [diff](https://git.samba.org/?p=samba.git;a=commit;h=530d50a1abdcdf4d1775652d4c456c1274d83d8d) and this [diff](https://git.samba.org/?p=samba.git;a=commit;h=9d989c9dd7a5b92d0c5d65287935471b83b6e884).

### CVE-2015-7061

> The ASN.1 decoder in Apple OS X before 10.11.2, tvOS before 9.1, and watchOS before 2.1 allows remote attackers to execute arbitrary code or cause a denial of service (memory corruption) via a crafted certificate, a different vulnerability than CVE-2015-7059 and CVE-2015-7060.

This one cannot really be reviewed, since Apple's code is closed-source.

### CVE-2015-7060

Ditto

### CVE-2015-7059

Ditto

### CVE-2015-3194

> `crypto/rsa/rsa_ameth.c` in OpenSSL 1.0.1 before 1.0.1q and 1.0.2 before 1.0.2e allows remote attackers to cause a denial of service (`NULL` pointer dereference and application crash) via an RSA PSS ASN.1 signature that lacks a mask generation function parameter.

Review this [git commit](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=c394a488942387246653833359a5c94b5832674e;hp=d73cc256c8e256c32ed959456101b73ba9842f72).

Though this library has nothing to do with RSA key exchange, problems with null
pointers could still happen. A review of the context-switching types should be
sufficient.

### CVE-2015-7182

> Heap-based buffer overflow in the ASN.1 decoder in Mozilla Network Security Services (NSS) before 3.19.2.1 and 3.20.x before 3.20.1, as used in Firefox before 42.0 and Firefox ESR 38.x before 38.4 and other products, allows remote attackers to cause a denial of service (application crash) or possibly execute arbitrary code via crafted OCTET STRING data.

Review this [bug page](https://bugzilla.mozilla.org/show_bug.cgi?id=1202868).

This one definitely needs to be reviewed.

### CVE-2015-1790

> The `PKCS7_dataDecodefunction` in `crypto/pkcs7/pk7_doit.c` in OpenSSL before 0.9.8zg, 1.0.0 before 1.0.0s, 1.0.1 before 1.0.1n, and 1.0.2 before 1.0.2b allows remote attackers to cause a denial of service (NULL pointer dereference and application crash) via a PKCS#7 blob that uses ASN.1 encoding and lacks inner `EncryptedContent` data.

Review this [GitHub diff](https://github.com/openssl/openssl/commit/59302b600e8d5b77ef144e447bb046fd7ab72686).

### CVE-2015-0289

> The PKCS#7 implementation in OpenSSL before 0.9.8zf, 1.0.0 before 1.0.0r, 1.0.1 before 1.0.1m, and 1.0.2 before 1.0.2a does not properly handle a lack of outer `ContentInfo`, which allows attackers to cause a denial of service (NULL pointer dereference and application crash) by leveraging an application that processes arbitrary PKCS#7 data and providing malformed data with ASN.1 encoding, related to `crypto/pkcs7/pk7_doit.c` and `crypto/pkcs7/pk7_lib.c`.

Review this [diff](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=c0334c2c92dd1bc3ad8138ba6e74006c3631b0f9;hp=c3c7fb07dc975dc3c9de0eddb7d8fd79fc9c67c1).

### CVE-2015-0287

> The `ASN1_item_ex_d2i` function in `crypto/asn1/tasn_dec.c` in OpenSSL before 0.9.8zf, 1.0.0 before 1.0.0r, 1.0.1 before 1.0.1m, and 1.0.2 before 1.0.2a does not reinitialize `CHOICE` and `ADB` data structures, which might allow attackers to cause a denial of service (invalid write operation and memory corruption) by leveraging an application that relies on ASN.1 structure reuse.

Review this [diff](https://git.openssl.org/?p=openssl.git;a=blobdiff;f=crypto/asn1/tasn_dec.c;h=7fd336a402268b3e32bea77d331bf66b2f061f2a;hp=4595664409c9b91118e0ac0dee35ddfc670edfe3;hb=b717b083073b6cacc0a5e2397b661678aff7ae7f;hpb=819418110b6fff4a7b96f01a5d68f71df3e3b736).

### CVE-2015-0208

> The ASN.1 signature-verification implementation in the rsa_item_verify function in crypto/rsa/rsa_ameth.c in OpenSSL 1.0.2 before 1.0.2a allows remote attackers to cause a denial of service (NULL pointer dereference and application crash) via crafted RSA PSS parameters to an endpoint that uses the certificate-verification feature.

[diff](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=4b22cce3812052fe64fc3f6d58d8cc884e3cb834;hp=b717b083073b6cacc0a5e2397b661678aff7ae7f).

Once again, just reviewing the context-switching types should be sufficient.

### CVE-2015-1182

> The `asn1_get_sequence_of` function in `library/asn1parse.c` in PolarSSL 1.0 through 1.2.12 and 1.3.x through 1.3.9 does not properly initialize a pointer in the `asn1_sequence` linked list, which allows remote attackers to cause a denial of service (crash) or possibly execute arbitrary code via a crafted ASN.1 sequence in a certificate.

Review.

### CVE-2014-1569

> The `definite_length_decoder` function in `lib/util/quickder.c` in Mozilla Network Security Services (NSS) before 3.16.2.4 and 3.17.x before 3.17.3 does not ensure that the DER encoding of an ASN.1 length is properly formed, which allows remote attackers to conduct data-smuggling attacks by using a long byte sequence for an encoding, as demonstrated by the `SEC_QuickDERDecodeItem` function's improper handling of an arbitrary-length encoding of `0x00`.

Review this [bug page](https://bugzilla.mozilla.org/show_bug.cgi?id=1064670).

`integer` and `enum` already check for this, but it might not hurt to look into
additional measures to ensure that DER does not encode invalid-length data.

### CVE-2014-4443

> Apple OS X before 10.10 allows remote attackers to cause a denial of service (NULL pointer dereference) via crafted ASN.1 data.

Not really able to be reviewed, because Apple is closed-source.

### CVE-2014-1568

> Mozilla Network Security Services (NSS) before 3.16.2.1, 3.16.x before 3.16.5, and 3.17.x before 3.17.1, as used in Mozilla Firefox before 32.0.3, Mozilla Firefox ESR 24.x before 24.8.1 and 31.x before 31.1.1, Mozilla Thunderbird before 24.8.1 and 31.x before 31.1.2, Mozilla SeaMonkey before 2.29.1, Google Chrome before 37.0.2062.124 on Windows and OS X, and Google Chrome OS before 37.0.2062.120, does not properly parse ASN.1 values in X.509 certificates, which makes it easier for remote attackers to spoof RSA signatures via a crafted certificate, aka a "signature malleability" issue.

[This bugzilla](https://bugzilla.mozilla.org/show_bug.cgi?id=1064636)
[That bugzilla](https://bugzilla.mozilla.org/show_bug.cgi?id=1069405)

### CVE-2014-5165

> The `dissect_ber_constrained_bitstring` function in `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.10.x before 1.10.9 does not properly validate padding values, which allows remote attackers to cause a denial of service (buffer underflow and application crash) via a crafted packet.

```diff
while (nb->p_id) {
-   if ((len > 0) && (nb->bit < (8*len-pad))) {
+   if ((len > 0) && (pad < 8*len) && (nb->bit < (8*len-pad))) {
        val = tvb_get_guint8(tvb, offset + nb->bit/8);
        bitstring[(nb->bit/8)] &= ~(0x80 >> (nb->bit%8));
        val &= 0x80 >> (nb->bit%8);
```

If I understand 
[this bug](https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=17a552666b50896a9b9dde8ee6a1052e7f9a622e;hp=c30df319547442b3847693c821844735fd692d9c) 
correctly, the padding could be larger than the actual
number of bits in the `BIT STRING`. A maliciously-crafted packet would contain
a `BIT STRING` with a number of bits less than 255, and a padding value greater
than that, possibly even greater than 7, since the application does not stop
processing the encoded data upon encountering a padding value > 7; it looks
like it just leaves behind some sort of log message. Then, in this line:

```c
if ((len > 0) && (nb->bit < (8*len-pad))) {
```

the value `8*len-pad` underflows to `UINT_MAX`, which makes WireShark read off
anything that comes after the `BIT STRING` in memory as the encoded bytes of
the `BIT STRING`.

Although, the CVE description specifically mentions a "buffer underflow," which
I am not seeing. I see an integer underflow.

Either way, I need to add unit tests to `BIT STRING` to make sure it does not
crash or read out of bounds if padding > 7 && bits < 7.

### CVE-2014-3468

> The `asn1_get_bit_der` function in GNU Libtasn1 before 3.6 does not properly report an error when a negative bit length is identified, which allows context-dependent attackers to cause out-of-bounds access via crafted ASN.1 data.

With this bug, all I need to do is make sure that length is always an 
*unsigned* integral type, and make sure it cannot somehow underflow.

### CVE-2014-3467

> Multiple unspecified vulnerabilities in the DER decoder in GNU Libtasn1 before 3.6, as used in GnuTLS, allow remote attackers to cause a denial of service (out-of-bounds read) via crafted ASN.1 data.

I could barely find any information on this one.

### CVE-2014-1316

> Heimdal, as used in Apple OS X through 10.9.2, allows remote attackers to cause a denial of service (abort and daemon exit) via ASN.1 data encountered in the Kerberos 5 protocol.

They are talking about [this Heimdal](http://www.h5l.org/). I cannot find any information about this vulnerability.

### CVE-2013-5018

> The `is_asn1` function in strongSwan 4.1.11 through 5.0.4 does not properly validate the return value of the `asn1_length` function, which allows remote attackers to cause a denial of service (segmentation fault) via a (1) XAuth username, (2) EAP identity, or (3) PEM encoded file that starts with a `0x04`, `0x30`, or `0x31` character followed by an ASN.1 length value that triggers an integer overflow.

The segmentation fault is thrown on line 657 of `src/libstrongswan/asn1/asn1.c` 
of version 5.0.5 (and obviously, the analogous line in earlier versions):

```c
if (len + 1 == blob.len && *(blob.ptr + len) == '\n')
```

If the encoded ASN.1 value is of type `SET` or `SEQUENCE`, or in some versions,
`OCTET STRING`, it can make it to this line, which is why the CVE says it must 
start with `0x04`, `0x30` or `0x31` (the `OCTET STRING`, `SET` and `SEQUENCE` 
type tags, respectively). When it makes it to the line above, if the encoded 
data encodes a length of `0xFFFFFFFF`, and if the `blob` mentioned above is
empty, then the first condition may pass, because `UINT_MAX` overflows to `0`.

On the second condition, `blob.ptr + len` will sum to the address of the byte
in memory immediately before `blob` on 32-bit builds, and will just be about
4.2 gigabytes of memory higher (or lower, depending on how you look at it) in 
memory on 64-bit builds. If the resulting memory address lies in a page not
owned by the process, a segmentation fault occurs.

This means I need to make sure that length is not added to or subtracted from
in any part of the validation code, or make sure that the necessary checks are
in place if it does.

### CVE-2013-4935

> The `dissect_per_length_determinant` function in `epan/dissectors/packet-per.c` in the ASN.1 PER dissector in Wireshark 1.8.x before 1.8.9 and 1.10.x before 1.10.1 does not initialize a length field in certain abnormal situations, which allows remote attackers to cause a denial of service (application crash) via a crafted packet.

In line 638, which reads:

```c
buf = (guint8 *)g_malloc(length+1);
```

if length is set to `0xFFFFFFFF`, then `g_malloc` will allocate 0 bytes to the
buffer, then try to access the subsequent bytes in memory which it does not
own, resulting in a segmentation fault.

You should be fine searching for any time that a value is added to or 
subtracted from and ensuring that overflows cannot happen.

### CVE-2013-3557

> The `dissect_ber_choice` function in `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.6.x before 1.6.15 and 1.8.x before 1.8.7 does not properly initialize a certain variable, which allows remote attackers to cause a denial of service (application crash) via a malformed packet.

There is almost no information on this one.

### CVE-2013-3556

> The `fragment_add_seq_common` function in `epan/reassemble.c` in the ASN.1 BER dissector in Wireshark before r48943 has an incorrect pointer dereference during a comparison, which allows remote attackers to cause a denial of service (application crash) via a malformed packet.

This bug is just caused by this little typo:

```diff
-                       if (*orig_keyp != NULL)
+                       if (orig_keyp != NULL)
```

### CVE-2012-0441

> The ASN.1 decoder in the QuickDER decoder in Mozilla Network Security Services (NSS) before 3.13.4, as used in Firefox 4.x through 12.0, Firefox ESR 10.x before 10.0.5, Thunderbird 5.0 through 12.0, Thunderbird ESR 10.x before 10.0.5, and SeaMonkey before 2.10, allows remote attackers to cause a denial of service (application crash) via a zero-length item, as demonstrated by (1) a zero-length basic constraint or (2) a zero-length field in an OCSP response.

From the [Bugzilla page](https://bugzilla.mozilla.org/show_bug.cgi?id=715073):

> From my reading of X.690, of the 25 ASN.1 UNIVERSAL types currently recognized/defined in `secasn1t.h`, the following 7 can never have zero length (when properly DER encoded): `BOOLEAN`, `INTEGER`, `BIT STRING`, `OBJECT_IDENTIFIER`, `ENUMERATED`, `UTCTime`, `GeneralizedTime`. QuickDER should abort further processing when the template specifies one of these types and the buffer being processed holds such an illegal encoding.

- [ ] Review how DER specifies that an `INTEGER` and `ENUMERATED` of zero should be encoded.
- [ ] Implement `invariant`s that ensure that all of the above types are never zero-length.

### CVE-2012-1569

> The `asn1_get_length_der` function in `decoding.c` in GNU Libtasn1 before 2.12, as used in GnuTLS before 3.0.16 and other products, does not properly handle certain large length values, which allows remote attackers to cause a denial of service (heap memory corruption and application crash) or possibly have unspecified other impact via a crafted ASN.1 structure.

Apparently, according to 
[this page](http://article.gmane.org/gmane.comp.gnu.libtasn1.general/54),
this was not actually a vulnerability, but rather, a lot of developers using
this library were not doing validation on the return value of 
`asn_get_length_der` that they were expected to do.

This bug is irrelevant to my code.

### CVE-2011-1142

> Stack consumption vulnerability in the `dissect_ber_choice` function in the BER dissector in Wireshark 1.2.x through 1.2.15 and 1.4.x through 1.4.4 might allow remote attackers to cause a denial of service (infinite loop) via vectors involving self-referential ASN.1 CHOICE values.

I tried looking at the source code, and its just too damn complicated for me to figure out what causes the security vulnerability. I believe it has to do with this section (cleaned up slightly for readability):

```c
ch = choice;

if (branch_taken) {
    *branch_taken = -1;
}

first_pass = TRUE;
while (ch->func || first_pass) {
    if(branch_taken) {
        (*branch_taken)++;
    }
    /* we reset for a second pass when we will look for choices */
    if (!ch->func) {
    first_pass = FALSE;
    ch = choice; /* reset to the beginning */
    if(branch_taken) {
        *branch_taken = -1;
    }
}
```

Obviously, that section of code is not really that complicated, but learning 
all the data types and structures involved is. 

However, I can say that I believe that this bug is irrelevant to my code, 
because my code does not parse `CHOICE` types. It is on the developer to 
loop over the type tag of the "chosen" element and determine how to 
correctly decode it. It might behoove me, however, to leave a note for
developers using this library to be wary of this issue.

### CVE-2011-0445

> The ASN.1 BER dissector in Wireshark 1.4.0 through 1.4.2 allows remote attackers to cause a denial of service (assertion failure) via crafted packets, as demonstrated by fuzz-2010-12-30-28473.pcap.

This bug occurs on the same exact line that CVE-2014-5165 occurs on, in 
`epan/dissectors/packet-ber.c`.

```diff
-                       if(nb->bit < (8*len-pad)) {
+                       if(len > 0 && nb->bit < (8*len-pad)) {
```

Here they just didn't check that the length is actually greater than zero.

- [ ] Review code for possible invalid zero lengths.

### CVE-2010-3445

> Stack consumption vulnerability in the `dissect_ber_unknown` function in `epan/dissectors/packet-ber.c` in the BER dissector in Wireshark 1.4.x before 1.4.1 and 1.2.x before 1.2.12 allows remote attackers to cause a denial of service (`NULL` pointer dereference and crash) via a long string in an unknown ASN.1/BER encoded packet, as demonstrated using SNMP.

[Here](https://xorl.wordpress.com/2010/10/15/cve-2010-3445-wireshark-asn-1-ber-stack-overflow/)
is a pretty good explanation of this vulnerability. Basically, there are no
recursion checks on nested BER-encoded elements, so you can send a message with 
a huge number of nested constructed elements, and with each constructed type 
tag encountered, it will recurse. Causing a stack overflow, then, is a simple 
matter of sending a repeating sequence of constructed type tags, each of 
which is followed by a length tag, of course.

Again, this is irrelevant to my code. My code decodes only a single "layer"
of recursion at a time. It is possible for a developer using this library
to make this mistake, however, so it is important that I leave a heads up
for developers.

### CVE-2010-2994

> Stack-based buffer overflow in the ASN.1 BER dissector in Wireshark 0.10.13 through 1.0.14 and 1.2.0 through 1.2.9 has unknown impact and remote attack vectors. NOTE: this issue exists because of a CVE-2010-2284 regression.

Jeez, is WireShark the only product that has ever had any vulnerabilities?

As stated above "this issue exists because of a CVE-2010-2284 regression." Moving on.

### CVE-2010-2284

> Buffer overflow in the ASN.1 BER dissector in Wireshark 0.10.13 through 1.0.13 and 1.2.0 through 1.2.8 has unknown impact and remote attack vectors.

I cannot find a bug or commit confirmed to be associated with this CVE, but I 
found 
[this commmit](https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=edb7f000dc5b342c311977c327be1bac0767ff06)
that appears to fix possible infinite recursion.

Again, with the other infinite recursion / stack overflow bugs mentioned above,
this one does not really relate to my code, because my code does not recurse.

However, it is possible to encode indefinite-length encoded elements in other 
indefinite-length elements, which would *require* recursion to determine the
length, so I definitely need to review my code for this possibility.

- [ ] Make sure IL elements can contain other IL elements.

### CVE-2009-3877

> Unspecified vulnerability in Sun Java SE in JDK and JRE 5.0 before Update 22, JDK and JRE 6 before Update 17, SDK and JRE 1.3.x before 1.3.1\_27, and SDK and JRE 1.4.x before 1.4.2\_24 allows remote attackers to cause a denial of service (memory consumption) via crafted HTTP headers, which are not properly parsed by the ASN.1 DER input stream parser, aka Bug Id 6864911.

[This bug](http://bugs.java.com/bugdatabase/view_bug.do?bug_id=6864911) is no longer available.

Skipping, because I think this is closed source anyway.

### CVE-2009-3876

Ditto.

### CVE-2009-2511

Closed source. Unable to research.

### CVE-2009-2661

> The `asn1_length` function in strongSwan 2.8 before 2.8.11, 4.2 before 4.2.17, and 4.3 before 4.3.3 does not properly handle X.509 certificates with crafted Relative Distinguished Names (RDNs), which allows remote attackers to cause a denial of service (pluto IKE daemon crash) via malformed ASN.1 data. NOTE: this is due to an incomplete fix for CVE-2009-2185.

Noted "this is due to an incomplete fix for CVE-2009-2185." Moving on.

### CVE-2009-2185

> The ASN.1 parser (`pluto/asn1.c`, `libstrongswan/asn1/asn1.c`, `libstrongswan/asn1/asn1_parser.c`) in (a) strongSwan 2.8 before 2.8.10, 4.2 before 4.2.16, and 4.3 before 4.3.2; and (b) openSwan 2.6 before 2.6.22 and 2.4 before 2.4.15 allows remote attackers to cause a denial of service (pluto IKE daemon crash) via an X.509 certificate with (1) crafted Relative Distinguished Names (RDNs), (2) a crafted `UTCTIME` string, or (3) a crafted `GENERALIZEDTIME` string.

There is a lot that went into this vulnerability. Basically, the developers 
just failed to do the most basic length checks.

### CVE-2009-0847

> The `asn1buf_imbed` function in the ASN.1 decoder in MIT Kerberos 5 (aka krb5) 1.6.3, when PK-INIT is used, allows remote attackers to cause a denial of service (application crash) via a crafted length value that triggers an erroneous `malloc` call, related to incorrect calculations with pointer arithmetic.

It looks like version 1.6.3 was removed altogether, so I cannot research this
one; but, I suspect this is just like CVE-2013-4935.

### CVE-2009-0846

> The `asn1_decode_generaltime` function in `lib/krb5/asn.1/asn1_decode.c` in the ASN.1 `GeneralizedTime` decoder in MIT Kerberos 5 (aka krb5) before 1.6.4 allows remote attackers to cause a denial of service (daemon crash) or possibly execute arbitrary code via vectors involving an invalid DER encoding that triggers a free of an uninitialized pointer.

This bug was only caused by nothing being done with the return value of
`asn1buf_remove_charstring`. So when the program encountered a problem
decoding the ASN.1 element, the code would continue even though the
output buffer, `s`, was never actually initialized. The second line
below was added in version 1.6.4, which fixed this bug.

```c
retval = asn1buf_remove_charstring(buf,15,&s);
if (retval) return retval;
```

I don't think there is actually a lesson to learn here at all. This was just 
dumb. The end.

### CVE-2009-0789

> OpenSSL before 0.9.8k on WIN64 and certain other platforms does not properly handle a malformed ASN.1 structure, which allows remote attackers to cause a denial of service (invalid memory access and application crash) by placing this structure in the public key of a certificate, as demonstrated by an RSA public key.

From [this advisory](https://www.openssl.org/news/secadv/20090325.txt):

> When a malformed ASN1 structure is received it's contents are freed up and zeroed and an error condition returned. On a small number of platforms where sizeof(long) < sizeof(void *) (for example WIN64) this can cause an invalid memory access later resulting in a crash when some invalid structures are read, for example RSA public keys (CVE-2009-0789).

Short term fix: `static assert` blocking code from compiling when `long.sizeof < (void *).sizeof`.
Long term fix: actually fix the code.

Although, I really don't think this bug should affect my code at all. I don't 
I cast between pointers and `long`s in my code.

### CVE-2008-2952

> `liblber/io.c` in OpenLDAP 2.2.4 to 2.4.10 allows remote attackers to cause a denial of service (program termination) via crafted ASN.1 BER datagrams that trigger an assertion error.

This shit is exactly what Uncle Bob was griping about:

```diff
 			/* Not enough bytes? */
-			if (ber->ber_rwptr - (char *)p < llen) {
-#if defined( EWOULDBLOCK )
-				sock_errset(EWOULDBLOCK);
-#elif defined( EAGAIN )
-				sock_errset(EAGAIN);
-#endif			
-				return LBER_DEFAULT;
+			i = ber->ber_rwptr - (char *)p;
+			if (i < llen) {
+				sblen=ber_int_sb_read( sb, ber->ber_rwptr, i );
+				if (sblen<i) return LBER_DEFAULT;
+				ber->ber_rwptr += sblen;
 			}
 			for (i=0; i<llen; i++) {
 				tlen <<=8;
```

I'm not reviewing this. Sorry.

### CVE-2008-1673

> The asn1 implementation in (a) the Linux kernel 2.4 before 2.4.36.6 and 2.6 before 2.6.25.5, as used in the `cifs` and `ip_nat_snmp_basic` modules; and (b) the `gxsnmp` package; does not properly validate length values during decoding of ASN.1 BER data, which allows remote attackers to cause a denial of service (crash) or execute arbitrary code via (1) a length greater than the working buffer, which can lead to an unspecified overflow; (2) an oid length of zero, which can lead to an off-by-one error; or (3) an indefinite length for a primitive encoding.

This appears to be the result of a few checks that were not done.

```diff
+	/* don't trust len bigger than ctx buffer */
+	if (*len > ctx->end - ctx->pointer)
+		return 0;
```

This makes sure that the reported length is not longer than the length of all
encoded data.

```diff
+	/* primitive shall be definite, indefinite shall be constructed */
+	if (*con == ASN1_PRI && !def)
+		return 0;
```

The comment says all.

```diff
    size = eoc - ctx->pointer + 1;

+	/* first subid actually encodes first two subids */
+	if (size < 2 || size > ULONG_MAX/sizeof(unsigned long))
+		return 0;
```

If the element is less than two bytes in length, it cannot be a valid ASN.1
element. I don't know why is must be no larger than 
`ULONG/sizeof(unsigned long)`.

The other checks added to the diff for that commit are duplicates of the
checks above.

- [ ] Check that length tag indicates length less than data length.
- [ ] Set PC to constructed if indefinite encoding is used. (Check that this is actually a rule, too.)
- [ ] Check that encoded value is at least two bytes long (one for type, one for length).

### CVE-2006-3894

> The RSA Crypto-C before 6.3.1 and Cert-C before 2.8 libraries, as used by RSA BSAFE, multiple Cisco products, and other products, allows remote attackers to cause a denial of service via malformed ASN.1 objects.

Closed source. Skipping.

### CVE-2006-6836

> Multiple unspecified vulnerabilities in osp-cert in IBM OS/400 V5R3M0 have unspecified impact and attack vectors, related to ASN.1 parsing.

Closed source. Skipping.

### CVE-2006-2937

> OpenSSL 0.9.7 before 0.9.7l and 0.9.8 before 0.9.8d allows remote attackers to cause a denial of service (infinite loop and memory consumption) via malformed ASN.1 structures that trigger an improperly handled error condition.

I really cannot figure out what causes the infinite loop here. I've looked at 
the patch, and, though there are a few changes to control flow (replacement of
`goto err` with `return -1`, for instance), I can't see anything that would 
cause an infinite loop in the first place. I might have to get an expert on
OpenSSL to weigh in here.

The patch is [here](http://security.FreeBSD.org/patches/SA-06:23/openssl.patch),
but also saved in `documentation/miscellaneous/CVE-2006-2937.patch`, just in 
case that link breaks.

### CVE-2006-1939

> Multiple unspecified vulnerabilities in Ethereal 0.9.x up to 0.10.14 allow remote attackers to cause a denial of service (crash from null dereference) via (1) an invalid display filter, or the (2) GSM SMS, (3) ASN.1-based, (4) DCERPC NT, (5) PER, (6) RPC, (7) DCERPC, and (8) ASN.1 dissectors.

Welp, "unspecified vulnerabilities" is my excuse for not looking into this.

### CVE-2006-0645

> Tiny ASN.1 Library (libtasn1) before 0.2.18, as used by (1) GnuTLS 1.2.x before 1.2.10 and 1.3.x before 1.3.4, and (2) GNU Shishi, allows attackers to crash the DER decoder and possibly execute arbitrary code via "out-of-bounds access" caused by invalid input, as demonstrated by the ProtoVer SSL test suite.

The patch for this one is huge, and I don't see which part of it deals with 
the invalid input. I got the patch from 
[here](https://bugzilla.redhat.com/attachment.cgi?id=124516), but I also saved
it in `documentation/miscellaneous/CVE-2006-0645.patch` in case that link 
breaks.

### CVE-2005-1730

> Multiple vulnerabilities in the OpenSSL ASN.1 parser, as used in Novell iManager 2.0.2, allows remote attackers to cause a denial of service (`NULL` pointer dereference) via crafted packets, as demonstrated by "OpenSSL ASN.1 brute forcer." NOTE: this issue might overlap CVE-2004-0079, CVE-2004-0081, or CVE-2004-0112.

I managed to download the [exploit malware source](http://downloads.securityfocus.com/vulnerabilities/exploits/ASN.1-Brute.c), 
which is saved in `documentation/miscellaneous/exploit-CVE-2005-1730.c`.
The author says you can use it [here](http://www.derkeiler.com/Mailing-Lists/securityfocus/bugtraq/2004-01/0126.html).

I will have to analyze it to discover the exploit (and possibly run it on my
system).

### CVE-2005-1935

> Heap-based buffer overflow in the BERDecBitString function in Microsoft ASN.1 library (MSASN1.DLL) allows remote attackers to execute arbitrary code via nested constructed bit strings, which leads to a realloc of a non-null pointer and causes the function to overwrite previously freed memory, as demonstrated using a SPNEGO token with a constructed bit string during HTTP authentication, and a different vulnerability than CVE-2003-0818. NOTE: the researcher has claimed that MS:MS04-007 fixes this issue.

Closed source. Skipping.

### CVE-2004-2344

> Unknown vulnerability in the ASN.1/H.323/H.225 stack of VocalTec VGW120 and VGW480 allows remote attackers to cause a denial of service.

Closed source, ancient, and "Unknown vulnerability." Skipping.

### CVE-2004-2644

> Unspecified vulnerability in ASN.1 Compiler (`asn1c`) before 0.9.7 has unknown impact and attack vectors when processing "ANY" type tags.

This library does not compile ASN.1, so this is irrelevant, but I will keep it
in mind if that ever changes.

### CVE-2004-2645

> Unspecified vulnerability in ASN.1 Compiler (`asn1c`) before 0.9.7 has unknown impact and attack vectors when processing "CHOICE" types with "indefinite length structures."

Ditto.

### CVE-2004-0642

> Double free vulnerabilities in the error handling code for ASN.1 decoders in the (1) Key Distribution Center (KDC) library and (2) client library for MIT Kerberos 5 (krb5) 1.3.4 and earlier may allow remote attackers to execute arbitrary code.

### CVE-2004-0644

> The asn1buf_skiptail function in the ASN.1 decoder library for MIT Kerberos 5 (krb5) 1.2.2 through 1.3.4 allows remote attackers to cause a denial of service (infinite loop) via a certain BER encoding.

### CVE-2004-0699

> Heap-based buffer overflow in ASN.1 decoding library in Check Point VPN-1 products, when Aggressive Mode IKE is implemented, allows remote attackers to execute arbitrary code by initiating an IKE negotiation and then sending an IKE packet with malformed ASN.1 data.

### CVE-2004-0123

> Double free vulnerability in the ASN.1 library as used in Windows NT 4.0, Windows 2000, Windows XP, and Windows Server 2003, allows remote attackers to cause a denial of service and possibly execute arbitrary code.

Closed source. Skipping.

### CVE-2003-0818

> Multiple integer overflows in Microsoft ASN.1 library (MSASN1.DLL), as used in LSASS.EXE, CRYPT32.DLL, and other Microsoft executables and libraries on Windows NT 4.0, 2000, and XP, allow remote attackers to execute arbitrary code via ASN.1 BER encodings with (1) very large length fields that cause arbitrary heap data to be overwritten, or (2) modified bit strings.

Closed source. Skipping.

### CVE-2005-1247

> `webadmin.exe` in Novell Nsure Audit 1.0.1 allows remote attackers to cause a denial of service via malformed ASN.1 packets in corrupt client certificates to an SSL server, as demonstrated using an exploit for the OpenSSL ASN.1 parsing vulnerability.

Closed source. Skipping.

### CVE-2003-1005

> The PKI functionality in Mac OS X 10.2.8 and 10.3.2 allows remote attackers to cause a denial of service (service crash) via malformed ASN.1 sequences.

Closed source. Skipping.

### CVE-2003-0564

> Multiple vulnerabilities in multiple vendor implementations of the Secure/Multipurpose Internet Mail Extensions (S/MIME) protocol allow remote attackers to cause a denial of service and possibly execute arbitrary code via an S/MIME email message containing certain unexpected ASN.1 constructs, as demonstrated using the NISSC test suite.

### CVE-2003-0565

> Multiple vulnerabilities in multiple vendor implementations of the X.400 protocol allow remote attackers to cause a denial of service and possibly execute arbitrary code via an X.400 message containing certain unexpected ASN.1 constructs, as demonstrated using the NISSC test suite.

### CVE-2003-0851

> OpenSSL 0.9.6k allows remote attackers to cause a denial of service (crash via large recursion) via malformed ASN.1 sequences.

### CVE-2003-0543

> Integer overflow in OpenSSL 0.9.6 and 0.9.7 allows remote attackers to cause a denial of service (crash) via an SSL client certificate with certain ASN.1 tag values.

### CVE-2003-0544

> OpenSSL 0.9.6 and 0.9.7 does not properly track the number of characters in certain ASN.1 inputs, which allows remote attackers to cause a denial of service (crash) via an SSL client certificate that causes OpenSSL to read past the end of a buffer when the long form is used.

### CVE-2003-0545

> Double free vulnerability in OpenSSL 0.9.7 allows remote attackers to cause a denial of service (crash) and possibly execute arbitrary code via an SSL client certificate with a certain invalid ASN.1 encoding.

### CVE-2003-0430

> The SPNEGO dissector in Ethereal 0.9.12 and earlier allows remote attackers to cause a denial of service (crash) via an invalid ASN.1 value.

### CVE-2002-0036

> Integer signedness error in MIT Kerberos V5 ASN.1 decoder before krb5 1.2.5 allows remote attackers to cause a denial of service via a large unsigned data element length, which is later used as a negative value.

### CVE-2002-0353

> The ASN.1 parser in Ethereal 0.9.2 and earlier allows remote attackers to cause a denial of service (crash) via a certain malformed packet, which causes Ethereal to allocate memory incorrectly, possibly due to zero-length fields.