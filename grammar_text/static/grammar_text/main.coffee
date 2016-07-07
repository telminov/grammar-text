createPhraseElement = (phrase, position) ->
    el = $("<div class='phrase'>#{ phrase.text }</div>")
    el.appendTo('body')
    el.css(position)
    return el

window.GrammarText = (input, phrasesUrl) ->
    this.input = $(input)
    this.phrasesUrl = phrasesUrl
    this.phrases = []
    return this

window.GrammarText.prototype.loadPhrases = ->
    $.get this.phrasesUrl, (result) =>
        for phrase in result
            this.phrases.push(phrase)

window.GrammarText.prototype.renderPhrase = (phrase) ->
    position = this.input.offset()

    # нарисуем фразу
    phraseElement = createPhraseElement(phrase, position)

    # подвинем input
    rowInputPadding = this.input.css('padding-left')
    inputPadding = Number(rowInputPadding.substring(0, rowInputPadding.length-2))   # избавимся от "px" в конце
    phrasePadding = phraseElement.outerWidth(true)
    newInputPadding = inputPadding + phrasePadding
    this.input.css('padding-left', newInputPadding)