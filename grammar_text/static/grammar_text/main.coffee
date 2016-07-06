phrases = []

window.grammarLoadPhrases = (url) ->
    $.get url, (result) ->
        for phrase in result
            phrases.push(phrase)

window.grammarGetPhrases = ->
    return phrases