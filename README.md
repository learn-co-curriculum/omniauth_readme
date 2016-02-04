# Omniauth

## Objectives
  1. Describe the problem of authentication and how Omniauth solves it.
  2. Explain an Omniauth strategy.
  3. Describe the problem OAuth solves, and how it solves it.
  4. Use Omniauth to provide OAuth authentication in a Rails server.

## Overview

Passwords are terrible.

For one thing, you have to remember them. Or you have to use a password manager, which comes with its own problems. Unsurprisingly, some percentage of users will just leave and never come back the moment you ask them to create an account.

And then on the server, you have to manage all these passwords. You have to store them securely. Rails secures your passwords when they are stored in your database, but it does not secure your servers, which see the password in plain text. If I can get into your servers, I can edit your Rails code and have it send all your users' passwords to me as they submit them. You'll also have to handle password changes, email verification, and password recovery. Inevitably, your users accounts will get broken into. This may or may not be your fault, but when they write to you, it will be your problem.

What if it could be someone else's problem?

Like Google, for example. They are dealing with all these problems somehow (having a huge amount of money helps). For example, when you log into Google, they are looking at vastly more than your username and password. Google considers where you are in the world (they can [guess based on your IP address][ip_geolocation], the operating system you're running (their servers can tell because they [listen very carefully to your computer's accent when it talks to them][ip_fingerprinting]), and numerous other factors. If the login looks suspicious—like you usually log in on a Mac in New York, but today you're logging in on a Windows XP machine in Thailand—they may reject it, or ask you to solve a [CAPTCHA].

Wouldn't it be nice if your users could use their Google—or Twitter, or Facebook—login for your site?

Of course, you know this is possible. I'm sure you've seen sites that let you log in with Facebook. Today, we're going to talk about how you can enable such a feature for your site.

## Omniauth

[Omniauth][omniauth] is a gem for Rails that lets you use multiple authentication providers on your site. You can let people log in with Twitter, Facebook, Google, or with a username and password.

Here's how it works from the user's standpoint:

  1. I try to access a page which requires me to be logged in. I am redirected to the login screen.
  2. It offers me the options of creating an account, or logging in with Google or Twitter.
  3. I click "login with Google". This momentarily sends me to `$your_site/auth/google`, which quickly redirects to the Google signin page.
  4. If I'm not signed in to Google, I sign in. More likely, I am already signed in to Google (because Gmail), so Google asks me if they should let `$your_site` know who I am. I say yes.
  5. I am (hopefully briefly) redirected to `$your_site/auth/google/callback`, and from there, to the page I wanted.

Let's see how this works in practice:

## Omniauth with Facebook

The Omniauth gem allows up to use the oauth protocol with a number of different providers.  All we need to do is add the gem specific to the provider we want to use in addition to the omniauth gem, in this case
add `omniauth` and `omniauth-facebook` to your Gemfile and `bundle`.  We can add as many additional omniauth gems if you want multiple provider login in our app. 

First we'll need to tell omniauth about our app's oauth credentials.

Create `config/initializers/omniauth.rb`. It will contain this:
```ruby
    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    end
```
The ENV constant refers to a global hash for your entire computer environment.  You can store any key value pairs in this environment and so it's a very useful place to store credentials that we don't want to be managed by git and later stored on github (if your repo is public).  The most common error we see from students here is that when ENV["PROVIDER_KEY"] is evaluated in the initializer it returns nil!  Then later when you try and authenticate with the provider you'll get some kind of 4xx error because the provider doesn't recognize your app.

To recieve these credentials, each provider's process is different, but you'll essentially need to register your app with the provider and they'll give you a set of keys specific to your app.

For Facebook:
Log in to [the Facebook developer's panel][facebook_dev]. Create an app, copy the key (it's called "App ID" on Facebook's page) and the secret and set them as environment variables in the terminal:

    export FACEBOOK_KEY=<your_key>
    export FACEBOOK_SECRET=<your_key>

We've included a [quick video](https://youtu.be/1yryyKB7Edk) as this often trips people up (including experienced folks!).  Make sure you do the last two steps of setting your URL and valid domains. If you don't Facebook will think you're making a request from an invalid site and will never let the user login.

Running these commands will make these key value pairs appear in the ENV hash in ruby in that terminal.  A more lasting way to do this is using the Figaro or Dotenv gems.

Jump into the console to check that you have set the keys properly.  If `ENV["FACEBOOK_KEY"]` and `ENV["FACEBOOK_SECRET"]` return your keys you're all set!

We now need to create a link that will take the user to Facebook to login.  Create a link anywhere you'd like that sends the user to "/auth/facebook".  We'll need a route, a controller and a view, I'll only show the view.

```ruby
  #\views\static\home.html.erb
  <%= link_to("login with facebook!", "/auth/facebook") %>
```
**Hot-Tip**
Log out of Facebook before you do this portion so you can see the full flow.

Let's visit this page in the browser and click on the link.
Clicking on the link clearly sends a GET request to your server to "/auth/facebook", but in the browser we end up at "https://www.facebook.com/login.php?skip_api_login=1&api_key=1688265381390456&signed_next=1&next=https%3A%2F%2Fwww.facebook.com%2Fv2.5%2Fdialog%2Foauth%3Fredirect_uri%3Dhttp%253A%252F%252Flocalhost%253A3000%252Fauth%252Ffacebook%252Fcallback%26state%3Dc7e7feeea98f875e7a77d76f7385ea2960db3dc23a397c4b%26scope%3Demail%26response_type%3Dcode%26client_id%3D1688265381390456%26ret%3Dlogin&cancel_url=http%3A%2F%2Flocalhost%3A3000%2Fauth%2Ffacebook%2Fcallback%3Ferror%3Daccess_denied%26error_code%3D200%26error_description%3DPermissions%2Berror%26error_reason%3Duser_denied%26state%3Dc7e7feeea98f875e7a77d76f7385ea2960db3dc23a397c4b%23_%3D_&display=page"

This URL has a whole bunch of parameters all URL (encoded)[http://ascii.cl/url-encoding.htm] (which is why they look so strange).  At this point we are at Facebook's site because somewhere in our app omniauth sent the browser a redirect to that url (which it intelligently autogenerated for us!).

Once we're at Facebook and the user logs in, Facebook will send the browser ANOTHER redirect with the URL omniauth told it about in the previous URL.  Omniauth always wants Facebook to redirect us back to our server to the route "/auth/whatever_provider/callback".  Along with that request they'll send a whole bunch of information for us!  

The URL in your browser should looks something like this mess!
"
http://localhost:3000/auth/facebook/callback?code=AQA_CrhVYnuufhQid-3vS1NvI5rZfk4uPJwFZIymA90JeUR7NDFFy0bHQjbtneLkymqqZlmFbjcg2A0y5zRmaCy0D7k9H46F3j9pm9slzBIN9fM4Q54zAdiVZo2k6XtiMPZ_AG2xEZ8MyiTtbbQOBdaK57PY7lr7iLuFeaVUCUnZC69ddzcq_tLILEkjagSyWXi8WGGshbnIwy9C6d98hnoxl6AJjIi4TC3FScEAxKQ9vH1tXntQ9YvTLNWlWsWUcbefEq1RlywNi3IqGsLnDgyyRcHph0u4-TpnaqZPxHSNdcWCgnYfHK_bSO-R_a3H4Oo&state=60fb843af784e411ea7b5f809e34dd29d5e4eda891d0c4c1#_=_
"

You should now see a routing error
`No route matches [GET] "/auth/facebook/callback"`

Let's add something to handle that redirect

```ruby
#routes.rb
get '/auth/facebook/callback' => 'sessions#create'
#note the controller and action you use don't matter, but to be semantic we #should use the sessions controller because we're going to log the user in #by creating a session.
```
Now we create a `SessionsController`. Our goal here is to either create a new user or find the user in our database and log them in.  Facebook sends us a bunch of information back and omniauth parses it for us and puts it in the request environment `request.env['omniauth.auth']`.  We can use the information in here to login the user or create them.

Here's a sample of the auth hash Facebook sends us
```ruby
{
  :provider => 'facebook',
  :uid => '1234567',
  :info => {
    :email => 'joe@bloggs.com',
    :name => 'Joe Bloggs',
    :first_name => 'Joe',
    :last_name => 'Bloggs',
    :image => 'http://graph.facebook.com/1234567/picture?type=square',
    :urls => { :Facebook => 'http://www.facebook.com/jbloggs' },
    :location => 'Palo Alto, California',
    :verified => true
  },
  :credentials => {
    :token => 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
    :expires_at => 1321747205, # when the access token expires (it always will)
    :expires => true # this will always be true
  },
  :extra => {
    :raw_info => {
      :id => '1234567',
      :name => 'Joe Bloggs',
      :first_name => 'Joe',
      :last_name => 'Bloggs',
      :link => 'http://www.facebook.com/jbloggs',
      :username => 'jbloggs',
      :location => { :id => '123456789', :name => 'Palo Alto, California' },
      :gender => 'male',
      :email => 'joe@bloggs.com',
      :timezone => -8,
      :locale => 'en_US',
      :verified => true,
      :updated_time => '2011-11-11T06:21:03+0000'
    }
  }
}
```
Let's log the user in! (We've omitted the model related code)

```ruby
#app/controllers/sessions_controller
class SessionsController < ApplicationController

  def create
    user = User.find_or_create_by_uid(auth['uid']) do |u|
      u.info = auth['info']['name']
      u.email = auth['info']['email']
    end
    session[:user_id] = user.id
  end

  def auth
    request.env['omniauth.auth']
  end

end
```

That completes the whole oauth login flow!

##Conclusion

Implementing the oauth protocol yourself is extremely complicated.  Using the omniauth gem along with the omniauth-provider gem for the provider you'd like to allow users to log in to your site with makes the process a lot easier, but it still trips a lot of people up!  Make sure you understand each piece of the flow, what you expect to happen, and any deviance from the expected result.  The end result should be getting access to the users data from the provider in your sessions controller where you can decide what to do with it, which is usually either creating a user in your database using their provider data, and/or logging them in.

[ip_geolocation]: https://en.wikipedia.org/wiki/Geolocation
[ip_fingerprinting]: https://en.wikipedia.org/wiki/TCP/IP_stack_fingerprinting]
[CAPTCHA]: [https://en.wikipedia.org/wiki/CAPTCHA]
[yak]: [https://en.wiktionary.org/wiki/yak_shaving]
[omniauth]: https://github.com/intridea/omniauth