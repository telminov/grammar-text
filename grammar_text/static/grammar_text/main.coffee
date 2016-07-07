createPhraseElement = (phrase, position) ->
    el = $("<div class='phrase'>#{ phrase.text }</div>")
    el.appendTo('body')
    el.css(position)
    return el

createSuggestElement = (position) ->
    el = $("<div class='suggest'><ul class='choices'></ul></div>")
    el.appendTo('body')
    el.css(position)
    return el



Suggest = (input, phrases) ->
    this.input = $(input)
    this.phrases = phrases
    this.isOpened= false

Suggest.prototype.open = ->
    this.isOpened = true

    position = this.input.offset()
    this.element = createSuggestElement(position)

    inputHeight = this.input.outerHeight()
    this.element.css('margin-top', inputHeight)

    inputWidth = this.input.outerWidth()
    this.element.css('width', inputWidth)

    this.refresh()

Suggest.prototype.refresh = ->
    if not this.isOpened
        return

    for phrase in this.phrases
        this.element.find('.choices').append("<li>#{ phrase.text }</li>")

    this.element.find('.choices li').first().addClass('selected')



window.GrammarText = (input, phrasesUrl) ->
    this.input = $(input)
    this.phrasesUrl = phrasesUrl
    this.phrases = []

    this.suggest = new Suggest(this.input, this.phrases)
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

