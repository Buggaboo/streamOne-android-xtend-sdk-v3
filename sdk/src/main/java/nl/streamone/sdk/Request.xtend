package nl.streamone.sdk

import android.net.Uri
import static android.text.TextUtils.*

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import java.net.URL
import java.util.Date
import java.net.HttpURLConnection
import java.io.OutputStreamWriter
import java.io.InputStreamReader
import java.io.BufferedReader

import org.eclipse.xtend.lib.annotations.Accessors

import java.util.Map
import java.util.List

import org.xtendroid.parcel.AndroidParcelable
import org.xtendroid.annotations.EnumProperty
import org.eclipse.xtend.lib.annotations.Accessors

import nl.streamone.sdk.RequestBase

@Accessors
@AndroidParcelable
class Authentication {
    String url

    @EnumProperty(name="AuthTypeEnum", values=#["user", "application"])
    String authenticationType

    String userId
    String userPsk
    String defaultAccountId

    new (String url, AuthTypeEnum authenticationType, String userId, String userPsk, String defaultAccountId) {
            this.url = url
            this.authenticationType = authenticationType.toString
            this.userId = userId
            this.userPsk = userPsk
            this.defaultAccountId = defaultAccountId
    }
}

abstract class Response
{
    @Accessors
    protected int code

    @Accessors
    protected String body

    // TODO deterimine that volley also supports this
    @Accessors
    protected Map<String, List<String>> headers

    def void onSuccess(RequestBase request)
    def void onError(RequestBase request)

    def void onLostConnection(RequestBase request, Exception e)
    // TODO support these
    /*
    def void connectionTimeout(RequestBase request, Exception e) // code == HTTP_CLIENT_TIMEOUT ?
    def void readTimeout(RequestBase request, Exception e) // ...
    */
}

abstract class RequestBase
{
    @Accessors
    String actorId

    @Accessors
    String psk

    @Accessors
    String command

    @Accessors
    String action

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
    protected String hostname

    @Accessors
    protected String method = 'POST'

    @Accessors
    protected boolean useCaches = false

    /**
    public String getSignature()
    {
     protected function signature()                                                                                 │fatal: Could not read from remote repository.
     {                                                                                                              │
     $parameters = $this->parametersForSigning();
     $path = $this->path();                                                                                 │and the repository exists.
     $arguments = $this->arguments();                                                                       │128 (M=2c5aa)
     │Counting objects: 19, done.
     // Calculate signature                                                                                 │Delta compression using up to 8 threads.
     $url = $path . '?' . http_build_query($parameters) . '&' . http_build_query($arguments);               │Compressing objects: 100% (11/11), done.
     $key = $this->signingKey();                                                                            │Writing objects: 100% (19/19), 3.67 KiB | 0 bytes/s, done.
     │Total 19 (delta 5), reused 0 (delta 0)
     return hash_hmac('sha1', $url, $key);                                                                  │To git@github.com:Buggaboo/streamOne-android-xtend-sdk-v3.git
     }

      protected function parametersForSigning()                                                                      │:100644 100644 eb88248... e5dc48b... M  sdk/src/main/java/nl/streamone/sdk/Request.xtend
        {                                                                                                              │
                $parameters = parent::parametersForSigning();                                                          │commit 2c5aaf55d2ae949cc374bcd6e40b4dae802e9d01

                // Set actor ID parameter                                                                              │Date:   Mon Jan 18 15:50:14 2016 +0100
                $actor_id = $this->config->getAuthenticationActorId();                                                 │
                switch ($this->config->getAuthenticationType())                                                        │    Added unit test for user session creation
                {                                                                                                      │
                        case Config::AUTH_USER:                                                                        │:100644 100644 45aaeda... dd28b6f... M  .gitignore
                                $parameters['user'] = $actor_id;                                                       │:100644 100644 7966aa7... 7c79303... M  sdk/build.gradle
                                break;                                                                                 │:100644 100644 2444970... 7a4ec76... M  sdk/src/androidTest/java/nl/streamone/sdk/ApplicationTest.java
                                                                                                                       │:000000 100644 0000000... b5ce4af... A  sdk/src/main/java/nl/streamone/sdk/Platform.xtend
                        case Config::AUTH_APPLICATION:                                                                 │:100644 100644 3e17c04... eb88248... M  sdk/src/main/java/nl/streamone/sdk/Request.xtend
                                $parameters['application'] = $actor_id;                                                │
                                break;                                                                                 │commit c099c2b9e6038a4a8e8fa83d0fd37ac97940477e
                }
                                                                                                                       │Date:   Fri Jan 15 16:25:40 2016 +0100
                return $parameters;                                                                                    │
        }
     */


    /*
    private String hmac(String psk, String input) throws
    UnsupportedEncodingException, NoSuchAlgorithmException,
    InvalidKeyException {

        SecretKeySpec key = new SecretKeySpec((psk).getBytes("UTF-8"), "HmacSHA1");
        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(key);

        byte[] bytes = mac.doFinal(input.getBytes("UTF-8"));

        StringBuffer buffer = new StringBuffer();
        for(int index = 0; index < bytes.length; index++) {
            buffer.append(Integer.toHexString(bytes[index]));
        }

        return buffer.toString();
    }
    */


    def String getHmacSha1(String input) throws
        UnsupportedEncodingException, NoSuchAlgorithmException,
        InvalidKeyException
    {
        val key = new SecretKeySpec((psk).getBytes("UTF-8"), "HmacSHA1");
        val mac = Mac.getInstance("HmacSHA1");
        mac.init(key);

        val bytes = mac.doFinal(input.getBytes("UTF-8"));

        // convert to hex (just like php expects)
        val buffer = new StringBuffer
        for(var index = 0; index < bytes.length; index++) {
            buffer.append(Integer.toHexString(bytes.get(index)));
        }

        return buffer.toString
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
    new () { super() }

    public override execute(Response response)
    {
        val builder = new Uri.Builder()
        builder.scheme(scheme)
        .authority(hostname)
        .appendPath('api')
        .appendPath(command)
        .appendPath(action)

        // default timestamp
        builder.appendQueryParameter('timestamp', Long.toString(new Date().time))

        for(p : parameters.entrySet)
        {
            builder.appendQueryParameter(p.key, p.value)
        }

        // TODO do something about the actorId
        val signaturePathAndQueryUrl = new URL(builder.build.toString)

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
            builder.appendQueryParameter("signature", signaturePathAndQuery.getHmacSha1)
        }catch(UnsupportedEncodingException e) {
            response.onLostConnection(this as RequestBase, e)
        }catch(NoSuchAlgorithmException e) {
            response.onLostConnection(this as RequestBase, e)
        }catch(InvalidKeyException e) {
            response.onLostConnection(this as RequestBase, e)
        }

        val url = new URL(builder.build.toString)
        var HttpURLConnection connection = null
        try {
            connection = url.openConnection as HttpURLConnection
        } catch(java.io.IOException e) {
            response.onLostConnection(this as RequestBase, e)
        }

        try {
            connection.requestMethod = method
        } catch(java.net.ProtocolException e) {
            response.onLostConnection(this as RequestBase, e)
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

            val in = new BufferedReader(new InputStreamReader(connection.inputStream));
            val rBuilder = new StringBuffer
            var String decodedString
            while ((decodedString = in.readLine()) != null) {
                rBuilder.append(decodedString)
            }
            in.close();

            val responseBody = rBuilder.toString.trim

            if (!responseBody.isEmpty)
            {
                response.body = responseBody
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
                response.onError(this as RequestBase)
            }
        } catch(java.io.IOException e) {
            response.onLostConnection(this as RequestBase, e)
        }

        if (connection != null && closeConnectionAfterUse) {
            connection.disconnect();
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