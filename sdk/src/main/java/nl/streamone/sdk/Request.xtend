package nl.streamone.sdk

import java.net.URL
import android.net.Uri
import java.util.Date
import java.net.HttpURLConnection
import java.io.OutputStreamWriter
import java.io.InputStreamReader
import java.io.BufferedReader

import org.eclipse.xtend.lib.annotations.Accessors

import java.util.Map
import java.util.List

import nl.streamone.sdk.RequestBase

/**
 * The base class for Request, abstracting authentication details
 *
 * This abstract class provides the basics for doing requests to the StreamOne API, and abstracts
 * the authentication details. This allows for subclasses that just implement a valid
 * authentication scheme, without having to re-implement all the basics of doing requests. For
 * normal use, the Request class provides authentication using users or applications, and
 * SessionRequest provides authentication for requests executed within a session.
 */

abstract class ResponseBase
{
    @Accessors
    protected int code

    @Accessors
    protected String body

    // TODO deterimine that volley also supports this
    @Accessors
    protected Map<String, List<String>> headers

    def void success(RequestBase request)
    def void error(RequestBase request)

    def void badConnection(RequestBase request, Exception e)
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


    def void execute(ResponseBase response)
}

class HttpUrlConnectionRequest extends RequestBase
{
    override execute(ResponseBase response)
    {
        /**
        1. http://api.nicky.test/api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572
        POST /api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572 HTTP/1.0
        Host: api.nicky.test
        Content-Length: 31
        Content-Type: application/x-www-form-urlencoded

        application=APPLICATION&limit=3

        2. http://api.nicky.test/api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9
        POST /api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9 HTTP/1.0
        Host: api.nicky.test
        Content-Length: 26
        Content-Type: application/x-www-form-urlencoded

        user=user&userip=127.0.0.2

        3. http://api.nicky.test/api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e
        POST /api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e HTTP/1.0
        Host: api.nicky.test
        Content-Length: 132
        Content-Type: application/x-www-form-urlencoded

        challenge=coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6&response=HQtJEAcGEwAASEJTUx0GRQYKRAACUQ8YD0BdXlVZVC90TBwgdhBlLm9RA1R5N0AFW25wUVMNHHpeY1QD

        4. http://api.nicky.test/api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506
        POST /api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506 HTTP/1.0
        Host: api.nicky.test
        Content-Type: application/x-www-form-urlencoded

         */

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

        /*
        Uri.Builder builder = new Uri.Builder();
        builder.scheme("https")
        .authority("api.openweathermap.org")
        .appendPath("data")
        .appendQueryParameter("q", params[0])
        */

        val url = new URL(builder.build.toString)
        var HttpURLConnection connection = null
        try {
            connection = url.openConnection as HttpURLConnection
        } catch(java.io.IOException e) {
            response.badConnection(this as RequestBase, e)
        }

        try {
            connection.requestMethod = method
        } catch(java.net.ProtocolException e) {
            response.badConnection(this as RequestBase, e)
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

            response.headers = connection.headerFields

            val code = connection.responseCode
            response.code = code

            if (HttpURLConnection.HTTP_OK == code) {
                // handle success
                response.success(this as RequestBase)
            } else {
                // handle error code
                response.error(this as RequestBase)
            }
        } catch(java.io.IOException e) {
            response.badConnection(this as RequestBase, e)
        }

        if (connection != null) {
            connection.disconnect();
        }

        /*
        URL aURL = new URL("http://example.com:80/docs/books/tutorial"
                + "/index.html?name=networking#DOWNLOADING");

        System.out.println("protocol = " + aURL.getProtocol());
        System.out.println("authority = " + aURL.getAuthority());
        System.out.println("host = " + aURL.getHost());
        System.out.println("port = " + aURL.getPort());
        System.out.println("path = " + aURL.getPath());
        System.out.println("query = " + aURL.getQuery());
        System.out.println("filename = " + aURL.getFile());
        System.out.println("ref = " + aURL.getRef());

        URL myURL = new URL(serviceURL);
        HttpURLConnection myURLConnection = (HttpURLConnection)myURL.openConnection();
        String userCredentials = "username:password";
        String basicAuth = "Basic " + new String(new Base64().encode(userCredentials.getBytes()));
        myURLConnection.setRequestProperty ("Authorization", basicAuth);
        myURLConnection.setRequestMethod("POST");
        myURLConnection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        myURLConnection.setRequestProperty("Content-Length", "" + Integer.toString(postData.getBytes().length));
        myURLConnection.setRequestProperty("Content-Language", "en-US");
        myURLConnection.setUseCaches(false);
        myURLConnection.setDoInput(true);
        myURLConnection.setDoOutput(true);
        */
    }
}

/*
class VolleyRequest extends RequestBase
{
    override execute()
    {

    }
}
*/