cozydb = require 'cozydb'

module.exports =
    login:
        all: cozydb.defaultRequests.all
    account:
        all: cozydb.defaultRequests.all
    konnector:
        all: cozydb.defaultRequests.all