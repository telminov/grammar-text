createSuggestElement = (position) ->
    el = $("<div class='suggest'><ul class='choices'></ul></div>")
    el.appendTo('body')
    el.css(position)
    return el


grammarInputPrepare = (grammar) ->

    grammar.input.focus (event) ->
        grammar.clearSelection()

    grammar.input.keydown (event) ->
#        console.log 'grammar', event.keyCode

        # Left
        if event.keyCode == 37
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return
            grammar.selectLastPhrase()

        # backspace
        else if event.keyCode == 8
            # если что-то есть в поле ввода, то не реагиуем
            if grammar.input.val()
                return
            event.preventDefault()  # чтобы браузер не отлистывал на предыдущую страницу
            grammar.selectLastPhrase()



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
            if not suggest.isOpened
                suggest.open()
            else
                suggest.moveSelectedDown()

        # Up
        else if event.keyCode == 38
            if not suggest.isOpened
                suggest.open()
            else
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
                phraseItem = $("<li>#{ phrase.text }</li>")
                phraseItem.data(phrase)
                phraseItem.click (event) =>
                    this.select($(event.target).data())

                    # меняем фокус, только если клик был не по инпуту
                    tagName = $(':focus').prop('tagName')?.toLocaleLowerCase()
                    if not tagName or tagName != 'input'
                        this.input.focus()

                this.element.find('.choices').append(phraseItem)
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


PHRASE_MOVE_LEFT_EVENT = 'PHRASE_MOVE_LEFT'
PHRASE_MOVE_RIGHT_EVENT = 'PHRASE_MOVE_RIGHT'
PHRASE_REMOVE_EVENT = 'PHRASE_REMOVE'
PHRASE_SELECTED_EVENT = 'PHRASE_SELECTED'
PHRASE_DESELECTED_EVENT = 'PHRASE_DESELECTED'
PHRASE_WIDTH_CHANGED_EVENT = 'PHRASE_WIDTH_CHANGED'
PHRASE_COMPLETE_EVENT = 'PHRASE_COMPLETE'

class PhraseElement
    constructor: (@phrase, position, data) ->
        this.hasParams = this.phrase.text.indexOf('_') != -1

        contentHtml = this.phrase.text
        contentHtml = contentHtml.replace(/_/g, "<input></input>")
        this.el = $("<div tabindex='0' class='phrase'>#{ contentHtml }</div>")
        if not this.hasParams
            this.el.addClass('no-params')

        this.el.appendTo('body')
        this.el.css(position)
        this.width = this.el.outerWidth(true)

        # если есть поля ввода, то сразу фокус на них
        if this.hasParams
            this.select()

            # запоминаем инпут, на котором был фокус, чтобы потом возвращаться на него
            this.lastFocusedInput = undefined
            this.el.find('input').focus (e) =>
                this.lastFocusedInput = $(e.target)

            # проставим значения
            if data
                for input, i in this.el.find('input')
                    $(input).val(data[i])
                this._renderInputs()

        this.el.click (event) =>
            # не меняем фокус, если клик был по инпуту фразы
            targetTag = $(event.target)?.prop('tagName').toLocaleLowerCase()
            doNotChangeFocusPosition = targetTag and targetTag == 'input'

            setTimeout(
                => this.select(doNotChangeFocusPosition)
                100
            )

        this.el.keydown (event) =>
            setTimeout(
                => this._renderInputs()
                100
            )
#            console.log 'PhraseElement keydown', event.keyCode

            target = $(event.target)
            isTargetInput = target.prop('tagName').toLocaleLowerCase() == 'input'

            # Left
            if event.keyCode == 37
                processed = this.moveSelectionLeft()
                if processed
                    event.preventDefault()

            # Right
            else if event.keyCode == 39
                processed = this.moveSelectionRight()
                if processed
                    event.preventDefault()

            # Del
            else if event.keyCode == 46
                # если не пустой ввод, ничего не делаем
                if isTargetInput and target.val().length
                    return
                this.moveSelectionRight()
                this.remove()

            # backspace
            else if event.keyCode == 8
                # если не пустой ввод, ничего не делаем
                if isTargetInput and target.val().length
                    return
                event.preventDefault()  # чтобы браузер не отлистывал на предыдущую страницу
                this.moveSelectionLeft()
                this.remove()

            # enter
            else if event.keyCode == 13
                this.complete()
                event.preventDefault()


    complete: ->
        this.deselect()
        e = $.Event(PHRASE_COMPLETE_EVENT, {phraseElement: this})
        $(this).trigger(e)

    select: (doNotChangeFocusPosition) ->
        this.el.addClass('selected')
        if this.hasParams
            setInputFocus = not doNotChangeFocusPosition
            if setInputFocus
                this._setInputFocus(setInputFocus)
        else
            this.el.focus()

        e = $.Event(PHRASE_SELECTED_EVENT, {phraseElement: this})
        $(this).trigger(e)


    deselect: (noBlur)->
        this.el.removeClass('selected')

        e = $.Event(PHRASE_DESELECTED_EVENT, {phraseElement: this})
        $(this).trigger(e)

        doBlur = !noBlur
        if doBlur
            this.el.blur()

    isSelected: ->
        return this.el.hasClass('selected')

    getText: ->
        return this.phrase.text

    getWidth: ->
        return this.width

    getLeftPosition: ->
        rawLeft = this.el.css('left')
        left = Number(rawLeft.substring(0, rawLeft.length-2))
        return left

    setLeftPosition: (left) ->
        this.el.css('left', left)

    remove: ->
        this.el.remove()
        e = $.Event(PHRASE_REMOVE_EVENT, {phraseElement: this})
        $(this).trigger(e)

    moveSelectionLeft: ->
        if this.hasParams
            focusedInput = this.el.find('input:focus')

            # если мы не в начале строки строки, игнорим
            position = focusedInput.caret()
            if position > 0
                return false

            # если есть предыдущий инпут, фокус на него
            prevInput = focusedInput.prev()
            if prevInput.length
                prevInput.focus()
                return true

        this.deselect()
        e = $.Event(PHRASE_MOVE_LEFT_EVENT, {phraseElement: this})
        $(this).trigger(e)
        return true

    moveSelectionRight: ->
        if this.hasParams
            focusedInput = this.el.find('input:focus')

            # если мы не в конце строки, игнорим
            position = focusedInput.caret()
            chars = focusedInput.val().length
            if position < chars
                return false

            # если есть следующий инпут, фокус на него
            nextInput = focusedInput.next()
            if nextInput.length
                nextInput.focus()
                return true

        this.deselect()
        e = $.Event(PHRASE_MOVE_RIGHT_EVENT, {phraseElement: this})
        $(this).trigger(e)
        return true

    getInputs: ->
        return this.el.find("input")

    getData: ->
        if this.hasParams
            data = []
            for input in this.getInputs()
                data.push($(input).val())
            return data
        else
            return 1

    _setInputFocus: ->
        if this.lastFocusedInput
            this.lastFocusedInput.focus()
            return

        for input in this.getInputs()
            input = $(input)
            # фокус на первый пустой инпут
            if not input.val()
                input.focus()
                return
        # если пустых нет, то на последний
        input.focus()

    _renderInputs: ->
        for input in this.getInputs()
            input = $(input)
            # расширим поле, чтобы было видно ровно столько символов, сколько ввели
            # для этого создадим временный элемент (без этого при удалении символов scrollWidth не уменьшается)
            tmpInput = $("<input style='width:10px' value='#{ input.val() }' />").appendTo('body')
            scrollWidth = tmpInput.prop('scrollWidth')
            tmpInput.remove()
            input.width(scrollWidth)

        newWidth = this.el.outerWidth(true)
        if newWidth != this.width
            this.width = newWidth
            e = $.Event(PHRASE_WIDTH_CHANGED_EVENT, {phraseElement: this})
            $(this).trigger(e)


class @GrammarText
    constructor: (input, @phrasesUrl) ->
        this.input = $(input)
        this.originalInputLeftPadding = getLeftPadding(this.input)

        this.phrases = []
        this.suggestPhrases = []
        this.selectedPhrases = []

        this.suggest = new Suggest(this.input, this.suggestPhrases)
        this.suggest.addSelectHandler((phrase) => this.renderPhrase(phrase))

        this.phraseElements = []
        grammarInputPrepare(this)

        # скрытый инпут со значением, передаваемым на сервер
        inputName = this.input.prop('name')
        this.input.removeProp('name')
        this.valueInput = $("<input type='hidden' name='#{ inputName }' />")
        this.valueInput.insertAfter(this.input)

        # отрисуем если есть значение для поля
        dataJSON = this.input.val()
        if dataJSON
            this.input.val('')
            this.valueInput.val(dataJSON)
            data = JSON.parse(dataJSON)
            for phraseText, phraseData of data
                phrase = {'text': phraseText}
                this.renderPhrase(phrase, phraseData)

        this.input.parents().find('form').submit =>
            this.refreshInputValue()

    getData: ->
        data = {}
        for phraseElement in this.phraseElements
            data[phraseElement.getText()] = phraseElement.getData()
        return data

    loadPhrases: ->
        $.get this.phrasesUrl, (result) =>
            for phrase in result
                this.phrases.push(phrase)
            this.refreshSuggestPhrases()

    clearSelection: ->
        for phraseElement in this.phraseElements
            phraseElement.deselect()

    renderPhrase: (phrase, data) ->
        # положение поля ввода
        position = this.input.offset()
        inputPadding = getLeftPadding(this.input)
        position.left += inputPadding
        position.top -= 4

        # нарисуем поверх него фразу
        phraseElement = new PhraseElement(phrase, position, data)
        $(phraseElement).bind(PHRASE_MOVE_LEFT_EVENT, (e) => this.moveLeftHandler(e))
        $(phraseElement).bind(PHRASE_MOVE_RIGHT_EVENT, (e) => this.moveRightHandler(e))
        $(phraseElement).bind(PHRASE_COMPLETE_EVENT, (e) => this.moveRightHandler(e))
        $(phraseElement).bind(PHRASE_REMOVE_EVENT, (e) => this.removePhraseHandler(e))
        $(phraseElement).bind(PHRASE_SELECTED_EVENT, (e) => this.selectPhraseHandler(e))
        $(phraseElement).bind(PHRASE_WIDTH_CHANGED_EVENT, (e) => this.widthChangedHandler())
        $(phraseElement).bind(PHRASE_DESELECTED_EVENT, (e) => this.deselectHandler(e))
        this.phraseElements.push(phraseElement)

        # подвинем текс в input'е
        this.refreshInputLeftPadding()

        # сохраним отрисованную фразу
        this.selectedPhrases.push(phrase)

        # удалим из списка доступных для автокомплита фразу
        this.refreshSuggestPhrases()

    getSelectedPhraseElement: ->
        for phraseElement in this.phraseElements
            if phraseElement.isSelected()
                return phraseElement

    getSelectedPhraseIndex: ->
        selectedPhraseElement = this.getSelectedPhraseElement()

        if not selectedPhraseElement
            return

        index = this.phraseElements.indexOf(selectedPhraseElement)
        if index == -1
            return

        return index

    getPhraseIndex: (phrase) ->
        selectedIndex = undefined
        for phraseElement, i in this.phraseElements
            if phrase.text == phraseElement.getText()
                selectedIndex = i
                break
        return selectedIndex

    selectLastPhrase: ->
        if not this.phraseElements.length
            return
        lastPhraseElement = this.phraseElements[this.phraseElements.length-1]
        lastPhraseElement.select()

    selectPhraseByIndex: (index) ->
        if not this.phraseElements.length
            return
        phraseElement = this.phraseElements[index]
        phraseElement.select()

    refreshInputLeftPadding: ->
        padding = this.originalInputLeftPadding
        for phraseElement in this.phraseElements
            padding += phraseElement.getWidth()
        this.input.css('padding-left', padding)

    refreshSuggestPhrases: ->
        this.suggestPhrases.length = 0
        for phrase in this.phrases
            selected = false
            for selectedPhrase in this.selectedPhrases
                if selectedPhrase.text == phrase.text
                    selected = true
            if not selected
                this.suggestPhrases.push(phrase)

    refreshInputValue: ->
        data = this.getData()
        dataJSON = JSON.stringify(data)
        this.valueInput.val(dataJSON)


    moveLeftHandler: (e) ->
        phrase = e.phraseElement.phrase
        phraseIndex = this.getPhraseIndex(phrase)

        nextIndex = phraseIndex - 1
        if nextIndex < 0
            nextIndex = 0

        nextPhraseElement = this.phraseElements[nextIndex]
        nextPhraseElement.select()

    moveRightHandler: (e) ->
        phrase = e.phraseElement.phrase
        phraseIndex = this.getPhraseIndex(phrase)

        nextIndex = phraseIndex + 1
        lastIndex = this.phraseElements.length - 1

        if nextIndex <= lastIndex
            nextPhraseElement = this.phraseElements[nextIndex]
            nextPhraseElement.select()
        else
            this.input.focus()


    removePhraseHandler: (e) ->
        phraseElement = e.phraseElement

        deleteIndex = this.getPhraseIndex(phraseElement.phrase)
        this.phraseElements.splice(deleteIndex, 1)

        # уменьшим сдвиг поля ввода
        phrasePadding = phraseElement.getWidth()
        this.refreshInputLeftPadding()

        # подвинем другие фразы
        for el in this.phraseElements.slice(deleteIndex)
            left = el.getLeftPosition() - phrasePadding
            el.setLeftPosition(left)

        # удалим фразу из выбранных
        _.remove(this.selectedPhrases, {text: phraseElement.getText()})

        this.refreshSuggestPhrases()
        this.suggest.refresh()

        if not this.phraseElements.length
            this.input.focus()

    selectPhraseHandler: (e) ->
        selectedPhraseElement = e.phraseElement
        for phraseElement in this.phraseElements
            if phraseElement.phrase.text != selectedPhraseElement.phrase.text
                phraseElement.deselect()

    widthChangedHandler: (e) ->
        this.refreshInputLeftPadding()

        if this.phraseElements.length
            left = this.phraseElements[0].getLeftPosition()
            for phraseElement in this.phraseElements
                phraseElement.setLeftPosition(left)
                left += phraseElement.getWidth()

    deselectHandler: (e) ->
        this.refreshInputValue()