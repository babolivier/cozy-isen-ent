# Description

This app allows you to integrate an iframe in your Cozy to your application
cluster while managing an authentication with CAS (Central Authentication
Service). It's a single sign-in: You only have to enter your credentials once,
and you'll be logged in forever (as long as don't click the "Disconnect" button
within the app).

It has been specifically designed to work with the ENT (Espace Numérique de
Travail, which would translate in Virtual Workspace) of the engineering school
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
        "displayName": "",
        "clientIcon": "",
        "clientServiceUrl": "",
        "serverServiceUrl": ""
      }
    ]
}
```

### Global configuration

* `casUrl`: the url of your CAS server.
* `defaultService`: the service which will be loaded by default. (Must correspond to the `clientServiceUrl` field of your service, see bellow.)
* `servicesList`: an array filled by your services.

### Services configuration

* `displayName`: the name that will be displayed to app users.
* `clientIcon`: the icon that will be displayed to app users. (Allowed values: see [Font-Awesome](http://fortawesome.github.io/Font-Awesome/icons/))
* `clientServiceUrl`: a string which will be used by the client browser to tell the cozy app which service the user want to see.
* `serverServiceUrl` the service url homepage, where the ST (Service ticket) will be transmitted.

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
