package nl.streamone.sdk

import java.util.Date
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import android.util.Base64

import org.xtendroid.parcel.AndroidParcelable
import org.xtendroid.json.AndroidJson
import org.xtendroid.annotations.EnumProperty
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Created by jasmsison on 15/01/16.
 */
@AndroidParcelable
@AndroidJson
class ResponseHeader
{
    /**
     "status": 0,
     "statusmessage": "OK",
     "apiversion": 3,
     "cacheable": true,
     "count": 1,
     "timezone": "Europe\/Amsterdam"
     */
    int status
    String statusmessage
    int apiversion
    boolean cacheable
    int count
    String timezone
}

@AndroidParcelable
class Authentication {
    String hostname

    @EnumProperty(name="AuthTypeEnum", values=#["user", "application"])
    String authenticationType

    String loginId
    String preSharedKey

    //String defaultAccountId // TODO determine wtf this is for
/*
    // TODO determine what the defaultUserId is for...
    new (String hostname, AuthTypeEnum authenticationType, String loginId, String preSharedKey) {
        this.hostname = hostname
        this.authenticationType = authenticationType.toString
        this.loginId = loginId
        this.preSharedKey = preSharedKey
        //this.defaultAccountId = defaultAccountId
    }
*/
}

@AndroidParcelable
@AndroidJson
class ApplicationAuthentication {
/**
     "body": [{
     "id": "APPLICATION",
     "name": "Application Title",
     "description": "Application Description",
     "datecreated": "2015-09-28 09:00:02",
     "datemodified": "2015-09-28 09:00:02",
     "active": true,
     "iplock": null,
     "timezone": "Europe\/Amsterdam"
     }]
 */
    @AndroidJson("header")
    ResponseHeader header

    String  id
    String  name
    String  description
    Date    datecreated
    Date    datemodified
    boolean active
    // boolean iplock
    String  timezone
}

@AndroidParcelable
@AndroidJson
class PreSessionAuthentication {

    @AndroidJson("header")
    ResponseHeader header

    /**
         "challenge": "coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6",
         "salt": "$2y$12$baztaaydu13s4ah6y6pegt",
         "needsv2hash": false
     */
    String challenge
    String salt
    boolean needsv2hash
}

@AndroidParcelable
@AndroidJson
class Session {
    /*
    "id": "sC5tGogRgBow",
    "key": "gR92jURda7mEqiDzhcz2bC1FtIzS8wxe",
    "timeout": 3600,
    "user": "USER"
    */
    /**
    Session token
     */
    String id
    /**
    psk + key <= signing
     */
    String key
    int timeout
    String user

    @AndroidJson("header")
    ResponseHeader header
}


class Cryptography
{
    /**
    intermediate := blowfish(md5(password), salt)
    challenge_hash := sha256(sha256(intermediate) + challenge)
    response := base64encode(challenge_hash (xor) intermediate)
     */
    public static def String getChallengeResponse(byte[] password, byte[] challenge, byte[] salt)
    {
        val intermediate = encryptWithBlowfish(password.md5, salt)

        // intermediate.sha256 + challenge.bytes
        val intermediateSha256 = intermediate.sha256
        val intermediateSha256Size = intermediateSha256.size
        val challengeSize = challenge.size
        val safeByteArrayMerge = newByteArrayOfSize(intermediateSha256.size + challengeSize)
        System.arraycopy(intermediateSha256, 0, safeByteArrayMerge, 0, intermediateSha256Size)
        System.arraycopy(challenge, 0, safeByteArrayMerge, intermediateSha256Size-1, challengeSize)

        val challengeHash = safeByteArrayMerge.sha256
        val challengeHashSize = challengeHash.size
        val intermediateSize = intermediate.size

        // (challengeHash ^ intermediate).base64Encoding

        /**
        // TODO find a sane way to do this in Xtend
        public static byte[] xor(byte[] data1, byte[] data2) {
            // make data2 the largest...
            if (data1.length > data2.length) {
                byte[] tmp = data2;
                data2 = data1;
                data1 = tmp;
            }
            for (int i = 0; i < data1.length; i++) {
                data2[i] ^= data1[i];
            }
            return data2;
        }
         */

        // juggle references
        var byte[] x = null
        var byte[] y = null
        if (challengeHashSize > intermediateSize) {
            x = challengeHash
            y = intermediate
        }else // ( ... <= ... )
        {
            x = intermediate
            y = challengeHash
        }

        for (var i = 0; i < y.length; i++) {
            // x[i] ^= y[i]; -> x[i] = x[i] ^ y[i], where the i, is from the smallest (i.e. i from y.size)
            //x.set(i, x.get(i).bitwiseXor(y.get(i))) // Xtend transpilation error, bitwiseXor only available to ints, wtf.
            // TODO report error... my bad: java is broken, e.g. byte ^ byte = int (wtf)

            val xint = x.get(i) as int
            val yint = y.get(i) as int

            //x.set(i, x.get(i).bitwiseXor(y.get(i)))
            x.set(i, xint.bitwiseXor(yint).bitwiseAnd(0xff) as byte)
            // will endianness fuck up this cast? bitwiseAnding with 0xff removes the signedness
        }

        // TODO nullify byte[], security

        return new String(x.base64Encoding)
    }

    /**
     * Shit, Xtend is VERBOOOOOOOSE when you go low level
     */
    static def String getBase64Encoding(byte[] b)
    {
        // Base64 is an android thing
        var flags = Base64.URL_SAFE.bitwiseOr(Base64.NO_PADDING).bitwiseOr(Base64.NO_WRAP)
        return Base64.encodeToString(b, flags)
    }

    static def byte[] getDigest(String digesterType, byte[] b)
    {
        val digester = MessageDigest.getInstance( digesterType )
        digester.reset
        digester.update(b)
        return digester.digest
    }

    static def byte[] getMd5(byte[] b)
    {
        "SHA-1".getDigest(b)
    }

    static def byte[] getSha256(byte[] b)
    {
        "SHA-256".getDigest(b)
    }

    static def byte[] encryptWithBlowfish(byte[] secretKey, byte[] message)
    {
        // create a cipher based upon Blowfish
        val cipher = Cipher.getInstance("Blowfish");

        // initialise cipher to with secret key
        val key = new SecretKeySpec(secretKey, "Blowfish")
        cipher.init(Cipher.ENCRYPT_MODE, key);

        // encrypt message
        return cipher.doFinal(message);
    }
}