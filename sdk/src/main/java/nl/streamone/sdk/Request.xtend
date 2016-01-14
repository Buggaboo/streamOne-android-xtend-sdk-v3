package nl.streamone.sdk

import java.net.URL

/**
 * The base class for Request, abstracting authentication details
 *
 * This abstract class provides the basics for doing requests to the StreamOne API, and abstracts
 * the authentication details. This allows for subclasses that just implement a valid
 * authentication scheme, without having to re-implement all the basics of doing requests. For
 * normal use, the Request class provides authentication using users or applications, and
 * SessionRequest provides authentication for requests executed within a session.
 */

interface ResponseAdapterInterface
{
    def void success()
    def void fail()
    def void noConnection()
}

abstract class RequestBase
{
    /**
     * The API command to call
     */
    @Accessor
    var String command

    /**
     * The action to perform on the API command called
     */
    @Accessor
    val String action

    /**
     * The parameters to use for the API request
     *
     * The parameters are the GET-parameters sent, and include meta-data for the request such
     * as API-version, output type, and authentication parameters. They cannot directly be set.
     */
    /*
    val parameters = #{
        'api' -> 3,
        'format' -> 'json'
    }
    */

    var parameters = newLinkedHashMap(
            'api' -> 3,
            'format' -> 'json'
    )

    /**
     * The arguments to use for the API request
     *
     * The arguments are the POST-data sent, and represent the arguments for the specific API
     * command and action called.
     */
    @Accessors
    var arguments = newLinkedHashMap()

    /**
     * The plain-text response received from the API server
     *
     * This is the plain-text response as received from the server, or null if no plain-text
     * response has been received.
     */
    @Accessors
    var String plainResponse

    /**
     * The parsed response received from the API
     *
     * This is the parsed response as received from the server, or null if no parseable response
     * has been received.
     */
    @Accessors
    var Response response

    /**
     * The protocol to use for requests
     */
    @Accessors
    var String protocol = 'http' // default

    /**
     * Construct a new request
     *
     * @param string command
     *   The API command to call
     * @param string action
     *   The action to perform on the API command
     */
    new () {} // default ctor
    new (String command, String action)
    {
        this.command = command
        this.action = action
    }

    /**
     * Set the account to use for this request
     *
     * Most actions require an account to be set, but not all. Refer to the documentation of the
     * action you are executing to read whether providing an account is required or not.
     *
     * @param string|null account
     *   ID of the account to use for the request if null, clear account
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    /*
     def setAccount(account)
    {
        if (account === null && isset(this.parameters['account']))
        {
            unset(this.parameters['account'])
        }
        elseif (account !== null)
        {
            this.parameters['account'] = account
        }

        // If a customer is set clear it, because account and customer are mutually exclusive
        if (isset(this.parameters['customer']))
        {
            unset(this.parameters['customer'])
        }

        return this
    }*/

    // builder pattern
    def RequestBase account (String account)
    {
        account.setAccount
        this
    }

    def void setAccount (String account)
    {
        // if the parameter is empty, don't even bother adding to the request params
        if (account.isEmpty)
        {
            if (parameters.contains('account'))
            {
                parameters.remove('account')
            }
        }else
        {
            parameters.add('account' -> account)

            // If a customer is set clear it, because account and customer are mutually exclusive
            // actually this is a nasty code smell
            // this business logic should be declared explicitly/defensively by throwing an exception
            // TODO discuss with original maintainer
            if (parameters.contains('customer'))
            {
                parameters.remove('customer')
            }
        }
    }

    // TODO use android's TextUtil.isEmpty instead, but we want to use this outside of android
    //def boolean isEmpty(CharSequence str) // abstract type...
    def boolean isEmpty(CharSequence str)
    {
        str != null && str.isEmpty
    }

    // TODO figure out if java -> objc already does the boxing
    /*
    def boolean isEmpty(String str)
    {
        str != null && str.isEmpty
    }
    */

    /**
     * Get the account to use for this request
     *
     * If an account is not set, return null
     *
     * @return string|null
     *   The ID of the account to use for the request or null if no account is set. If more than
     *   one account has been set (with setAccounts), the first one will be returned
     */
    /*
     def getAccount()
    {
        if (isset(this.parameters['account']))
        {
            accounts = explode(',', this.parameters['account'])
            if (!empty(accounts))
            {
                return accounts[0]
            }
        }

        return null
    }*/

    // wtf... you do things intentionally, none of this guessing game...
    // TODO write unit test
    def String getFirstAccount()
    {
        if (parameters.contains('account'))
        {
            val accountMaybePlural = parameters.get('account')
            val index = accountMaybePlural.indexOf(',')
            if(index > -1)
            {
                return accountMaybePlural.substring(0, index)
            }else
            {
                return accountMaybePlural
            }
        }
        null
    }

    /**
     * Set the accounts to use for this request
     *
     * Some actions allow you to set more than one account at the same time. Refer to the
     * documentation of the action you are executing to read whether providing more than one
     * account is allowed or not.
     *
     * @param array accounts
     *   Array with IDs of the accounts to use for the request if empty, clear accounts
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    def void setAccounts(String... accounts)
    {
        val buffer = new StringBuffer
        for (a : accounts)
        {
            buffer.append(',').append(a)
        }
        val complete = buffer.toString
        parameters.add('account' -> complete.substring(1, complete.length))
    }

    def RequestBase accounts(String... accounts)
    {
        accounts.setAccounts
        this
    }

    /**
     * Get the accounts to use for this request
     *
     * If an accounts are set, return an empty array
     *
     * @return array()
     *   An array with the IDs of the accounts to use for the request
     */
    def String[] getAccounts()
    {
        if (parameters.contains('account'))
        {
            return parameters.get('account').splitter
        }
        null
    }

    /**

     TODO implement android code
    // Once
    TextUtils.StringSplitter splitter = new TextUtils.SimpleStringSplitter(delimiter);

    // Once per string to split
    splitter.setString(string);
    for (String s : splitter) {
    ...
    }
    */
    def String[] splitter(String joinedAccounts)

    /**
     * Set the customer to use for this request
     *
     * Some actions require an account to be set and others have it as an alternative to an account.
     * Refer to the documentation to check whether it is needed
     *
     * @param string|null customer
     *   ID of the customer to use for the request if null clear customer
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    def setCustomer(String customer)
    {
        // if the parameter is empty, don't even bother adding to the request params
        if (customer.isEmpty)
        {
            if (parameters.contains('customer'))
            {
                parameters.remove('customer')
            }
        }else
        {
            parameters.add('customer' -> customer)

            // actually this is a nasty code smell
            // this business logic should be declared explicitly/defensively by throwing an exception
            // TODO discuss with original maintainer
            if (parameters.contains('account'))
            {
                parameters.remove('account')
                // TODO throw exception, there is an account defined
            }
        }
    }

    def RequestBase customer(String customer)
    {
        customer.setCustomer
        this
    }

    /**
     * Get the customer to use for this request
     *
     * If an customer is not set, return null
     *
     * @return string|null
     *   The ID of the customer to use for the request or null if no customer is set
     */
     def getCustomer()
    {
        if (parameters.contains('customer'))
        {
            return parameters.get('customer')
        }
        return null
    }

    /**
     * Set the timezone to use for this request.
     *
     * If no timezone is set, the default timezone for the actor (user or application) doing the
     * request is used.
     *
     * @param DateTimeZone time_zone
     *   Timezone to use for the request
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
     def void setTimeZone(String timeZone)
    {
        parameters.add('timezone' -> timeZone)
    }

    def RequestBase timeZone(String timeZone)
    {
        timeZone.setTimeZone
        this
    }

    /**
     * Set the value of a single argument
     *
     * @param string argument
     *   The name of the argument
     * @param string value
     *   The new value for the argument null will be translated to an empty string and an array
     *   will be joined by comma's
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    /*
     def setArgument(argument, value)
    {
        if (value === null)
        {
            value = ''
        }
        elseif (is_array(value))
        {
            value = implode(',', value)
        }
        this.arguments[argument] = value

        return this
    }
    */
    def RequestBase addArgument(String arg, String value)
    {
        arguments.add(arg -> value)
        this
    }

    /**
     * Set the value of a single parameter
     *
     * @param string parameter
     *   The name of the parameter
     * @param string value
     *   The new value for the parameter null will be translated to an empty string
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    /*
    protected def setParameter(parameter, value)
    {
        if (value === null)
        {
            value = ''
        }
        this.parameters[parameter] = value

        return this
    }
    */
    def RequestBase addParameter(String param, String value)
    {
        parameters.add(param -> value)
        this
    }

    /**
     * Retrieve the currently defined parameters
     *
     * @return array
     *   An array containing the currently defined parameters as key=>value pairs
     */
    /*
    protected def parameters()
    {
        return this.parameters
    }
    */
    // See @Accessor

    /**
     * Sets the protocol to use for requests, e.g. 'http'
     *
     * Using this method overrides any protocol set in the API URL. The protocol must not
     * contain trailing '://', even though the protocol() method returns protocols with '://'
     * appended.
     *
     * @param protocol string
     *   The protocol to use
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    // See @Accessor protocol
    /*
     def setProtocol(protocol)
    {
        this.protocol = protocol

        return this
    }
    */

    /**
     * Retrieves the protocol to use for requests, with trailing ://
     *
     * If a protocol has been set using setProtocol(), that protocol is used. Otherwise, if a
     * protocol is present in the API URL, that protocol is used. If neither gives a valid
     * protocol, the default of 'http' is used.
     *
     * This method returns the protocol with trailing '://', while setProtocol() requires
     * a protocol without trailing '://'. For example, when the protocol is set to 'https',
     *
     *
     * @return string
     *   The protocol to use
     */
    // see @Accessor
    /*
     def protocol()
    {
        if (this.protocol !== null)
        {
            // Protocol overridden by setProtocol
            return this.protocol . '://'
        }

        // Use protocol from API URL if given
        protohost = this.getApiProtocolHost()
        if (protohost['protocol'] !== null)
        {
            return protohost['protocol'] . '://'
        }

        // No protocol set in any way default to HTTP
        return 'http://'
    }
    */

    /**
     * Retrieve the API protocol and host, as retrieved from the apiUrl() method
     *
     * The API URL is split into up to 3 parts, the protocol, host and prefix. The following
     * forms of URLs, as provided by apiUrl(), are supported:
     *
     * - `protocol://host/prefix`
     * - `protocol://host`
     * - `host/prefix`
     * - `host`
     *
     * @return array
     *   An array with 3 elements:
     *   - protocol: a string with the protocol specified in the API URL, or null if not present
     *   - host: a string with the host as specified in the API URL
     *   - prefix: a possibly empty string with the path prefix of the URL  contains basically
     *             everything after the host
     */
    // You as the developer should DIY, this is stupidly easy in java with URL
    /*
    @Deprecated
    protected def getApiProtocolHost()
    {
        val url = new URL(apiUrl)
        return #{
            'protocol' -> url.protocol,
            'host' -> url.host,
            'prefix' -> url.path, // TODO wtf? prefix???? suffix! Discuss with maintainer
            'path' -> url.path
        }
    }
    */
    /*
    {
        // a combination of letters, digits, plus ("+"), period ("."), or hyphen ("-")
        pattern = '@^(?:([a-zA-Z0-9\+\.-]+):/?/?)?([^/]*)(.*)@'
        api_url = this.apiUrl()
        preg_match(pattern, api_url, matches)
        return #{
            'protocol' -> (strlen(matches[1]) == 0) ? null : matches[1],
            'host' -> matches[2],
            'prefix' -> matches[3]
        }
    }
    */

    /**
     * Gather the server, path, parameters, and arguments for the request to execute
     *
     * @return array
     *   An array with 4 elements:
     *   - The server (`protocol://host/prefix`) to send the request to
     *   - The path of the request (`/api/command/action`)
     *   - The parameters for the request, as a key=>value array, including the parameters
     *       required for authentication
     *   - The arguments for the request, as a key=>value array
     */
    /*
    protected def prepareExecute()
    {
        // Gather path, signed parameters and arguments
        protohost = this.getApiProtocolHost()
        server = this.protocol() . protohost['host'] . protohost['prefix']
        path = this.path()
        parameters = this.signedParameters()
        arguments = this.arguments()

        return array(server, path, parameters, arguments)
    }*/
    /**
        Why bother?
     */
    /*
    @Deprecated
    protected def prepare()
    {

    }
    */

    /**
     * Execute the prepared request
     *
     * This will sign the request, send it to the Internal API server, and analyze the response. To
     * check whether the request was successful and returned no error, use the method success().
     *
     * @return RequestBase
     *   A reference to this object, to allow chaining
     */
    // TODO add call back anonymous type
    def execute(ResponseAdapterInterface response)
    /*
    {
        list(server, path, parameters, arguments) = this.prepareExecute()

        // Actually execute the request
        response = this.sendRequest(new URL(apiUrl), parameters, arguments)

        // Handle the response
        this.handleResponse(response)

        return this
    }*/

    /**
     * Check if the returned response is valid
     *
     * A valid response contains a header and a body, and the header contains at least the fields
     * status and statusmessage with correct types.
     *
     * @return bool
     *   Whether the retrieved response is valid
     */
    /*
     def valid()
    {
        // The response must be a valid array
        if ((this.response === null) || (!is_array(this.response)))
        {
            return false
        }

        // The response must have a header and a body
        if (!array_key_exists('header', this.response) ||
        !array_key_exists('body', this.response))
        {
            return false
        }

        // The header must be an array and contain a status and statusmessage
        if (!is_array(this.response['header']) ||
        !array_key_exists('status', this.response['header']) ||
        !array_key_exists('statusmessage', this.response['header']))
        {
            return false
        }

        // The status must be an integer and the statusmessage must be a string
        if (!is_int(this.response['header']['status']) ||
        !is_string(this.response['header']['statusmessage']))
        {
            return false
        }

        // All is valid
        return true
    }*/
    // TODO discuss, WTF would a ReQuest object care about the ResPonse object? Code smell, method envy
    /*
    @Deprecated
    def boolean valid()
    {

    }
    */

    /**
     * Check if the request was successful
     *
     * The request was successful if the response is valid, and the status is 0 (OK).
     *
     * @return bool
     *   Whether the request was successful
     */
    /*
     def success()
    {
        return (this.valid() && (this.response['header']['status'] === 0))
    }
    */
    // NOTE see valid()

    /**
     * Retrieve the header as received from the server
     *
     * This method returns the response header as received from the server. If the response was
     * not valid (check with valid()), this method will return null.
     *
     * @return array
     *   The header of the received response null if the response was not valid
     */
    /*
     def header()
    {
        if (!this.valid())
        {
            return null
        }

        return this.response['header']
    }
    */

    /**
     * Retrieve the body as received from the server
     *
     * This method returns the response body as received from the server. If the response was
     * not valid (check with valid()), this method will return null.
     *
     * @return array
     *   The body of the received response null if the response was not valid
     */
    /*
     def body()
    {
        if (!this.valid())
        {
            return null
        }

        return this.response['body']
    }
    */

    /**
     * Retrieve the plain-text response as received from the server
     *
     * This method returns the entire plain-text response as received from the server. If there was
     * no valid plain-text response, this method will return null.
     *
     * @return string
     *   The plain-text response null if no response was received
     */
    /*
     def plainResponse()
    {
        return this.plain_response
    }
    */

    /**
     * Retrieve the status returned for this request
     *
     * @return int
     *   The status returned for this request, or null if no valid response was received
     */
    /*
     def status()
    {
        if (!this.valid())
        {
            return null
        }
        return this.response['header']['status']
    }
    */

    /**
     * Retrieve the status message returned for this request
     *
     * @return string
     *   The status message returned for this request, or 'invalid response' if no valid response
     *   was received
     */
    /*
     def statusMessage()
    {
        if (!this.valid())
        {
            return 'invalid response'
        }
        return this.response['header']['statusmessage']
    }
    */

    /**
     * This def returns the base URL of the API, with optional protocol and without trailing /
     *
     * Subclasses will overwrite this def to get it from the correct configuration
     *
     * @return string
     *   The base URL of the API
     */
    abstract protected def String getApiUrl()

    /**
     * This def should return the key used for signing the request
     *
     * Subclasses will overwrite this def to provide the correct key
     *
     * @return string
     *   The key used for signing
     */
    abstract protected def getSigningKey()

    /**
     * Retrieve the path to use for the API request
     *
     * @return string
     *   The path for the API request
     */
    protected def getPath()
    {
        return String.concat('/api/', command , '/' , action)
    }

    /**
     * Retrieve the parameters used for signing
     *
     * Subclasses will add the parameters that are used specifically for those classes
     *
     * @return array
     *   An array containing the parameters needed for signing
     */
    protected def getParametersForSigning()
    {
        // Add basic authentication parameters
        parameters.add('timestamp' -> new Date().time) // convenience? code smell.

        return parameters
    }

    /**
     * Retrieve the signed parameters for the current request
     *
     * This method will lookup the current path, parameters and arguments, calculates the
     * authentication parameters, and returns the new set of parameters.
     *
     * @return array
     *   An array containing the defined parameters, as well as authentication parameters, both as
     *   key=>value pairs
     */
    protected def getSignedParameters()
    {
        parametersForSigning
        parameters.add('signature' -> signature)

        return parameters
    }

    /**
     * Returns the signature for the current request
     *
     * @return String
     *   The signature for the current request
     */
    protected def getSignature()
    {
        parameters.map[ k,v | k + '=' + 'v' ]
        arguments.map[ k,v | k + '=' + 'v' ]
    }
    /*
    {
        parametersForSigning
        path = this.path()
        arguments = this.arguments()

        // Calculate signature
        url = path . '?' . http_build_query(parameters) . '&' . http_build_query(arguments)
        key = this.signingKey()

        return hash_hmac('sha1', url, key)
    }
    */

    /**
     * Actually send a signed request to the server
     *
     * @param string server
     *   The API server to use
     * @param string path
     *   The request path
     * @param array parameters
     *   The request parameters as key=>value pairs
     * @param array arguments
     *   The request arguments as key=>value pairs
     * @return string
     *   The plain-text response from the server false if the request failed
     *
     * @codeCoverageIgnore
     *   This def is deliberately not included in unit tests
     */
    protected def sendRequest(server, path, parameters, arguments)
    {
        // Build the URL (including GET-params)
        url = server . path . '?' . http_build_query(parameters)

        // Create the required stream context for POSTing
        stream_parameters = array(
                'http' => array(
                        'method' => 'POST',
                        'content' => http_build_query(arguments),
                        'header' => "Content-Type: application/x-www-form-urlencoded"
                )
        )
        stream_parameters = array_merge(stream_parameters, this.extraStreamParameters())
        context = stream_context_create(stream_parameters)

        // Actually do the request and return the response
        return file_get_contents(url, false, context)
    }

    /**
     * Handle a plain-text response as received from the API
     *
     * @param mixed response
     *   The plain-text response as received from the API parsing will not be succesful if this is
     *   not a string.
     */
    protected def handleResponse(response)
    {
        // Only attempt handling the response if it is a string
        if (is_string(response))
        {
            this.plain_response = response

            // Attempt to decode the (JSON) response returns null if failed
            this.response = json_decode(response, true)
        }
    }

    /**
     * This def returns extra parameters used for stream_context_create in sending requests
     *
     * @return array
     *   Extra parameters to pass to stream_context_create for sending requests
     */
    protected def extraStreamParameters()
    {
        return array()
    }
}

/**
 * Execute a request to the StreamOne API
 *
 * This class represents a request to the StreamOne API. To execute a new request, first construct
 * an instance of this class by specifying the command and action to the constructor. The various
 * arguments and options of the request can then be specified and then the request can be actually
 * sent to the StreamOne API server by executing the request. There are various defs to
 * inspect the retrieved response.
 *
 * \code
 * use StreamOne\API\v3\Platform as StreamOnePlatform
 * platform = new StreamOnePlatform(array(...))
 * request = platform->newRequest('item', 'view')
 * request->setAccount('Mn9mdVb-02mA')
 *         ->setArgument('item', 'vMD_9k1SmkS5')
 *         ->execute()
 * if (request->success())
 * {
 *     var_dump(request->body())
 * }
 * \endcode
 *
 * This class only supports version 3 of the StreamOne API. All configuration is done using the
 * Config class.
 *
 * This class inherits from RequestBase, which is a very basic request-class implementing
 * only the basics of setting arguments and parameters, and generic signing of requests. This
 * class adds specific signing for users, applications and sessions, as well as a basic caching
 * mechanism.
 */
class Request extends RequestBase
{
    /**
     * @var Config config
     *   The Config object with information for this request
     */
    val config

    /**
     * @var bool from_cache
     *   Whether the response was retrieved from the cache
     */
    val from_cache = false

    /**
     * @var int|null cache_age
     *   If the response was retrieved from the cache, how old it is in seconds otherwise null
     */
    val cache_age = null

    /**
     * Construct a new request
     *
     * @see RequestBase::__construct
     *
     * @param string command
     *   The API command to call
     * @param string action
     *   The action to perform on the API command
     * @param Config config
     *   The Config object to use for this request
     *
     * @throw \UnexpectedValueException
     *   The given Config object is not valid for performing requests
     */
     def __construct(command, action, Config config)
    {
        parent::__construct(command, action)

        this.config = config

        // Check if a default account is specified and set it as a parameter. Can later be overridden
        if (this.config->hasDefaultAccountId())
        {
            this.setParameter('account', this.config->getDefaultAccountId())
        }

        // Validate configuration
        if (!config->validateForRequests())
        {
            throw new \UnexpectedValueException('Invalid Config object')
        }

        // Set correct authentication_type parameter
        switch (this.config->getAuthenticationType())
        {
            case Config::AUTH_USER:
            this.setParameter('authentication_type', 'user')
            break

            case Config::AUTH_APPLICATION:
            this.setParameter('authentication_type', 'application')
            break
        }
    }

    /**
     * Retrieve the config used for this request
     *
     * @return Config
     *   The config used for this request
     */
     def getConfig()
    {
        return this.config
    }

    /**
     * Execute the prepared request
     *
     * This method will first check if there is a cached response for this request. If there is,
     * the cached response is used. Otherwise, the request is signed and sent to the API server.
     * The response will be stored in this class for inspection, and in the cache if applicable
     * for this request.
     *
     * To check whether the request was successful, use the success() method. The header and body
     * of the response can be obtained using the header() and body() methods of this class. A
     * request can be unsuccessful because either the response was invalid (check using the valid()
     * method), or because the status in the header was not OK / 0 (check using the status() and
     * statusMessage() methods.)
     *
     * @see RequestBase::execute
     *
     * @return Request
     *   A reference to this object, to allow chaining
     */
     def execute()
    {
        // Check cache
        response = this.retrieveCache()
        if (response === false)
        {
            parent::execute()
        }
        else
        {
            this.handleResponse(response)
        }

        this.saveCache()

        return this
    }

    /**
     * Retrieve whether this response was retrieved from cache
     *
     * @return bool
     *   True if and only if the response was retrieved from cache
     */
     def fromCache()
    {
        return this.from_cache
    }

    /**
     * Retrieve the age of the response retrieved from cache
     *
     * @return int
     *   The age of the response retrieved from cache in seconds. If the response was not
     *   retrieved from cache, this will return null instead.
     */
     def cacheAge()
    {
        return this.cache_age
    }

    /**
     * Retrieve the URL of the StreamOne API server to use.
     *
     * @see RequestBase::apiUrl
     */
    protected def apiUrl()
    {
        return this.config->getApiUrl()
    }

    /**
     * Retrieve the key to use for signing this request.
     *
     * @see RequestBase::signingKey
     */
    protected def signingKey()
    {
        // Config object returns correct key for authentication type in use
        return this.config->getAuthenticationActorKey()
    }

    /**
     * Retrieve the parameters to include for signing this request.
     *
     * @see RequestBase::parametersForSigning
     */
    protected def parametersForSigning()
    {
        parameters = parent::parametersForSigning()

        // Set actor ID parameter
        actor_id = this.config->getAuthenticationActorId()
        switch (this.config->getAuthenticationType())
        {
            case Config::AUTH_USER:
            parameters['user'] = actor_id
            break

            case Config::AUTH_APPLICATION:
            parameters['application'] = actor_id
            break
        }

        return parameters
    }

    /**
     * Handle a plain-text response as received from the API
     *
     * If the request was valid and contains one of the status codes set in
     * Config::getVisibleErrors, a very noticable error message will be shown on the
     * screen. It is advisable that these errors are handled and logged in a less visible manner,
     * and that the visible_errors configuration variable is then set to an empty array. This is
     * not done by default to aid in catching these errors during development.
     *
     * @see RequestBase::handleResponse
     *
     * @param mixed response
     *   The plain-text response as received from the API
     */
    protected def handleResponse(response)
    {
        parent::handleResponse(response)

        // Check if the response was valid and the status code is one of the visible errors
        if (this.valid() && this.config->isVisibleError(this.status()))
        {
            echo '<div style="position:absolutetop:0left:0right:0background-color:blackcolor:redfont-weight:boldpadding:5px 10pxborder:3px outset #d00z-index:2147483647font-size:12ptfont-family:sans-serif">StreamOne API error ' . this.status() . ': <em>' . this.statusMessage() . '</em></div>'
        }
    }

    /**
     * Check whether the response is cacheable
     *
     * @return bool
     *   True if and only if a successful response was given, which is cacheable
     */
    protected def cacheable()
    {
        if (this.success())
        {
            header = this.header()
            if (array_key_exists('cacheable', header) && header['cacheable'])
            {
                return true
            }
        }

        return false
    }

    /**
     * Determine the key to use for caching
     *
     * @return string
     *   A cache-key representing this request
     */
    protected def cacheKey()
    {
        return 's1:request:' . this.path() . '?' . http_build_query(this.parameters()) . '#' .
        http_build_query(this.arguments())
    }

    /**
     * Attempt to retrieve the result for the current request from the cache
     *
     * @return string
     *   The cached plain text response if it was found in the cache false otherwise
     */
    protected def retrieveCache()
    {
        // Retrieve cache object from config
        cache = this.config->getRequestCache()

        // Check for response from cache
        response = cache->get(this.cacheKey())

        if (response !== false)
        {
            // Object found store meta-data and return it
            this.from_cache = true
            this.cache_age = cache->age(this.cacheKey())
            return response
        }

        // No cache hit
        return false
    }

    /**
     * Save the result of the current request to the cache
     *
     * This method only saves to cache if the request is cacheable, and if the request was not
     * retrieved from the cache.
     */
    protected def saveCache()
    {
        if (this.cacheable() && !this.from_cache)
        {
            cache = this.config->getRequestCache()
            cache->set(this.cacheKey(), this.plainResponse())
        }
    }
}

/**
 * Exception thrown if an error occurred while communicating with the API.
 *
 * This exception should be thrown when code cannot be executed because communication with the
 * API failed. It is not thrown from Request itself, but must be thrown from code using that class.
 */
class RequestException extends \RuntimeException
{
    /**
     * Create an RequestException from a Request
     *
     * @param Request request
     *   The request to create an exception from
     * @return RequestException
     *   The exception corresponding to the given request
     */
     static def fromRequest(Request request)
    {
        return new RequestException(request->statusMessage(), request->status())
    }
}

/**
 * Interface definition for a request factory to instantiate different kinds of requests
 */
interface RequestFactoryInterface
{
    /**
     * Instantiate a new request without a session
     *
     * @param string command
     *   The command to execute
     * @param string action
     *   The action to execute
     * @param Config config
     *   The Config object to use for the request
     * @return Request
     *   The instantiated request
     */
    def Request newRequest(String command, String action, Config config)

    /**
     * Instantiate a new request within a session
     *
     * @param string command
     *   The command to execute
     * @param string action
     *   The action to execute
     * @param Config config
     *   The Config object to use for the request
     * @param SessionStoreInterface session_store
     *   The session store containing the required session information
     * @return SessionRequest
     *   The instantiated request
     */
    def SessionRequest newSessionRequest(String command, String action, Config config, SessionStoreInterface session_store)
}

