package nl.streamone.sdk

import android.util.Log
import android.net.Uri
import static android.text.TextUtils.*

import java.io.UnsupportedEncodingException
import java.security.InvalidKeyException
import java.security.NoSuchAlgorithmException

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

import java.net.URL
import java.util.Date
import java.net.HttpURLConnection
import java.io.OutputStreamWriter
import java.io.InputStreamReader
import java.io.BufferedReader

import java.util.Map
import java.util.List

import org.eclipse.xtend.lib.annotations.Accessors

import nl.streamone.sdk.RequestBase

abstract class Response
{
    @Accessors
    protected int code

    @Accessors
    protected String json

    // TODO deterimine that volley also supports this
    @Accessors
    protected Map<String, List<String>> headers

    def void onSuccess(RequestBase request)
    def void onError(RequestBase request, Exception e)
}

abstract class RequestBase
{
    @Accessors
    String command

    @Accessors
    String action

    /**
        For application authentication we only require the psk here.
        For session authentication we need (psk + post-application-authentication-key)
     */
    @Accessors
    String signingKey

    /**
        Path data
     */
    @Accessors
    protected val Map<String, String> parameters = newLinkedHashMap(
        'api' -> '3',
        'format' -> 'json'
    )

    @Accessors
    protected String scheme = 'https'

    @Accessors
    protected String method = 'POST'

    @Accessors
    protected boolean useCaches = false

    /**
    Do it like PHP
     */
    static def String getHmacSha1(byte[] key, byte[] message) throws
        UnsupportedEncodingException, NoSuchAlgorithmException,
        InvalidKeyException
    {
        val hmacSHA1Key = new SecretKeySpec(key, "HmacSHA1")
        val mac = Mac.getInstance("HmacSHA1")
        mac.init(hmacSHA1Key)

        val bytes = mac.doFinal(message)

        val StringBuffer hash = new StringBuffer
        for (var i = 0; i < bytes.length; i++) {
            val hex = Integer.toHexString(0xFF.bitwiseAnd(bytes.get(i)))
            if (hex.length == 1) {
                hash.append('0')
            }
            hash.append(hex)
        }
        return hash.toString
    }


    /**
        POST data
     */
    @Accessors
    protected val Map<String, String> arguments = newLinkedHashMap()

    // TODO experiment!
    protected val CONNECT_TIMEOUT = 10000
    protected val READ_TIMEOUT    = 10000

    @Accessors
    protected boolean closeConnectionAfterUse = false

    public def void execute(Response response)
}

class HttpUrlConnectionRequest extends RequestBase
{
    val TAG = "HttpUrlConnectionRequest"

    @Accessors
    String hostname

    @Accessors
    String port

    new () {
        super()
    }

    new (String hostname) {
        this()
        this.hostname = hostname
    }

    new (String hostname, int port)
    {
        this(hostname)
        this.port =  Integer.toString(port)
    }

    public override execute(Response response)
    {
        if (signingKey == null)
        {
            throw new IllegalArgumentException("You must provide a signing key.")
        }

        val builder = Uri.parse(concat(scheme, '://', hostname , ':', port) as String).buildUpon
        builder.appendPath('api')
        .appendPath(command)
        .appendPath(action)

        // default timestamp
        builder.appendQueryParameter('timestamp', Long.toString(new Date().time))

        for(p : parameters.entrySet)
        {
            builder.appendQueryParameter(p.key, p.value)
        }

        // TODO add builder methods to explicitly add the parameters
        // necessary for either application or user authentication
        // the PHP version has a very convoluted way of doing this
        val signaturePathAndQueryUrl = new URL(builder.build.toString)

        // TODO remove log
        Log.d(TAG, signaturePathAndQueryUrl.toString)

        val argBuilder = new StringBuilder
        if (!arguments.isEmpty)
        {
            for (arg : arguments.entrySet)
            {
                argBuilder.append('&').append(arg.key).append('=').append(arg.value)
            }
        }

        val args = argBuilder.toString.trim

        val signaturePathAndQuery = concat(signaturePathAndQueryUrl.path, '?', signaturePathAndQueryUrl.query, args).toString

        try {
            builder.appendQueryParameter("signature", getHmacSha1(signingKey.getBytes("UTF-8"), signaturePathAndQuery.getBytes("ASCII")))
        }catch(UnsupportedEncodingException e) {
            response.onError(this as RequestBase, e)
        }catch(NoSuchAlgorithmException e) {
            response.onError(this as RequestBase, e)
        }catch(InvalidKeyException e) {
            response.onError(this as RequestBase, e)
        }

        val url = new URL(builder.build.toString)

        // TODO remove log
        Log.d(TAG, url.toString)

        var HttpURLConnection connection = null
        try {
            connection = url.openConnection as HttpURLConnection
        } catch(java.io.IOException e) {
            response.onError(this as RequestBase, e)
        }

        try {
            connection.requestMethod = method
        } catch(java.net.ProtocolException e) {
            response.onError(this as RequestBase, e)
        }

        connection.doInput = true
        connection.useCaches = useCaches

        connection.connectTimeout = CONNECT_TIMEOUT
        connection.readTimeout = READ_TIMEOUT

        try {
            if ('POST'.equals(method) || 'PUT'.equals(method))
            {
                connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

                if (!arguments.isEmpty)
                {
                    val sbuilder = new StringBuilder
                    for (arg : arguments.entrySet)
                    {
                        sbuilder.append(arg.key).append('=').append(arg.value).append("\n")
                    }

                    val postData = sbuilder.toString.trim
                    connection.setRequestProperty("Content-Length", Integer.toString(postData.bytes.size))
                    connection.doOutput = true
                    val out = new OutputStreamWriter(connection.outputStream)
                    out.write(postData)
                    out.close
                }
            }

            val in = new BufferedReader(new InputStreamReader(connection.inputStream))
            val rBuilder = new StringBuffer
            var String decodedString
            while ((decodedString = in.readLine()) != null) {
                rBuilder.append(decodedString)
            }
            in.close()

            val responseBody = rBuilder.toString.trim

            if (!responseBody.isEmpty)
            {
                response.json = responseBody
            }

            response.headers = connection.headerFields

            val code = connection.responseCode
            response.code = code

            // is HTTP_OK the only valid response code? Is this the only _happy flow_?
            if (HttpURLConnection.HTTP_OK == code) {
                // handle success
                response.onSuccess(this as RequestBase)
            } else {
                // handle error code
                response.onError(this as RequestBase, null)
            }
        } catch(java.io.IOException e) {
            response.onError(this as RequestBase, e)
        }

        if (connection != null && closeConnectionAfterUse) {
            connection.disconnect()
        }
    }
}

/*
// TODO
class VolleyRequest extends RequestBase
{
    override execute()
    {

    }
}
*/