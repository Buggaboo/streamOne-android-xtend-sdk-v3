package nl.streamone.sdk

import java.util.Map
import org.junit.Test
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.runner.RunWith
import static org.junit.Assert.*

import nl.streamone.sdk.Cryptography
import nl.streamone.sdk.Authentication
import nl.streamone.sdk.ApplicationAuthentication
import nl.streamone.sdk.PreSessionAuthentication
import nl.streamone.sdk.Session
import org.json.JSONObject

import android.support.test.runner.AndroidJUnit4
import android.util.Log

import com.squareup.okhttp.mockwebserver.MockWebServer
import com.squareup.okhttp.mockwebserver.Dispatcher
import com.squareup.okhttp.mockwebserver.MockResponse
import com.squareup.okhttp.mockwebserver.RecordedRequest
import android.test.suitebuilder.annotation.MediumTest

/**
 * <a href="http://d.android.com/tools/testing/testing_android.html">Testing Fundamentals</a>
 * TODO test timeouts (max. 15m)
 */
@RunWith(AndroidJUnit4)
@MediumTest
class HttpUrlConnectionRequestTest {
    static val TAG = "HttpUrlConnectionRequestTest"

    @Rule public var MockWebServer mServer = new MockWebServer

    final static String hostName = 'localhost'
    final static int    port     = 6969

    final static String user = "user"
    final static String psk = "AAAAABBBBBCCCCCDDDDD000000111111222222"
    final static String actorId = "user"
    final static String password = "password"

    static val applicationViewJsonRaw =   "{\"header\":{\"status\":0,\"statusmessage\":\"OK\",\"apiversion\":3,\"cacheable\":true,\"count\":1,\"timezone\":\"Europe/Amsterdam\"},\"body\":[{\"id\":\"APPLICATION\",\"name\":\"Application Title\",\"description\":\"Application Description\",\"datecreated\":\"2015-09-28 09:00:02\",\"datemodified\":\"2015-09-28 09:00:02\",\"active\":true,\"iplock\":null,\"timezone\":\"Europe/Amsterdam\"}]}"
    static val sessionInitializeJsonRaw = "{\"header\":{\"status\":0,\"statusmessage\":\"OK\",\"apiversion\":3,\"cacheable\":false,\"timezone\":\"Europe/Amsterdam\"},\"body\":{\"challenge\":\"coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6\",\"salt\":\"$2y$12$baztaaydu13s4ah6y6pegt\",\"needsv2hash\":false}}"
    static val sessionCreateJsonRaw =     "{\"header\":{\"status\":0,\"statusmessage\":\"OK\",\"apiversion\":3,\"cacheable\":false,\"timezone\":\"Europe/Amsterdam\"},\"body\":{\"id\":\"sC5tGogRgBow\",\"key\":\"gR92jURda7mEqiDzhcz2bC1FtIzS8wxe\",\"timeout\":3600,\"user\":\"USER\"}}"

    // TODO add this to the Requests
    Authentication auth
    // (hostName, AuthTypeEnum.toAuthTypeEnumValue("application"), user, psk)
    ApplicationAuthentication appAuth = new ApplicationAuthentication(new JSONObject(applicationViewJsonRaw).getJSONArray("body").get(0) as JSONObject)
    PreSessionAuthentication preSessionAuth = new PreSessionAuthentication(new JSONObject(sessionInitializeJsonRaw).getJSONObject("body"))
    Session session = new Session(new JSONObject(sessionCreateJsonRaw).getJSONObject("body"))

    // run exactly once
    @Before
    public def void initializeMockWebServer() {
        mServer.dispatcher = [ RecordedRequest request |
            val path = request.path

            if (path.contains("api/application/view")){
                return new MockResponse().setResponseCode(200).body = applicationViewJsonRaw
            }
            if (path.contains("api/session/initialize")){
                return new MockResponse().setResponseCode(200).body = sessionInitializeJsonRaw
            }
            if (path.contains("api/session/create")){
                return new MockResponse().setResponseCode(200).body = sessionCreateJsonRaw

            }
            // once we have the session id and the key, we can make arbitrary calls,
            // this arbitrary tests should be wrapped in @Test
            return new MockResponse().responseCode = 404
        ]

        mServer.useHttps(null, false)

        try {
            mServer.start(port)
        } catch(IllegalStateException e) {
            // walk on... nothing to see here
        }
    }

/*
    // I think I got it right, TODO
    @Test
    def HmacSha1_same_as_php()
    {
        val byte[] key     = "aaaa".bytes
        val byte[] message = "bbbb".bytes
        assertEquals(RequestBase.getHmacSha1(key, message), "something")
    }
*/
    @Test
    public def void openApplicationSession() {

        /**
         * 1. http://api.nicky.test/api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572
         * POST /api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572 HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 31
         * Content-Type: application/x-www-form-urlencoded
         * application=APPLICATION&limit=3
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest('localhost', port)
        // TODO chain this mofo
        connReq.scheme = 'http'
        connReq.setCommand("application")
        connReq.setAction("view")
        connReq.setSigningKey(psk)
        // TODO chain this mofo
        var Map<String, String> params = connReq.parameters
        params.put("authentication_type", "application")
        params.put("application", "APPLICATION")
        // TODO chain this mofo
        var Map<String, String> args = connReq.arguments
        args.put("application", "APPLICATION")
        args.put("limit", "3")
        connReq.execute(new Response() {
            override void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", json), true)
                appAuth = new ApplicationAuthentication(new JSONObject(json).getJSONObject("body"))
            }

            override void onError(RequestBase request, Exception e) {
                fail(e?.message)
            }
        })
    }

    /**
     * The difference between this one and the one above is the
     */
    @Test
    public def void initializeUserSession() {
        /**
         * 2. http://api.nicky.test/api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9
         * POST /api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9 HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 26
         * Content-Type: application/x-www-form-urlencoded
         * user=user&userip=127.0.0.2
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest('localhost', port)
        // TODO chain this mofo
        connReq.scheme = 'http'
        connReq.setCommand("session")
        connReq.setAction("initialize")
        connReq.setSigningKey(psk)
        // TODO chain this mofo
        var Map<String, String> params = connReq.parameters
        params.put("authentication_type", "application")
        params.put("application", "APPLICATION")
        // TODO chain this mofo
        var Map<String, String> args = connReq.arguments
        args.put("user", "user")
        args.put("userip", "127.0.0.2")
        connReq.execute(new Response() {
            override void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", json), true)
                preSessionAuth = new PreSessionAuthentication(new JSONObject(json).getJSONObject("body"))
            }

            override void onError(RequestBase request, Exception e) {
                fail(e?.message)
            }
        })
    }

    /**
     * How to get the response:
     * public static function generatePasswordResponse($password, $salt, $challenge)
     * {
     * $password_hash = crypt(md5($password), $salt)
     * $sha_password_hash = hash('sha256', $password_hash)
     * $password_hash_with_challenge = hash('sha256', $sha_password_hash . $challenge)
     * return base64_encode($password_hash_with_challenge ^ $password_hash)
     * }
     * $password_hash --> "The new password hash for this user, should be calculated as sha56(blowfish(md5(password), salt)), where password is the new password of the user"
     */
    @Test
    public def void createUserSession() {
        /**
         * 3. http://api.nicky.test/api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e
         * POST /api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 132
         * Content-Type: application/x-www-form-urlencoded
         * challenge=coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6&response=HQtJEAcGEwAASEJTUx0GRQYKRAACUQ8YD0BdXlVZVC90TBwgdhBlLm9RA1R5N0AFW25wUVMNHHpeY1QD
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest('localhost', port)
        // TODO chain this mofo
        connReq.scheme = 'http'
        connReq.setCommand("session")
        connReq.setAction("create")
        connReq.setSigningKey(psk)
        // TODO chain this mofo
        var Map<String, String> params = connReq.parameters
        params.put("authentication_type", "application")
        params.put("application", "APPLICATION")
        // TODO chain this mofo
        var Map<String, String> args = connReq.arguments
        // get these things from the JSON in getJson
        args.put("challenge", preSessionAuth.challenge)
        args.put("response",
        Cryptography.getChallengeResponse(password.bytes, preSessionAuth.challenge.bytes, preSessionAuth.salt.bytes))
        connReq.execute(new Response() {
            override void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", json), true)
                session = new Session(new JSONObject(json).getJSONObject("body"))
            }

            override void onError(RequestBase request, Exception e) {
                fail(e?.message)
            }
        })
    }

    @Test
    public def void viewUser() {
        /**
         * 4. http://api.nicky.test/api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506
         * POST /api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506 HTTP/1.0
         * Host: api.nicky.test
         * Content-Type: application/x-www-form-urlencoded
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest('localhost', port)
        // TODO chain this mofo
        connReq.scheme = 'http'
        connReq.setCommand("user")
        connReq.setAction("viewme")
        connReq.setSigningKey(psk + session.key)
        // TODO chain this mofo
        var Map<String, String> params = connReq.parameters
        params.put("authentication_type", "application")
        params.put("application", "APPLICATION")
        params.put("session", session.id)
        connReq.execute(new Response() {
            override void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", json), true)
                /**
             * {
             * "header": {
             * "status": 0,
             * "statusmessage": "OK",
             * "apiversion": 3,
             * "cacheable": true,
             * "sessiontimeout": 3600,
             * "timezone": "Europe/Amsterdam"
             * },
             * "body": {
             * "id": "USER",
             * "username": "user",
             * "active": true,
             * "datecreated": "2015-09-28 09:05:57",
             * "datemodified": "2016-01-15 09:24:41",
             * "email": "user@streamone.test",
             * "sessionsenabled": true,
             * "timezone": "Europe/Amsterdam",
             * "mobilephone": "",
             * "address": "",
             * "zipcode": "",
             * "city": "",
             * "firstname": "",
             * "lastname": ""
             * }
             * }
             */
            }

            override void onError(RequestBase request, Exception e) {
                fail(e?.message)
            }
        })
    } // TODO unit test Customer session (i.e. replace 'user' with 'customer'
/*
    @After
    def void shutdownMockWebServer() {
        mServer?.shutdown
    }
*/

}
