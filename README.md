# OmniAuth

## Objectives

1. Describe the problem of authentication and how OmniAuth solves it.
2. Explain an OmniAuth strategy.
3. Use OmniAuth to handle authentication in a Rails server.

There are no tests for this lesson, but code along as we learn about OmniAuth
and build out a login strategy together! To get started, run:

```console
$ bundle install
$ rails db:migrate
```

> **_NOTE_**: If you run into trouble with GitHub, use the usual avenues for
> assistance (Google, StackOverflow, Pair with a TC, Slack, and so on), but
> don't bash your head against the wall too much. GitHub is the choice for this
> lesson because it is ubiquitous as an OAuth provider, but feel free to pick a
> different provider (Google, for instance). A bit of struggle in the setup
> process is healthy — that's a learning opportunity. However, the ultimate
> point of this lesson is to learn how to use OmniAuth; not to waste six hours
> fighting with the GitHub developer interface.

## Overview

Passwords are terrible.

For one thing, you have to remember them. Or you have to use a password manager,
which comes with its own problems. Unsurprisingly, some percentage of users will
just leave and never come back the moment you ask them to create an account.

And then on the server, you have to manage all these passwords. You have to
store them securely. Rails secures your passwords when they are stored in your
database, but it does not secure your servers, which see the password in plain
text. If I can get into your servers, I can edit your Rails code and have it
send all your users' passwords to me as they submit them. You'll also have to
handle password changes, email verification, and password recovery. Inevitably,
your users accounts will get broken into. This may or may not be your fault,
but, when they write to you, it will be your problem.

What if it could be someone else's problem?

Like Google, for example. They are dealing with all these problems somehow
(having a huge amount of money helps). For example, when you log into Google,
they are looking at vastly more than your username and password. Google
considers where you are in the world (they can guess based on [your IP
address][ip_geolocation]), the operating system you're running (their servers
can tell because they [listen very carefully to your computer's accent when it
talks to them][ip_fingerprinting]), and numerous other factors. If the login
looks suspicious — for instance, you usually log in on a Mac in New York, but
today you're logging in on a Windows XP machine in Thailand — they may reject it
or ask you to solve a [CAPTCHA][captcha].

Wouldn't it be nice if your users could use their Google — or Twitter, Facebook,
GitHub, etc. — login for your site?

Of course, you know this is possible. It's becoming increasingly rare to find a
modern website that _doesn't_ allow users to login via a third-party account.
Today, we're going to talk about how to add this feature to your Rails
applications.

## OmniAuth

[OmniAuth][omniauth] is a gem for Rails that lets you use multiple
authentication providers alongside the more traditional username/password setup.
'Provider' is the most common term for an authentication partner, but within the
OmniAuth universe we refer to providers (e.g., using a GitHub account to log in)
as _strategies_. The OmniAuth wiki keeps [an up-to-date list of
strategies][list_of_strategies], both official (provided directly by the
service, such as GitHub, Heroku, and SoundCloud) and unofficial (maintained by
an unaffiliated developer, such as Facebook, Google, and Twitter).

Here's how OmniAuth works from the user's standpoint:

1. User tries to access a page on `yoursite.com` that requires them to be logged
   in. They are redirected to the login screen.
2. The login screen offers the options of creating an account or logging in with
   Google or Twitter.
3. The user clicks `Log in with Google`. This momentarily sends the user to
   `yoursite.com/auth/google`, which quickly redirects to the Google sign-in
   page.
4. If the user is not already signed in to Google, they sign in normally. More
   likely, they are already signed in, so Google simply asks if it's okay to let
   `yoursite.com` access the user's information. The user agrees.
5. They are (hopefully quickly) redirected to
   `yoursite.com/auth/google/callback` and, from there, to the page they
   initially tried to access.

Let's see how this works in practice.

## OmniAuth with GitHub

The OmniAuth gem allows us to use the OAuth protocol with a number of different
providers. All we need to do is add the OmniAuth gem _and_ the provider-specific
OmniAuth gem (e.g., `omniauth-google`) to our Gemfile. In some cases, adding
only the provider-specific gem will suffice because it will install the OmniAuth
gem as a dependency, but it's safer to add both — the shortcut is far from
universal.

In this case, let's add a few gems to the Gemfile by running:

```console
$ bundle add omniauth omniauth-github omniauth-rails_csrf_protection
```

If we were so inclined, we could add additional OmniAuth gems to our heart's
content, offering login via multiple providers in our app.

Next, we'll need to tell OmniAuth about our app's OAuth credentials. Create a
file named `config/initializers/omniauth.rb`. It will contain the following
lines:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
end
```

The code is unfamiliar, but we can guess what's going on from the
characteristically clear Rails syntax. We're telling our Rails app to use a
piece of middleware created by OmniAuth for the GitHub authentication strategy.

### `ENV`

The `ENV` constant refers to a global hash for your entire computer environment.
You can store any key-value pairs in this hash, so it's a very useful place to
keep credentials that we don't want to be managed by Git or displayed on GitHub
(especially if your GitHub repo is public). The most common error students run
into is that when `ENV["PROVIDER_KEY"]` is evaluated in the OmniAuth initializer
it returns `nil`. Later attempts to authenticate with the provider will cause
some kind of `4xx` error because the provider doesn't recognize the app's
credentials (because they're evaluating to `nil`).

As you can gather from the initializer code, we're going to need two pieces of
information from GitHub in order to get authentication working: the application
key and secret that will identify our app to GitHub.

Follow these instructions to create an OAuth app on GitHub:

- [Creating an OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app)

You'll need to enter a few settings as you're creating the app:

- **Homepage URL**: `http://localhost:3000`
- **Authorization callback URL**: `http://localhost:3000/auth/github/callback`

After clicking "Register Application", you'll be taken to a settings page for
your newly created app. Leave this page open — we'll need some info from this
page in the next step.

### `dotenv-rails`

Instead of setting environment variables directly in our local `ENV` hash, we're
going to let an awesome gem handle the hard work for us. `dotenv-rails` is one
of the best ways to ensure that environment variables are correctly loaded into
the `ENV` hash in a secure manner. Using it requires four steps:

1. Run `bundle add dotenv-rails` add the `dotenv-rails` gem to your Gemfile
2. Create a file named `.env` at the root of your application (in this case,
   inside the `omniauth_readme/` directory).
3. Add your GitHub app credentials to the newly created `.env` file
4. Add `.env` to your `.gitignore` file to ensure that you don't accidentally
   commit your precious credentials.

For step three, take the `Client ID` and generate a `Client Secret` on the
GitHub settings page, and paste them into the `.env` file as follows:

```txt
GITHUB_KEY=d739af6d68fb498fb492
GITHUB_SECRET=ac5dabbec764a22e2b79eab98425cda7b01b21ca
```

### Routing OAuth flow in your application

We now need to create a link that will initiate the GitHub OAuth process. The
standard OmniAuth path is `/auth/:provider`, so, in this case, we'll need a link
to `/auth/github`. Let's add one to `app/views/welcome/home.html.erb`:

```erb
<%= link_to('Log in with GitHub!', '/auth/github', method: :post) %>
```

Next, we're going to need a `User` model and a `SessionsController` to track
users who log in via GitHub. The `User` model should have four attributes, all
strings: `name`, `email`, `image`, and `uid` (the user's ID on GitHub).

To handle user sessions, we need to create a single route, `sessions#create`,
which is where GitHub will redirect users in the callback phase of the login
process. Add the following to `config/routes.rb`:

```ruby
get '/auth/github/callback' => 'sessions#create'
```

Our `SessionsController` will be pretty simplistic, with a lone action (and a
helper method to DRY up our code a bit):

```ruby
class SessionsController < ApplicationController
  def create
    @user =
      User.find_or_create_by(uid: auth['uid']) do |u|
        u.name = auth['info']['name']
        u.email = auth['info']['email']
        u.image = auth['info']['image']
      end

    session[:user_id] = @user.id

    render 'welcome/home'
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
```

And, finally, since we're re-rendering the `welcome#home` view upon logging in
via GitHub, let's add a control flow to display user data if the user is logged
in and the login link otherwise:

```erb
<% if session[:user_id] %>
  <h1><%= @user.name %></h1>
  <h2>Email: <%= @user.email %></h2>
  <h2>GitHub UID: <%= @user.uid %></h2>
  <img src="<%= @user.image %>">
<% else %>
  <%= link_to('Log in with GitHub!', '/auth/github', method: :post) %>
<% end %>
```

Now it's time to test it out! It's best to log out of GitHub prior to clicking
the login link — that way, you'll see the full login flow. Run `rails s` to
start the app, then navigate to [http://localhost:3000](http://localhost:3000).

When you click the link, you should be prompted log in to GitHub and then to
give the app access to your GitHub account.

If everything is working correctly, you should then see your GitHub information
displayed in the browser!

#### A man, a plan, a param, Panama

Upon clicking the link, your browser sends a `POST` request to the
`/auth/github` route, which OmniAuth intercepts and redirects to a GitHub login
screen with a ridiculously long URI:

```txt
https://github.com/login/oauth/authorize?client_id=d739af6d68fb498fb492&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauth%2Fgithub%2Fcallback&response_type=code&state=913d5b0d9c9204efea1652fc4d066605ae0bebc937fd73af
```

The URI has a ton of [encoded](http://ascii.cl/url-encoding.htm) parameters, but
we can parse through them to get an idea of what's actually being communicated.

We see our GitHub client ID, `client_id=d739af6d68fb498fb492`, and the
authorization callback url that the login flow will send us to next:
`redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauth%2Fgithub`.

#### Inspecting the returned authentication data

If you want to inspect the exact information that GitHub returns to our
application about a logged-in user, throw a `binding.pry` in the
`SessionsController#create` method and call `auth` inside the Pry session:

```txt
     2: def create
 =>  3:   binding.pry
     4:   @user =
     5:     User.find_or_create_by(uid: auth['uid']) do |u|
     6:       u.name = auth['info']['name']
     7:       u.email = auth['info']['email']
     8:       u.image = auth['info']['image']
     9:     end
    10:
[1] pry(#<SessionsController>)> auth
=> {"provider"=>"github",
 "uid"=>"39830572",
 "info"=>
  {"nickname"=>"ihollander",
   "email"=>nil,
   "name"=>"Ian Hollander",
   "image"=>"https://avatars.githubusercontent.com/u/39830572?v=4"
```

When you make a server-side API call (as we did), GitHub will provide an access
token that's good for about two months, so you don't have to bug your users very
often. That's good!

## Conclusion

Implementing the OAuth protocol yourself is extremely complicated. Using the
OmniAuth gem along with any `omniauth-provider` gem(s) streamlines the process,
allowing users to log in to your site easily. However, it still trips a lot of
people up! Make sure you understand each piece of the flow, what you expect to
happen, and any deviation from the expected result. The end result should be
gaining access to the user's data from the provider in your
`SessionsController`, where you can then decide what to do with it. Typically,
if a matching `User` exists in your database, the client will be logged in to
your application. If no match is found, a new `User` will be created using the
data received from the provider.

[ip_geolocation]: https://en.wikipedia.org/wiki/Geolocation
[ip_fingerprinting]: https://en.wikipedia.org/wiki/TCP/IP_stack_fingerprinting
[captcha]: https://en.wikipedia.org/wiki/CAPTCHA
[omniauth]: https://github.com/intridea/omniauth
[list_of_strategies]:
  https://github.com/omniauth/omniauth/wiki/List-of-Strategies
