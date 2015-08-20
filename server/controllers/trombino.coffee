printit = require 'printit'
Trombino = require '../models/trombino'
trombi  = require '../../trombino.json'

log = printit
    prefix: 'controllers:trombino'
    date: true

module.exports.getList = (req, res, next) ->
    Trombino.getList req.params.cycle, (err, results) ->
        if err
            log.error err
            console.error err
            res.status(500).send err
        else
            res.send results

module.exports.getCycles = (req, res, next) ->
    Trombino.getCycles (err, cycles) ->
        if err
            log.error err
            console.error err
            res.status(500).send err
        else
            res.send cycles

module.exports.getAll = (req, res, next) ->
    Trombino.getAll (err, results) ->
        if err
            log.error err
            console.error err
            res.status(500).send err
        else
            res.send results

module.exports.rearrange = (req, res, next) ->
    Trombino.import(trombi)
