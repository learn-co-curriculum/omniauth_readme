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

Running these commands will make these key value pairs appear in the ENV hash in ruby in that terminal.  A more lasting way to do this is using the Figaro or Dotenv gems.

Jump into the console to check that you have set the keys properly.  If `ENV["FACEBOOK_KEY"]` and `ENV["FACEBOOK_SECRET"]` return your keys you're all set!

We now need to create a link that will take the user to facebook to login.  Create a link anywhere you'd like that sends the user to "/auth/facebook".  We'll need a route, a controller and a view, I'll only show the view.

```ruby
  #\views\static\home.html.erb
  <%= link_to("login with facebook!", "/auth/facebook") %>


Then run `rails s` again.

Create a `SessionsController`. This will be simpler than ones we've made in the past. This time, we won't log you in at all, we'll just print all the information in the `request.env['omniauth.auth']` hash. The tests verify that the controller sets the appropriate variable for the views; ensure they pass.

There is already a view that outputs all the authentication data, as well as showing you the user's photo if one is provided.

We're not logging anyone in now. But if we were, it wouldn't be hard. You can trust the data coming in from `request.env['omniauth.auth']`, at least as far as you can trust the authentication provider.

For extra fun, try editing your initializer to look like this:

    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
               info_fields: ['name', 'email', 'age_range', 'context'].join(',')
    end

You can add more fields from the list [here][facebook_info_fields], and see what Facebook has to say about you.

And here's how it works from your standpoint:

  1. You add the Omniauth gem.
  2. You configure the gem. If you want to use external authentication providers like Facebook, this will involve going to those sites and signing up for developer accounts and generating API tokens. This will be an enormous pain. Probably you will struggle with weird issues for an hour or so. But you will only have to [shave such a yak][yak] a few hundred times in your lifetime as a developer, and it is worth it for the users.
  3. You configure your controllers and routes such that when you want to authenticate a user, you send them to `/auth/:provider`. For example, you might have your "login with Twitter" button link to `/auth/twitter`.
  4. You configure a controller to respond to `/auth/:provider/callback`. Omniauth puts all the information it was able to find about the user into `request.env['omniauth.auth']`. You read that hash and decide whether to let the user in.

Behind the scenes, Omniauth is redirecting your users to Google's authentication servers. Google's servers verify your user's identity, ask the user if it's okay to share that identity with your site, and if they say yes, Google passes that information back to your server. Omniauth interprets the information and puts it into `request.env['omniauth.auth']`.

[ip_geolocation]: https://en.wikipedia.org/wiki/Geolocation
[ip_fingerprinting]: https://en.wikipedia.org/wiki/TCP/IP_stack_fingerprinting]
[CAPTCHA]: [https://en.wikipedia.org/wiki/CAPTCHA]
[yak]: [https://en.wiktionary.org/wiki/yak_shaving]
[omniauth]: https://github.com/intridea/omniauth