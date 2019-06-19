###
// ==UserScript==
// @name              Trello - Thenow Trello Extend
// @namespace         http://ejiasoft.com/
// @version           1.1.7
// @description       Extend trello.com
@description:zh-CN Extend the functionality of trello.com kanban
// @homepageurl       https://github.com/thenow/ThenowTrelloExtend
// @author            thenow
// @run-at            document-end
// @license MIT license
// @match             http*://*trello.com
// @match             http*://*trello.com/*
// @grant             none
// ==/UserScript==
###

pageRegex = # required regular expression
    CardLimit:/\[\d+\]/ # card number limit
    Category : /\{.+\}/g # Categories
    User : /`\S+`/g # User
    CardCount: /^\d+/ # Current number of cards
    Number : /\d+/ # General number
    CardNum : /^#\d+/ # card number
    HomePage : /com[\/]$/ # Home
    BoardId : /\/b\/.{8}\/-$/ # Kanban page

curUrl = window.location.href # current page address
boardId = pageRegex.BoardId.exec curUrl # Current Kanban ID

cardLabelCss = """
<style type="text/css">
    .card-short-id {
        display: inline;
        font-weight: bold;
    }
    .card-short-id:after {
        content:" ";
    }
    .column-list{padding:5px 15px 10px;}
    .column-list li{height:30px;width:100%;display:block;}
    .column-list li a{display:block;height:100%;line-height:30px;position:relative;}
    .column-list li a:before{font-family: trellicons;content:"\\e910";display:block;position:absolute;right:5px;top:2px;color:#333;}
    .column-list li a.false:before{content:"-";color:#DDD;}
    .card-label.mod-card-front {
        width: auto;
        height: 12px;
        line-height: 12px;
        font-size: 12px;
        text-shadow: none;
        padding: 3px 6px;
        font-family: Microsoft Yahei;
        font-weight: 400;
    }
    .list-card-title .card-short-id {
        display: inline;
        margin-right: 4px;
        color: #0079bf;
    }
    .list .list-header-num-cards {
        display: block;
        font-size: 12px;
        line-height: 18px;
    }
</style>"""

#卡标题Format
listCardFormat = (objCard) -> 
    listCardTitle = objCard.find('div.list-card-details>a.list-card-title').each ->
        curCardTitle = $ this
        cardTitle = curCardTitle.html() # Get the card title HTML content
        cardUserArray = cardTitle.match pageRegex.User # Match related person tags
        cardCategoryArray = cardTitle.match pageRegex.Category # Matching classification tags
        if cardUserArray != null
            for cardUser in cardUserArray
                cardTitle = cardTitle.replace cardUser,"<code>#{cardUser.substring 1,cardUser.length-1}</code>"
                curCardTitle.html cardTitle
        if cardCategoryArray != null
            for cardCate in cardCategoryArray 
                cardTitle = cardTitle.replace cardCate,"<code style=\"color:#0f9598\">#{cardCate.substring 1,cardCate.length-1}</code>"
                curCardTitle.html cardTitle

# Work in process restriction
listTitleFormat = (objList) -> 
    curListHeader = objList.find 'div.list-header' # Current list object
    curListTitle = curListHeader.find('textarea.list-header-name').val() # current list name
    cardLimitInfo = pageRegex.CardLimit.exec curListTitle
    return false if cardLimitInfo == null
    curCardCountP = curListHeader.find 'p.list-header-num-cards'
    cardCount = pageRegex.CardCount.exec(curCardCountP.text())[0]
    cardLimit = pageRegex.Number.exec(cardLimitInfo[0])[0]
    if cardCount > cardLimit
        objList.css 'background','#903'
    else if cardCount == cardLimit
        objList.css 'background','#c93'
    else
        objList.css 'background','#e2e4e6'

listToggle = (objList) ->
    return if objList.find('.toggleBtn').length > 0
    listMenu = objList.find 'div.list-header-extras' # current list object
    toggleBtn = $ '<a class="toggleBtn list-header-extras-menu dark-hover"><span class="icon-sm">隐</span></a>'
    toggleBtn.click ->
        base = objList.parent()
        if base.width() == 30
            base.css 'width',''
        else 
            base.width 30
        objList.find('.js-open-list-menu').toggle()
        objList.find('div.list-cards').toggle()
        objList.find('.open-card-composer').toggle()
    listMenu.append toggleBtn

listFormatInit = ->
    $('div.list').each ->
        listTitleFormat $(this)
        listToggle $(this)
        $(this).find('div.list-card').each ->
            listCardFormat $(this)
            
btnClass = 'board-header-btn board-header-btn-org-name board-header-btn-without-icon'
btnTextClass = 'board-header-btn-text'
addBoardBtn = (id, text, eventAction, eventName='click')-> # Add button
    return $ "##{id}" if $("##{id}").length >0
    newBtn = $ "<a id=\"#{id}\" class=\"#{btnClass}\"><span class=\"#{btnTextClass}\">#{text}</span></a>" # 按钮对象
    $('div.board-header').append newBtn # Add button
    newBtn.bind eventName, eventAction if eventAction != null # bind event
    Return newBtn # return button object

# Add picture display switch
addImgSwitchBtn = -> 
    addBoardBtn 'btnImgSwitch', 'Hide/Show Picture', ->
        $('div.list-card-cover').slideToggle()

#Add Modify Background button
addBgBtn = -> 
    addBoardBtn 'setBgBtn', 'set background image', ->
        oldBgUrl = localStorage[boardId[0]]
        newBgUrl = prompt 'Please enter the background image address', oldBgUrl
        return if newBgUrl == oldBgUrl
        if newBgUrl == null or newBgUrl == ''
            localStorage.removeItem boardId[0]
            $('body').css 'background-image',''
            return
        localStorage[boardId[0]] = newBgUrl
        
# Add member display switch
addMemberToggleBtn = -> 
    addBoardBtn 'memberSwitchBtn', 'Hide/Show members', ->
        $('div.list-card-members').slideToggle()

boardInit = ->
    Return if pageRegex.HomePage.exec(curUrl) != null # Home does not execute
    bgUrl = $('body').css 'background-image'
    localBgUrl = localStorage[boardId[0]]
    if localBgUrl != undefined and bgUrl != localBgUrl
        $('body').css 'background-image',"url(\"#{localBgUrl}\")" 
    $('p.list-header-num-cards').show() # Show the number of cards
    listFormatInit()
    addImgSwitchBtn()
    addBgBtn()
    addMemberToggleBtn()

$ ->
    $('head').append cardLabelCss
    setInterval (->
        curUrl = window.location.href # current page address
        boardId = pageRegex.BoardId.exec curUrl # Current Kanban ID
        boardInit()
    ),1000
