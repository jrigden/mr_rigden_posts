# Using Tor with the Python Requests Library

> Doing HTTP requests anonymously with Python and Tor.

![](http://static.jasonrigden.com/img/requests_tor/web.png)

If you have used Python then you have probably used the fantastic  [Requests](http://docs.python-requests.org/en/master/)library. It makes doing HTTP request nice and easy. I use this library almost every day. Today I wanted to use it a bit differently. I wanted to use it with  [Tor](https://www.torproject.org/projects/torbrowser.html.en). There are several ways to to this. I’ll showing you one possible way to do it.

## Install Tor

First of all we want to install Tor. In this tutorial the Tor Browser will now help us. Follow these  [instructions for installation and activation](https://www.torproject.org/docs/debian.html.en). Do not use the default version available from your Linux distro. These are very often out of date. As always, it is best to be running to most up to date software. Running outdated software could be dangerous. Follow the official documents.

## Install the Required Library

Remember to use some kind of isolated Python environment system. I like  [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/)  but many others prefer  [pipenv](https://docs.pipenv.org/).

    pip install requests

And import

    import requests

## Setting up a empty session

We will be using the Session object from the Requests library. This object will allow certain parameter to be persistent. We will create a empty Session object.

    session = requests.session()  
    session.proxies = {}

This is how we normally make requests with the Request library:

    r = requests.get('https://jasonrigden.com')

But the using the Session object is a just a tiny bit different:

    r = session.get('https://jasonrigden.com')

## Checking our current IP

_I’ll will not be showing my my real IP address. Instead. I’ll be using your routers address 192.168.0.1.  😉

Let us check out IP address by asking  [httpbin.org](https://httpbin.org/).

    r = session.get(‘http://httpbin.org/ip')
    print(r.text)

Gives us:

    {  
        "origin”: "192.168.0.1"  
    }

That seems normal and expected.

## Use the proxies

Now let us create a new Session object and then add our proxies.

    session = requests.session()  
    session.proxies = {}
    
    session.proxies\['http'\] = 'socks5h://localhost:9050'  
    session.proxies\['https'\] = 'socks5h://localhost:9050'

### Checking our new IP

Now we check out IP address again:

    r = session.get(‘http://httpbin.org/ip')
    print(r.text)

Giving us:

    {  
        "origin": "185.220.101.26"  
    }

This IP appears to be from East Africa but I am in Seattle. Thing seems to be working.

## Dark Web Requests

This setup will also allow us to make request for Tor hidden services aka the dark web. We are going to visit a rather notorious site in this example. A site that has been used for violent revolutions, drugs, and to interfere will democratic elections. I just want to warn you. These guy make money selling you personal info and they will literally sell to anyone. We are going to  [Facebook](https://www.facebook.com/). They run a hidden service at facebookcorewwwi.onion. If you try to visit this address in a standard without Tor you will get nothing. But let us try with our Session object.

    r = session.get('https://www.facebookcorewwwi.onion/')
    print(r.headers)

And we will get

    {    
       'Content-Encoding':'gzip',  
       'Strict-Transport-Security':'max-age=15552000; preload',  
       'X-Frame-Options':'DENY',  
       'X-Content-Type-Options':'nosniff',  
       'Connection':'keep-alive',  
       'Date':'Tue, 06 Feb 2018 23:41:05 GMT',  
       'Transfer-Encoding':'chunked',  
       'Set-Cookie':'fr=0ibUkv48vNYqUtRGO..Baej0R.a4.AAA.0.0.Baej0R.AWXOsJtM; expires=Mon, 07-May-2018 23:41:05 GMT; Max-Age=7776000; path=/; domain=.facebookcorewwwi.onion; secure; httponly,sb=ET16Wt8nU0VqZwyI2JREUG7L; expires=Thu, 06-Feb-2020 23:41:05 GMT; Max-Age=63072000; path=/; domain=.facebookcorewwwi.onion; secure; httponly',  
       'Content-Type':'text/html; charset=UTF-8',  
       'Cache-Control':'private, no-cache, no-store, must-revalidate',  
       'Vary':'Accept-Encoding',  
       'Expires':'Sat, 01 Jan 2000 00:00:00 GMT',  
       'X-XSS-Protection':'0',  
       'X-FB-Debug':'rPWGof2T7AWYKmygk/NHSKiD73OmtkI579bnw/2FQxmgmIKmB92dRJYTjXLr13Fj79PNaBYfp4N5/F2dzcNbSg==',  
       'Pragma':'no-cache'  
    }

We now have access to the dark web through our Python scripts. Now it is time to get paranoid.

## User-agent

We are sending some info our requests:

    r = session.get(‘https://httpbin.org/user-agent')
    print(r.text)

That returns:

    {  
        "user-agent”: “python-requests/2.18.4"  
    }

Well, they would know we are a Python script, what library we are using, and some version info. We can change this.

We will create some request headers and change the User-agent:

    headers = {}  
    headers\['User-agent'\] = “HotJava/1.1.2 FCS”

_Does anyone remember_ [_HotJava_](https://en.wikipedia.org/wiki/HotJava)_? You know it is old school when the download page warns that the software is not Y2K safe._

Then we include the headers in the request:

    r = session.get('https://httpbin.org/user-agent', headers=headers)
    print(r.text)

That returns:

    {  
        "user-agent": "HotJava/1.1.2 FCS"  
    }

### Cookies

Using the Session object mean we have cookies. We will use httpbin to set a cookie with the value, “Hello”:

    session.get('http://httpbin.org/cookies/set/sessioncookie/Hello')

Now we check to see if that cookie is working.:

    r = session.get(‘http://httpbin.org/cookies')
    print(r.text)

And we get:

    {  
        "cookies": {  
            "sessioncookie": "Hello"  
        }  
    }

We can kill the cookies:

    session.cookies.clear()
    r = session.get(‘http://httpbin.org/cookies')
    print(r.text)

Resulting:

    {  
        "cookies": {}  
    }

No more cookies.

## DNS leakage

DNS Leaks are a big concern. Check out the post “[What is a DNS leak and why should I care?](https://www.dnsleaktest.com/what-is-a-dns-leak.html)” for more info. Using  [Wireshark](https://www.wireshark.org/)  we can see the DNS requests for the previous examples.

Example:

    requests.get(‘http://httpbin.org/ip')


![](http://static.jasonrigden.com/img/requests_tor/leak1.png)

But using the proxies through the Session object reveals nothing.

![](http://static.jasonrigden.com/img/requests_tor/leak2.png)

A picture of nothin’

## Conclusion

So this is one way to use Tor with you the Request Library. I hope you find it useful.
