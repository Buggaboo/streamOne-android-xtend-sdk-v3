package nl.streamone.sdk

/**
 * Created by jasmsison on 15/01/16.
 */
import org.xtendroid.parcel.AndroidParcelable
import org.xtendroid.annotations.EnumProperty
import org.eclipse.xtend.lib.annotations.Accessors

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

    new (Authentication a)
    {
        url = a.url
        authenticationType = a.authenticationType
        userId = a.userId
        userPsk = a.userPsk
        defaultAccountId = a.defaultAccountId
    }
}

class Session
{

}

class RequestFactory<Q extends RequestBase, R extends Response>
{

    def Session createSession(Authentication authentication, R response)
    {
/*
        // session/initialize
        val request = new Q()
        .execute(R)

        // session/create
*/
    }

    def Q createRequest(Authentication authentication)
    {

    }

    def Q createRequest(Session session)
    {

    }

}