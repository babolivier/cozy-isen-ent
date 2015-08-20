printit     = require 'printit'
Trombino    = require '../models/trombino'
Trombino    = new Trombino

log = printit
    prefix: 'controllers:trombino'
    date: true

module.exports.startImportStudentsContacts = (req, res, next) ->
    Trombino.startImport (err) ->
        if err
            log.error err
            console.error err
            res.status(500).json error: err
        else
            res.status(202).json status: true

module.exports.getImportStatus = (req, res, next) ->
    status = Trombino.getImportStatus()
    if status.done is status.total
        res.status(201).json status
    else
        res.status(200).json status

module.exports.isActive = (req, res, next) ->
    if Trombino.isActive()
        res.status(200).json active: true
    else
        res.status(418).json active: false
