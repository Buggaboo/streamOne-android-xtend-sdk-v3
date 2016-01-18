package nl.streamone.sdk;

import android.app.Application;
import android.test.ApplicationTestCase;
import android.test.suitebuilder.annotation.SmallTest;

import java.util.Map;

import nl.streamone.sdk.RequestBase
import nl.streamone.sdk.Response

import org.junit.Test;
import java.util.regex.Pattern;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

/**
 * <a href="http://d.android.com/tools/testing/testing_android.html">Testing Fundamentals</a>
 */
public class HttpUrlConnectionRequestTest {
    public HttpUrlConnectionRequestTest() {}

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
        connReq.setHostname(hostName); // see src/javascript/streamone_mock_server.js
        connReq.setCommand("application");
        connReq.setAction("view");

        // TODO chain this mofo
        Map<String, String> params = connReq.getParameters();
        params.put("authentication_type", "application");
        params.put("application", "APPLICATION");
        params.put("signature", ...);

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("application", "APPLICATION");
        args.put("limit", "3");

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
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
        params.put("signature", ...);

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("user", "user");
        args.put("userip", "127.0.0.2");

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
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
        params.put("signature", ...);

        // TODO chain this mofo
        Map<String, String> args = connReq.getArguments();
        args.put("challenge", ...);

        connReq.execute(new Response() {

            @Override
            public void onSuccess(RequestBase request) {
                assertTrue(String.format("Connection succesful, response: %s", getBody()), true);
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