module.exports = class Utils
    importMailAccount: =>
        #Probably will do something cool, like making possible to see magic unicorn flying in the sky.
        #Whith a magic cheese. whitout it, that would not be so awsome.

    importContacts: (callback) =>
        $.ajax
            type: "GET"
            dataType: "text"
            async: true
            url: 'contacts'
            complete: (xhr) =>
                switch xhr.status
                    when 202 then callback null
                    else callback xhr.responseText

    getImportContactStatus: (callback) ->
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: 'contactImportStatus'
            complete: (xhr) =>
                if xhr.status is 200 \
                or xhr.status is 304 \
                or xhr.status is 201
                    callback null, xhr.responseJSON
                else callback xhr.responseText