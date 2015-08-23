cozydb      = require 'cozydb'
VCardParser = require 'cozy-vcard'
request     = require 'request'
conf        = require('../../conf')
notif       = require "./notif"
Login       = require './login'
printit     = require 'printit'
AbstractContactImporter = require './abstractContactImporter'

log = printit
    prefix: 'models:contact'
    date: true

class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        type: String

###
Contact: Import administrative contacts.
###
module.exports = class Contact extends AbstractContactImporter

    ###
    Name: isActive
    Role: Tell if importing administrative contacts is active or not.
    Args: void
    Rtrn: Bool
    ###
    isActive: =>
        if conf.contact
            return true
        else
            return false

    ###
    Name: createFromVCard
    Role: Parse a vcard, and import it's contacts into database.
    Args: A String representing a vcard file contents.
    Rtrn: void
    ###
    createFromVCard: (vcfString) =>
        vparser = new VCardParser vcfString.replace(/EMAIL:/g, "EMAIL;" + conf.contactParams.defaultEmailTag + ":") #Change invalid EMAIL tag and parse vcard.

        vcf = new Array # An array of parsed contacts.

        for contact in vparser.contacts
            c = new Object
            c.fn = contact.fn if contact.fn
            c.n = contact.n if contact.n
            c.datapoints = contact.datapoints if contact.datapoints
            c.tags = conf.contactParams.tag
            vcf.push c

        ####

        @total = vcf.length

        #We explore new contacts datas:
        for contact in vcf
            do (contact) =>
                for dt in contact.datapoints
                    #If contacts already exists:
                    if dt.name is "email" and @oldContacts[dt.value]
                        #If the same contact has been changed:
                        if contact.n isnt @oldContacts[dt.value].n \
                        or contact.fn isnt @oldContacts[dt.value].fn
                            oldContact = @oldContacts[dt.value].toJSON()
                            #We update it in database
                            @oldContacts[dt.value].updateAttributes
                                fn: contact.fn
                                n: contact.n
                            , (err) =>
                                if err
                                    @oldContacts[dt.value].beforeUpdate = oldContact
                                    @error.push err
                                    log.error err
                                else
                                    @modified.push contact.fn
                                @done++
                                @endImport() if @done is @total
                        #If the contact has no changes:
                        else
                            #We do nothing
                            @notmodified.push contact.fn
                            @done++
                            @endImport() if @done is @total
                    #If the contact is new:
                    else
                        #We create it
                        Contact.create contact, (err, contactCree) =>
                            if err
                                @error.push err
                                log.error err
                            else
                                @succes.push contactCree.fn
                            @done++
                            @endImport() if @done is @total
        ####

    ###
    Name: retrieveContacts
    Role: Launch the contacts import, and authentificates if nessecary.
    Args: callback(err): called with err if error, called by subfunction otherwise.
    Rtrn: void
    ###
    retrieveContacts: (callback) =>
        #Is login required?
        if conf.contactParams.clientServiceUrlForLogin
            #We do one request on the service, with a service ticket provide by Login.authRequest(...) in order to be identified.
            Login.authRequest conf.contactParams.clientServiceUrlForLogin, (err, data) =>
                if err
                    callback err
                    log.error err
                else
                    j = request.jar()
                    requ = request.defaults
                    	jar: j
                    requ.get
                        url: data
                    , (err, resp, body) =>
                        if err
                            callback err
                            log.error err
                        else
                            #We launch VCard download/import.
                            @ImportFromVCard requ, callback
        else
            # idem
            @ImportFromVCard request, callback

    ###
    Name: ImportFromVCard
    Role: Download a vcard file and starts importing it.
    Args:
        requestModule: the request module used for authentification.
        callback(err): called with err if error, called with null otherwise.
    Rtrn: void
    ###
    ImportFromVCard: (requestModule, callback) =>
        #downlod vcard
        requestModule.post
            url: conf.contactParams.vCardUrl
            form:
                conf.contactParams.vCardPostData
        , (err, resp, body) =>
            if err
                callback err
            else
                #initialisation of import
                @initImporter conf.contactParams.tag[0], 'administratif ISEN', (err) =>
                    if err
                        callback err
                        log.error err
                    else
                        #Here we respond to the client: vcard dowload is over, and we start parsing and importing it.
                        callback null
                        @createFromVCard body