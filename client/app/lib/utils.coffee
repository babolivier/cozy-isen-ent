module.exports = class Utils
    @changepsw: (oldPassword, newPassword, callback) =>
        console.log "c: " + newPassword
        console.log "d: " + oldPassword
        $.ajax
            type: "POST"
            async: true
            url: 'changePassword'
            data:
                newpassword: newPassword
                oldpassword: oldPassword
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null
                    when 304 then callback null
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @importMailAccount: (callback) ->
        #Probably will do something cool, like making possible to see magic unicorn flying in the sky.
        #Whith a magic cheese. whitout it, that would not be so awsome.
        $.ajax
            type: "PUT"
            async: true
            url: 'email'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 304 then callback null, false
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @isMailActive: (callback) ->
        $.ajax
            type: "GET"
            async: true
            url: 'email'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 418 then callback null, false
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @isAdminContactsActive: (callback) ->
        $.ajax
            type: "GET"
            async: true
            url: 'isAdminContactsActive'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 418 then callback null, false
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @importAdminContacts: (callback) ->
        $.ajax
            type: "PUT"
            dataType: "text"
            async: true
            url: 'contactsAdmin'
            complete: (xhr) ->
                switch xhr.status
                    when 202 then callback null
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @getAdminImportContactStatus: (callback) ->
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: 'contactsAdmin'
            complete: (xhr) ->
                if xhr.status is 200 \
                or xhr.status is 304 \
                or xhr.status is 201
                    callback null, xhr.responseJSON
                else if xhr.status is 504
                    callback "Connection timed out"
                else
                    callback xhr.responseText
                    console.error xhr.responseJSON

    @isStudentsContactsActive: (callback) ->
        $.ajax
            type: "GET"
            async: true
            url: 'trombino/active'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 418 then callback null, false
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @importStudentsContacts: (callback) ->
        $.ajax
            type: "PUT"
            dataType: "text"
            async: true
            timeout: 600000
            url: 'trombino/import'
            complete: (xhr) ->
                switch xhr.status
                    when 202 then callback null
                    when 504 then callback "Connection timed out"
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    @getStudentsImportContactStatus: (callback) ->
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: 'trombino/import'
            complete: (xhr) ->
                if xhr.status is 200 \
                or xhr.status is 304 \
                or xhr.status is 201
                    callback null, xhr.responseJSON
                else if xhr.status is 504
                    callback "Connection timed out"
                else
                    callback xhr.responseText
                    console.error xhr.responseJSON

    @getStudentsImportRetrieveStatus: (callback) ->
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: 'trombino/status'
            complete: (xhr) ->
                if xhr.status is 201
                    callback null, xhr.responseJSON, true
                else if xhr.status is 200 \
                or xhr.status is 304
                    callback null, xhr.responseJSON, false
                else if xhr.status is 504
                    callback "Connection timed out"
                else
                    callback xhr.responseText
                    console.error xhr.responseJSON