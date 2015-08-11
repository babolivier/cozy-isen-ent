module.exports = class Utils
    importMailAccount: (credentials, callback) ->
        #Probably will do something cool, like making possible to see magic unicorn flying in the sky.
        #Whith a magic cheese. whitout it, that would not be so awsome.
        $.ajax
            type: "PUT"
            async: false
            url: 'email'
            data:
                username: credentials.username
                password: credentials.password
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 304 then callback null, false
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    isMailActive: (callback) ->
        $.ajax
            type: "GET"
            async: false
            url: 'email'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 418 then callback null, false
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    isContactsActive: (callback) ->
        $.ajax
            type: "GET"
            async: false
            url: 'isContactsActive'
            complete: (xhr) ->
                switch xhr.status
                    when 200 then callback null, true
                    when 418 then callback null, false
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    importContacts: (callback) ->
        $.ajax
            type: "GET"
            dataType: "text"
            async: true
            url: 'contacts'
            complete: (xhr) ->
                switch xhr.status
                    when 202 then callback null
                    else
                        callback xhr.responseText
                        console.error xhr.responseJSON

    getImportContactStatus: (callback) ->
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: 'contactImportStatus'
            complete: (xhr) ->
                if xhr.status is 200 \
                or xhr.status is 304 \
                or xhr.status is 201
                    callback null, xhr.responseJSON
                else
                    callback xhr.responseText
                    console.error xhr.responseJSON