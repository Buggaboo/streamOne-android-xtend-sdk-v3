package nl.streamone.sdk

import java.util.Map
import org.junit.Test
import java.util.regex.Pattern
import static org.junit.Assert.assertFalse
import static org.junit.Assert.assertTrue
import static org.junit.Assert.fail
import nl.streamone.sdk.Cryptography
import nl.streamone.sdk.Authentication
import nl.streamone.sdk.ApplicationAuthentication
import nl.streamone.sdk.PreSessionAuthentication
import nl.streamone.sdk.Session
import org.json.JSONObject

import android.support.test.runner.AndroidJUnit4
import org.junit.runner.RunWith

/** 
 * <a href="http://d.android.com/tools/testing/testing_android.html">Testing Fundamentals</a>
 * TODO test timeouts (max. 15m)
 */
@RunWith(AndroidJUnit4)
class HttpUrlConnectionRequestTest {

    final static String hostName = "localhost:6969"
    final static String user = "user"
    final static String psk = "AAAAABBBBBCCCCCDDDDD000000111111222222"
    final static String actorId = "user"
    final static String password = "password"

    // TODO add this to the Requests
    static Authentication auth
    // (hostName, AuthTypeEnum.toAuthTypeEnumValue("application"), user, psk);
    static ApplicationAuthentication appAuth
    static PreSessionAuthentication preSessionAuth
    static Session session

    @Test def void openApplicationSession() {
        /** 
         * 1. http://api.nicky.test/api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572
         * POST /api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572 HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 31
         * Content-Type: application/x-www-form-urlencoded
         * application=APPLICATION&limit=3
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest(hostName)
        // TODO chain this mofo
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
                /**
             * {
             * "header": {
             * "status": 0,
             * "statusmessage": "OK",
             * "apiversion": 3,
             * "cacheable": true,
             * "count": 1,
             * "timezone": "Europe\/Amsterdam"
             * },
             * "body": [{
             * "id": "APPLICATION",
             * "name": "Application Title",
             * "description": "Application Description",
             * "datecreated": "2015-09-28 09:00:02",
             * "datemodified": "2015-09-28 09:00:02",
             * "active": true,
             * "iplock": null,
             * "timezone": "Europe\/Amsterdam"
             * }]
             * }
             */
            }

            override void onError(RequestBase request) {
                fail()
            }

            override void onLostConnection(RequestBase request, Exception e) {
                fail()
            }
        })
    }

    /** 
     * The difference between this one and the one above is the
     */
    @Test def void initializeUserSession() {
        /** 
         * 2. http://api.nicky.test/api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9
         * POST /api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9 HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 26
         * Content-Type: application/x-www-form-urlencoded
         * user=user&userip=127.0.0.2
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest(hostName)
        // TODO chain this mofo
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
                /**
             * {
             * "header": {
             * "status": 0,
             * "statusmessage": "OK",
             * "apiversion": 3,
             * "cacheable": false,
             * "timezone": "Europe\/Amsterdam"
             * },
             * "body": {
             * "challenge": "coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6",
             * "salt": "$2y$12$baztaaydu13s4ah6y6pegt",
             * "needsv2hash": false
             * }
             * }
             */
            }

            override void onError(RequestBase request) {
                fail()
            }

            override void onLostConnection(RequestBase request, Exception e) {
                fail()
            }
        })
    }

    /** 
     * How to get the response:
     * public static function generatePasswordResponse($password, $salt, $challenge)
     * {
     * $password_hash = crypt(md5($password), $salt);
     * $sha_password_hash = hash('sha256', $password_hash);
     * $password_hash_with_challenge = hash('sha256', $sha_password_hash . $challenge);
     * return base64_encode($password_hash_with_challenge ^ $password_hash);
     * }
     * $password_hash --> "The new password hash for this user, should be calculated as sha56(blowfish(md5(password), salt)), where password is the new password of the user"
     */
    @Test def void createUserSession() {
        /** 
         * 3. http://api.nicky.test/api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e
         * POST /api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e HTTP/1.0
         * Host: api.nicky.test
         * Content-Length: 132
         * Content-Type: application/x-www-form-urlencoded
         * challenge=coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6&response=HQtJEAcGEwAASEJTUx0GRQYKRAACUQ8YD0BdXlVZVC90TBwgdhBlLm9RA1R5N0AFW25wUVMNHHpeY1QD
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest(hostName)
        // TODO chain this mofo
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
                /**
             * {
             * "header": {
             * "status": 0,
             * "statusmessage": "OK",
             * "apiversion": 3,
             * "cacheable": false,
             * "timezone": "Europe\/Amsterdam"
             * },
             * "body": {
             * "id": "sC5tGogRgBow",
             * "key": "gR92jURda7mEqiDzhcz2bC1FtIzS8wxe",
             * "timeout": 3600,
             * "user": "USER"
             * }
             * }
             */
            }

            override void onError(RequestBase request) {
                fail()
            }

            override void onLostConnection(RequestBase request, Exception e) {
                fail()
            }
        })
    }

    @Test def void viewUser() {
        /** 
         * 4. http://api.nicky.test/api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506
         * POST /api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506 HTTP/1.0
         * Host: api.nicky.test
         * Content-Type: application/x-www-form-urlencoded
         */
        var HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest(hostName)
        // TODO chain this mofo
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
             * "timezone": "Europe\/Amsterdam"
             * },
             * "body": {
             * "id": "USER",
             * "username": "user",
             * "active": true,
             * "datecreated": "2015-09-28 09:05:57",
             * "datemodified": "2016-01-15 09:24:41",
             * "email": "user@streamone.test",
             * "sessionsenabled": true,
             * "timezone": "Europe\/Amsterdam",
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

            override void onError(RequestBase request) {
                fail()
            }

            override void onLostConnection(RequestBase request, Exception e) {
                fail()
            }
        })
    } // TODO unit test Customer session (i.e. replace 'user' with 'customer'
}
