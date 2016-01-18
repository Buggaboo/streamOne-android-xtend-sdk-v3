package nl.streamone.sdk

import android.net.Uri
import static android.text.TextUtils.*

import java.net.URL
import java.util.Date
import java.net.HttpURLConnection
import java.io.OutputStreamWriter
import java.io.InputStreamReader
import java.io.BufferedReader

import org.eclipse.xtend.lib.annotations.Accessors

import java.util.Map
import java.util.List

import nl.streamone.sdk.RequestBase


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
    protected String command

    @Accessors
    protected String action

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

        for (p : parameters.entrySet)
        {
            builder.appendQueryParameter(p.key, p.value)
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