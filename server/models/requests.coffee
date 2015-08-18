cozydb = require 'cozydb'

module.exports =
    login:
        all: cozydb.defaultRequests.all

    account:
        all: cozydb.defaultRequests.all

    contact:
        all: cozydb.defaultRequests.all

    mailbox:
        all: cozydb.defaultRequests.all
        treeMap: (doc) ->
            emit [doc.accountID].concat(doc.tree), null