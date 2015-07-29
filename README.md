# Description

This app allows you to integrate an iframe in your Cozy to your application
cluster while managing an authentication with CAS (Central Authentication
Service). It's a single sign-in: You only have to enter your credentials once,
and you'll be logged in forever (as long as don't click the "Disconnect" button
within the app).

It has been specifically designed to work with the ENT (Espace Numérique de
Travail, which would translate as Virtual Workspace) of the engineering school
ISEN Brest, but can be reused in order to work with almost any application
cluster using a CAS server. You'll just have a couple of files to edit in order
to add your own services (CAS clients).

The app is entirely in French up to now, but we plan on translating it in the
future.

# Configuration

To change configuration, you will have to edit two files:

* `conf.coffee`: determines which configuration file to load.
* `conf.prod.json`: contains the configuration itself.

## conf.coffee

Very simple to edit: in `module.exports = require './conf.test.json'`,
replace `conf.test.json` with your custom configuration file's path.

## conf.prod.json (or anything like foobar.json)

This file should looks like this:

```
{
    "casUrl":"",
    "defaultService": "",
    "servicesList":[
      {
          "displayName": String,
          "serverServiceUrl": String,
          "clientIcon": String,
          "clientServiceUrl": String,
          "clientRedirectTimeOut": Number,
          "clientRedirectPage": String
      }
    ],
    "mail": Boolean,
    "contact": Boolean
}
```

### Global configuration

* `casUrl`: the url of your CAS server.
* `defaultService`: the service which will be loaded by default. (Must correspond to the `clientServiceUrl` field of your service, see bellow.)
* `servicesList`: an array filled by your services.

### Services configuration

* `displayName`: the name that will be displayed to app users.
* `serverServiceUrl`: the service url homepage, where the ST (Service ticket) will be transmitted.
* `clientIcon`: the icon that will be displayed to app users. (Allowed values: see [Font-Awesome](http://fortawesome.github.io/Font-Awesome/icons/))
* `clientServiceUrl`: a string which will be used by the client browser to tell the cozy app which service the user want to see.
* `clientRedirectPage`: (optional) if you want the client be redirected after loged in, insert the url here.
* `clientRedirectTimeOut`: (optional) a numer in milliseconds, which determines the waiting time before redirecting the client to the `clientRedirectPage`. If no specified, the client will be redirected when the `serverServiceUrl` page has been loaded (using onload js event).<br>
**/!\ When using a timer, the reload does not begin at the onload js event, but during the global page loading.**
* `clientLogoutUrl`: (optional) If specified, the client web browser will load (on logout) an invisible iframe on this url, in order to perform a client logout (when all logout iframes has been loaded, or after 5 sec, the client will be redirected to the login page).

### E-mail configuration

If your CAS applications cluster includes IMAP mailboxes for your users, you can make it so your users will have their email account added to their Cozy when they authentificate via the app. You can also disable this feature at any time.

The `mail` line on the configuration file expects a boolean as its value. It obviously behaves on a different way according to its value:

* When set to `true`, it'll enable the feature, but also expect a `mailParams` object (described below)
* When set to `false`, it'll disable the feature. The app won't run the necessary procedures for the addition of an email account. It also doesn't require the `mailParams` object, but won't yell at you if you let it there.

The schema of the `mailParams` object looks like this:

```
"mailParams": {
    "viaKonnector": Boolean,
    "konnectorSlug": String,
    "domain": String,
    "label": String,
    "smtpServer": String,
    "smtpPort": Number,
    "smtpSSL": Boolean,
    "smtpTLS": Boolean,
    "smtpMethod": String,
    "imapServer": String,
    "imapPort": Number,
    "imapSSL": Boolean,
    "imapTLS": Boolean
}
```

Here's a quick description of each member. Please note that there's a difference between the user's e-mail address and its IMAP/SMTP credentials. The e-mail addresses mentioned here are what the recipient of one of your user's e-mail will see as its sender, while the IMAP/SMTP credentials must be the same as the user's CAS credentials.

* `viaKonnector`: If your organization uses a konnector in the "Konnectors" Cozy app to store your user's e-mail addresses, you can set this boolean to true. The e-mail must be stored in the `fieldValues` object of the konnector, with `email` as its key.
* `konnectorSlug`: If `viaKonnector` is set to `true`, the app will look for the e-mail address in the konnector with this value as its `slug`.
* `domain`: The domain of your e-mail addresses. If the app can't find the konnector, or if you set `viaKonnector` to `false`, an address will be constructed as `[CAS username]@[domain]`.
* `label`: The name the "Emails" Cozy app will give to the e-mail account once created
* `smtpServer`: The FQDN (Full Qualified Domain Name) of your SMTP server
* `smtpPort`: The port your SMTP server is listening on
* `smtpSSL`: Set to `true` if your SMTP server uses SSL, and to `false` if it doesn't
* `smtpTLS`: Set to `true` if your SMTP server uses TLS, and to `false` if it doesn't
* `smtpMethod`: The auth method of your SMTP server (usually `"LOGIN"`)
* `imapServer`: The FQDN of your IMAP server
* `imapPort`: The port your IMAP server is listening on
* `imapSSL`: Set to `true` if your IMAP server uses SSL, and to `false` if it doesn't
* `imapTLS`: Set to `true` if your IMAP server uses TLS, and to `false` if it doesn't

### Contact configuration

If your organization has a way to obtain contacts through a vCard file, you may want to allow you app's users to import easily those contacts.

Ready? So begin by changing  `contact": false` to `contact": true`. Then add a `"contactParams": {}` element. It should look like this:

```
"contactParams": {
    "clientServiceUrlForLogin": String,
    "vCardUrl": String,
    "vCardPostData": JSON,
    "defaultEmailTag": String,
    "tag": String []
}
```

* `clientServiceUrlForLogin`: (optional) If CAS loging is required to grant access for the vCard file, insert here the `clientServiceUrl` that will be used to determine the service which grant vCard access. (the `clientServiceUrl` must match one of `clientServiceUrl` listed in services configuration.)
* `vCardUrl`: the url where to dowload the vCard file. (Note that the app will do a POST request, not GET. This can't be configured for the moment, but we planed to do so.)
* `vCardPostData`: data to transmit within the POST request.
Examples:
```
"vCardPostData": {
    "param1": value1,
    "param2": value2
}
```
**/!\ If you don't need to transmit POST data, don't omit this field, just insert it empty, like this:** `vCardPostData": {}`
* `defaultEmailTag`: There are two way to describe email in a vCard file:
    * `EMAIL:foo@bar.org`
    * `EMAIL;TYPE:foo@bar.org` where `TYPE` is an email type, such as personal, work, company name...
If your vCard do not has `TYPE` specified, the `defaultEmailTag` will be used instead.
**/!\ Must be none empty!**
* `tag` : an array of String, that will be used to tag imported contacts.

# Run and build

You can install this app on your Cozy by entering the address of this repository
in the field at the bottom of your Cozy's app store.

If you want to run the app outside of Cozy (as a fork, for instance), clone this
repository, install dependencies and run server (it requires Node.js and Coffee-script)

    npm install -g coffee-script
    git clone git://github.com/babolivier/cozy-isen-ent.git
    cd cozy-isen-ent
    npm install
    coffee server.coffee

If you want to build the application, be sure client side dependencies are installed

    cd client && npm install

And then, whenever you want to build your application:

    cake build

Check the `Cakefile` for more information.

# Feedback

If you need to contact us for any feedback related to this application, please do so at <brendan@cozycloud.cc> and/or <joseph.caillet@cozycloud.cc>.

# What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you. You install only the applications you want. You can build your
own one too.

## Community

You can reach the Cozy community via various support:

* IRC #cozycloud on irc.freenode.net
* Post on our [Forum](https://groups.google.com/forum/?fromgroups#!forum/cozy-cloud)
* Post issues on the [Github repos](https://github.com/mycozycloud/)
* Via [Twitter](http://twitter.com/mycozycloud)
