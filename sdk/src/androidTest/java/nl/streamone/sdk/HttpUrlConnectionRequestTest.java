package nl.streamone.sdk;

import java.util.Map;

import org.junit.Test;
import java.util.regex.Pattern;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

/**
 * <a href="http://d.android.com/tools/testing/testing_android.html">Testing Fundamentals</a>
 */
public class HttpUrlConnectionRequestTest {

    public String getSignature()
    {
        /**
         protected function signature()                                                                                 │fatal: Could not read from remote repository.
         {                                                                                                              │
         $parameters = $this->parametersForSigning();                                                           │Please make sure you have the correct access rights
         $path = $this->path();                                                                                 │and the repository exists.
         $arguments = $this->arguments();                                                                       │128 (M=2c5aa) jasmsison@JASMS_MBP ~/Documents/git-repositories/streamOne-android-xtend-sdk-v3> git push
         │Counting objects: 19, done.
         // Calculate signature                                                                                 │Delta compression using up to 8 threads.
         $url = $path . '?' . http_build_query($parameters) . '&' . http_build_query($arguments);               │Compressing objects: 100% (11/11), done.
         $key = $this->signingKey();                                                                            │Writing objects: 100% (19/19), 3.67 KiB | 0 bytes/s, done.
         │Total 19 (delta 5), reused 0 (delta 0)
         return hash_hmac('sha1', $url, $key);                                                                  │To git@github.com:Buggaboo/streamOne-android-xtend-sdk-v3.git
         }
         */
    }


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

    final private static String hostName = "localhost:6969";
    final private static String user = "user";
    final private static String psk = "AAAAABBBBBCCCCCDDDDD000000111111222222";

    @Test
    public void openApplicationSession()
    {
        /**
         *
         1. http://api.nicky.test/api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572
         POST /api/application/view?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=fdcb6fa43769bc7729e4e6df1ed0cb99ffcd8572 HTTP/1.0
         Host: api.nicky.test
         Content-Length: 31
         Content-Type: application/x-www-form-urlencoded

         application=APPLICATION&limit=3
         */
        HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest();

        // TODO chain this mofo
        connReq.setPsk(psk);
        connReq.setHostname(hostName); // see src/javascript/streamone_mock_server.js
        connReq.setCommand("application");
        connReq.setAction("view");

        // TODO chain this mofo
        Map<String, String> params = connReq.getParameters();
        params.put("authentication_type", "application");
        params.put("application", "APPLICATION");

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("application", "APPLICATION");
        args.put("limit", "3");

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);

                /**
                 *
                 * {
                 "header": {
                 "status": 0,
                 "statusmessage": "OK",
                 "apiversion": 3,
                 "cacheable": true,
                 "count": 1,
                 "timezone": "Europe\/Amsterdam"
                 },
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
                 }
                 *
                 */
            }

            @Override
            public void onError(RequestBase request) {
                fail();
            }

            @Override
            public void onLostConnection(RequestBase request, Exception e) {
                fail();
            }
        });
    }

    /**
     *
     * The difference between this one and the one above is the
     *
     */
    @Test
    public void initializeUserSession()
    {
        /**
         2. http://api.nicky.test/api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9
         POST /api/session/initialize?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=4fefaf20807f55839425fe217507a30cc4d3dea9 HTTP/1.0
         Host: api.nicky.test
         Content-Length: 26
         Content-Type: application/x-www-form-urlencoded

         user=user&userip=127.0.0.2
         */

        HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest();

        // TODO chain this mofo
        connReq.setHostname(hostName); // see src/javascript/streamone_mock_server.js
        connReq.setCommand("session");
        connReq.setAction("initialize");

        // TODO chain this mofo
        Map<String, String> params = connReq.getParameters();
        params.put("authentication_type", "application");
        params.put("application", "APPLICATION");

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("user", "user");
        args.put("userip", "127.0.0.2");

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
                /**
                 * {
                 "header": {
                 "status": 0,
                 "statusmessage": "OK",
                 "apiversion": 3,
                 "cacheable": false,
                 "timezone": "Europe\/Amsterdam"
                 },
                 "body": {
                 "challenge": "coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6",
                 "salt": "$2y$12$baztaaydu13s4ah6y6pegt",
                 "needsv2hash": false
                 }
                 }
                 */
            }

            @Override
            public void onError(RequestBase request) {
                fail();
            }

            @Override
            public void onLostConnection(RequestBase request, Exception e) {
                fail();
            }
        });
    }

    @Test
    public void createUserSession()
    {
        /**
         *
         3. http://api.nicky.test/api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e
         POST /api/session/create?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&signature=b4cddd93cdb0e46fe8e992d578bc60f82fb3c95e HTTP/1.0
         Host: api.nicky.test
         Content-Length: 132
         Content-Type: application/x-www-form-urlencoded

         challenge=coRUuWCVY3pqiEt69i9IaU8d9E0Q4zz6&response=HQtJEAcGEwAASEJTUx0GRQYKRAACUQ8YD0BdXlVZVC90TBwgdhBlLm9RA1R5N0AFW25wUVMNHHpeY1QD
         */
        HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest();

        // TODO chain this mofo
        connReq.setHostname(hostName); // see src/javascript/streamone_mock_server.js
        connReq.setCommand("session");
        connReq.setAction("create");

        // TODO chain this mofo
        Map<String, String> params = connReq.getParameters();
        params.put("authentication_type", "application");
        params.put("application", "APPLICATION");

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("challenge", ...);

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
                /**
                 * {
                 "header": {
                 "status": 0,
                 "statusmessage": "OK",
                 "apiversion": 3,
                 "cacheable": false,
                 "timezone": "Europe\/Amsterdam"
                 },
                 "body": {
                 "id": "sC5tGogRgBow",
                 "key": "gR92jURda7mEqiDzhcz2bC1FtIzS8wxe",
                 "timeout": 3600,
                 "user": "USER"
                 }
                 }
                 */
            }

            @Override
            public void onError(RequestBase request) {
                fail();
            }

            @Override
            public void onLostConnection(RequestBase request, Exception e) {
                fail();
            }
        });
    }

    @Test
    public void viewUser()
    {
        /**
         *
         4. http://api.nicky.test/api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506
         POST /api/user/viewme?api=3&format=json&authentication_type=application&timestamp=1452846289&application=APPLICATION&session=sC5tGogRgBow&signature=0760294b553bae59d798b2df03e66082b6699506 HTTP/1.0
         Host: api.nicky.test
         Content-Type: application/x-www-form-urlencoded
         */
        HttpUrlConnectionRequest connReq = new HttpUrlConnectionRequest();

        // TODO chain this mofo
        connReq.setHostname(hostName); // see src/javascript/streamone_mock_server.js
        connReq.setCommand("user");
        connReq.setAction("viewme");

        // TODO chain this mofo
        Map<String, String> params = connReq.getParameters();
        params.put("authentication_type", "application");
        params.put("application", "APPLICATION");
        params.put("session", ...);

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
                /**
                 * {
                 "header": {
                 "status": 0,
                 "statusmessage": "OK",
                 "apiversion": 3,
                 "cacheable": true,
                 "sessiontimeout": 3600,
                 "timezone": "Europe\/Amsterdam"
                 },
                 "body": {
                 "id": "USER",
                 "username": "user",
                 "active": true,
                 "datecreated": "2015-09-28 09:05:57",
                 "datemodified": "2016-01-15 09:24:41",
                 "email": "user@streamone.test",
                 "sessionsenabled": true,
                 "timezone": "Europe\/Amsterdam",
                 "mobilephone": "",
                 "address": "",
                 "zipcode": "",
                 "city": "",
                 "firstname": "",
                 "lastname": ""
                 }
                 }
                 */
            }

            @Override
            public void onError(RequestBase request) {
                fail();
            }

            @Override
            public void onLostConnection(RequestBase request, Exception e) {
                fail();
            }
        });
    }

    // TODO unit test Customer session (i.e. replace 'user' with 'customer'
}