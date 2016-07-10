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


grammarInputPrepare = (grammar) ->

    grammar.input.keydown (event) ->
        console.log 'grammar', event.keyCode

        # backspace
        if event.keyCode == 8
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return

            selectedPhraseElement = grammar.getSelectedPhraseElement()
            if selectedPhraseElement
                grammar.removePhrase(selectedPhraseElement)
            else
                grammar.selectLastPhrase()

        # Del
        else if event.keyCode == 46
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return

            selectedPhraseElement = grammar.getSelectedPhraseElement()
            if selectedPhraseElement
                grammar.removePhrase(selectedPhraseElement)


        # Left
        else if event.keyCode == 37
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return

            grammar.moveSelectionLeft()

        # Right
        else if event.keyCode == 39
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return

            grammar.moveSelectionRight()


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
            200     # 200 мс достаточно чтобы успел отработать клик мыши
        )

    suggest.input.keydown (event) ->
#        console.log 'suggest', event.keyCode

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

        else
            setTimeout(
                -> suggest.refresh()
                10
            )



getLeftPadding = (input) ->
    rawInputPadding = input.css('padding-left')
    inputPadding = Number(rawInputPadding.substring(0, rawInputPadding.length-2))   # избавимся от "px" в конце
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

        # отфильтруем фразы по введенному тексту в инпут
        phrases = []
        for phrase in this.phrases
            filterText = this.input.val().toLowerCase()
            phraseText = phrase.text.toLowerCase()
            if phraseText.indexOf(filterText) == 0
                phrases.push(phrase)

        if phrases.length
            # отрисуем фразы
            for phrase in phrases
                phraseElement = $("<li>#{ phrase.text }</li>")
                phraseElement.data(phrase)
                phraseElement.click (event) =>
                    this.select($(event.target).data())
                    this.input.focus()
                this.element.find('.choices').append(phraseElement)
            # выберем первый элемент
            this.element.find('.choices li').first().addClass('selected')
        else
            this.element.append('<div class="no-items">Нет элементов для выбора...</div>')

    addSelectHandler: (handler) ->
        this.selectHandlers.push(handler)

    select: (phrase) ->
        for handler in this.selectHandlers
            handler(phrase)

        this.input.val('')
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

        this.phraseElements = []
        grammarInputPrepare(this)

    loadPhrases: ->
        $.get this.phrasesUrl, (result) =>
            for phrase in result
                this.phrases.push(phrase)
            this.refreshSuggestPhrases()

    clearSelection: ->
        for phraseElement in this.phraseElements
            phraseElement.removeClass('selected')

    renderPhrase: (phrase) ->
        this.clearSelection()

        # положение поля ввода
        position = this.input.offset()
        inputPadding = getLeftPadding(this.input)
        position.left += inputPadding

        # нарисуем поверх него фразу
        phraseElement = createPhraseElement(phrase, position)
        this.phraseElements.push(phraseElement)

        # подвинем текс в input'е
        inputPadding = getLeftPadding(this.input)
        phrasePadding = phraseElement.outerWidth(true)
        newInputPadding = inputPadding + phrasePadding
        this.input.css('padding-left', newInputPadding)

        # сохраним отрисованную фразу
        this.selectedPhrases.push(phrase)

        # удалим из списка доступных для автокомплита фразу
        this.refreshSuggestPhrases()

        this.selectLastPhrase()

    getSelectedPhraseElement: ->
        for phraseElement in this.phraseElements
            if phraseElement.hasClass('selected')
                return phraseElement

    getSelectedPhraseIndex: ->
        selectedPhraseElement = this.getSelectedPhraseElement()

        if not selectedPhraseElement
            return

        index = this.phraseElements.indexOf(selectedPhraseElement)
        if index == -1
            return

        return index

    removePhrase: (phraseElement) ->
        deleteIndex = undefined
        for el, i in this.phraseElements
            if el.text() == phraseElement.text()
                deleteIndex = i
                break
        if deleteIndex == undefined
            return

        this.phraseElements.splice(deleteIndex, 1)

        # уменьшим сдвиг поля ввода
        phrasePadding = phraseElement.outerWidth(true)
        inputPadding = getLeftPadding(this.input)
        newInputPadding = inputPadding - phrasePadding
        this.input.css('padding-left', newInputPadding)

        # подвинем другие фразы
        for el in this.phraseElements.slice(deleteIndex)
#            console.log deleteIndex, el.text(), el.css('left')
            rawLeft = el.css('left')
            left = Number(rawLeft.substring(0, rawLeft.length-2)) - phrasePadding
            el.css('left', left)

        # удалим фразу из выбранных
        _.remove(this.selectedPhrases, {text: phraseElement.text()})

        phraseElement.remove()

        this.refreshSuggestPhrases()
        this.suggest.refresh()

        # поставим выделение на друзую фразу
        if deleteIndex > 0
            selectedIndex = deleteIndex-1
        else
            selectedIndex = 0
#        console.log this.phraseElements
        this.selectPhraseByIndex(selectedIndex)


    selectLastPhrase: ->
        if not this.phraseElements.length
            return
        lastPhraseElement = this.phraseElements[this.phraseElements.length-1]
        lastPhraseElement.addClass('selected')

    selectPhraseByIndex: (index) ->
        if not this.phraseElements.length
            return
        phraseElement = this.phraseElements[index]
        phraseElement.addClass('selected')

    moveSelectionLeft: ->
        index = this.getSelectedPhraseIndex()

        if index > 0
            index -= 1
        else
            index = 0

        this.clearSelection()
        this.selectPhraseByIndex(index)

    moveSelectionRight: ->
        lastIndex = this.phraseElements.length - 1
        index = this.getSelectedPhraseIndex()

        if index < lastIndex
            index += 1
        else
            index = lastIndex

        this.clearSelection()
        this.selectPhraseByIndex(index)

    refreshSuggestPhrases: ->
        this.suggestPhrases.length = 0
        for phrase in this.phrases
            selected = false
            for selectedPhrase in this.selectedPhrases
                if selectedPhrase.text == phrase.text
                    selected = true
            if not selected
                this.suggestPhrases.push(phrase)


