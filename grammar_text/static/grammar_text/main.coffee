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


suggestInputPrepare = (suggest) ->
    suggest.input.attr('autocomplete', 'off');

    suggest.input.focus ->
        suggest.open()

    suggest.input.focusout ->
        # с задержкой, чтобы мог отработать клик по списку вариантов (при этом фокус с элемента ввода уходит)
        setTimeout(
            ->
                if not suggest.input.is(':focus')
                    suggest.close()
            100
        )

    suggest.input.keydown (event) ->
        # Enter
        if event.keyCode == 13
            event.preventDefault()
            suggest.useSelected()

        # Esc
        else if event.keyCode == 27
            suggest.close()

        # Down
        else if event.keyCode == 40
            suggest.open()
            suggest.moveSelectedDown()

        # Up
        else if event.keyCode == 38
            suggest.open()
            suggest.moveSelectedUp()


getLeftPadding = (input) ->
    rowInputPadding = input.css('padding-left')
    inputPadding = Number(rowInputPadding.substring(0, rowInputPadding.length-2))   # избавимся от "px" в конце
    return inputPadding


class Suggest
    constructor: (@input, @phrases) ->
        this.selectHandlers = []
        this.isOpened= false
        suggestInputPrepare(this)

    open: ->
        if this.isOpened
            return

        this.isOpened = true

        position = this.input.offset()
        this.element = createSuggestElement(position)

        inputHeight = this.input.outerHeight()
        this.element.css('margin-top', inputHeight)

        inputWidth = this.input.outerWidth()
        this.element.css('width', inputWidth)

        this.refresh()

    close: ->
        if not this.isOpened
            return

        this.isOpened = false
        this.element.remove()


    refresh: ->
        if not this.isOpened
            return

        this.element.find('.choices li, .no-items').remove()

        if this.phrases.length
            for phrase in this.phrases
                phraseElement = $("<li>#{ phrase.text }</li>")
                phraseElement.data(phrase)
                phraseElement.click (event) =>
                    this.select($(event.target).data())
                    this.input.focus()
                this.element.find('.choices').append(phraseElement)
        else
            this.element.append('<div class="no-items">Нет элементов для выбора...</div>')

    addSelectHandler: (handler) ->
        this.selectHandlers.push(handler)

    select: (phrase) ->
        for handler in this.selectHandlers
            handler(phrase)

        this.refresh()

    useSelected: ->
        selectedElement = this.element.find('.choices li.selected')
        if not selectedElement.length
            return

        phrase = selectedElement.data()
        this.select(phrase)

    moveSelectedDown: ->
        nextElement = $('.choices li.selected').next()
        if not nextElement.length
            nextElement = this.element.find('.choices li').first()

        this.element.find('.choices li').removeClass('selected')
        nextElement.addClass('selected')

    moveSelectedUp: ->
        prevElement = $('.choices li.selected').prev()
        if not prevElement.length
            prevElement = this.element.find('.choices li').last()

        this.element.find('.choices li').removeClass('selected')
        prevElement.addClass('selected')


class @GrammarText
    constructor: (input, @phrasesUrl) ->
        this.input = $(input)
        this.phrases = []
        this.suggestPhrases = []
        this.selectedPhrases = []
        this.suggest = new Suggest(this.input, this.suggestPhrases)
        this.suggest.addSelectHandler((phrase) => this.renderPhrase(phrase))

    loadPhrases: ->
        $.get this.phrasesUrl, (result) =>
            # все фразы
            for phrase in result
                this.phrases.push(phrase)

            # еще не выбранные
            for phrase in this.phrases
                if _.indexOf(this.selectedPhrases, {text: phrase.text}) == -1
                    this.suggestPhrases.push(phrase)

    renderPhrase: (phrase) ->
        position = this.input.offset()
        inputPadding = getLeftPadding(this.input)
        position.left += inputPadding

        # нарисуем фразу
        phraseElement = createPhraseElement(phrase, position)

        # подвинем input
        inputPadding = getLeftPadding(this.input)
        phrasePadding = phraseElement.outerWidth(true)
        newInputPadding = inputPadding + phrasePadding
        this.input.css('padding-left', newInputPadding)

        this.selectedPhrases.push(phrase)
        _.remove(this.suggestPhrases, {text: phrase.text})


