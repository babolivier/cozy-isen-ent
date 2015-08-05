module.exports = class Utils
    importMailAccount: =>
        console.log "import du compte mail"

    importContacts: (callback) =>
        console.log "import des contacts"#ret un truc.status (bool) et un truc .err si err il y à.
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
                console.log xhr.responseJSON
                if xhr.status is 200 \
                or xhr.status is 304 \
                or xhr.status is 201
                    callback null, xhr.responseJSON
                else callback xhr.responseText