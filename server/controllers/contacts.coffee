printit = require 'printit'
Contact = require '../models/contact'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.getContacts = (req, res, next) ->
    Contact.retrieveContacts (err) ->
        if err
            log.error err
            res.status(500).json error: err
        else
            res.status(202).json status: true

module.exports.getImportStatus = (req, res, next) ->
    status = Contact.getImportStatus()
    if status.done is status.total
        res.status(200).json status
    else
        res.status(102).json status