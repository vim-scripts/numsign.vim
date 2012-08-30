" Script Name: numsign.vim 
" Version:     1.0
" Last Change: Aug 16, 2012
" Author:      hjjdebug
" Email:       hejinjing@tom.com
" Description: like ultra edit but beyond ultra edit , jump between signs  according sign ID or line Number
"
" Usage:
" it has tow working mode,  default is jump between signs according sign ID,
" you can use \sm, which will toggle according sign ID  or according Line Number
"
"                <C-F2>   \ss ----> toggle sign
"                <F2>     \sn ----> jump to next sign
"                <S-F2>   \sp ----> jump to previous sign
"                         \sc ----> clear all signs
"                         \sm ----> toggle working mode
"                         \sl ----> list current buffer signs
"
" Install: put this file in your vimfile/plugin or equivalent
" ---------------------------------------------------------------------
"   load once {{{1
if exists("loaded_Sign")
    finish
endif
let loaded_Sign = 1
if !has("signs")
    echoerr "***sorry*** [".expand("%")."] your vim doesn't support signs"
    finish
endif
" ---------------------------------------------------------------------
"  Public Interface:maps & commands {{{1
if !hasmapto('<Plug>ToggleSign')
    map <unique> <c-F2> <Plug>ToggleSign
    map <silent> <unique> \ss <Plug>ToggleSign 
endif
if !hasmapto('<Plug>GotoNextSign')
    map <unique> <F2> <Plug>GotoNextSign
    map <unique> \sn  <Plug>GotoNextSign
endif
if !hasmapto('<Plug>GotoPrevSign')
    map <unique> <s-F2> <Plug>GotoPrevSign
    map <unique> \sp <Plug>GotoPrevSign
endif
if !hasmapto('<Plug>RmAllSigns')
    map <unique> \sc <Plug>RmAllSigns
endif
if !hasmapto('<Plug>ToggleMode')
    map <unique> \sm <Plug>ToggleMode
endif
if !hasmapto('<Plug>SignList')
    map <unique> \sl <Plug>SignList
endif
nnoremap <silent> <script> <Plug>ToggleSign            :call ToggleSign()<cr>
nnoremap <silent> <script> <Plug>GotoPrevSign    :call GotoPrevSign()<cr>
nnoremap <silent> <script> <Plug>GotoNextSign    :call GotoNextSign()<cr>
nnoremap <silent> <script> <Plug>RmAllSigns        :call RmAllSigns()<cr>
nnoremap <silent> <script> <Plug>ToggleMode        :call <SID>ToggleMode()<cr>
nnoremap <silent> <script> <Plug>SignList        :call <SID>EchoAllSigns()<cr>
autocmd BufWinEnter * call s:InitVariable()
" ---------------------------------------------------------------------
"set BlueColor & SignBlue{{{1
if &bg == "dark"
    highlight BlueColor ctermfg=white ctermbg=blue guifg=white guibg=RoyalBlue3
else
    highlight BlueColor ctermfg=blue ctermbg=white guifg=RoyalBlue3 guibg=grey 
endif
fun! SignDefine(id)
    exe 'sign define SignBlue'. a:id . ' linehl=BlueColor texthl=LineNr text='.a:id
endfun

" ---------------------------------------------------------------------
"global variable {{{1 PRIVATE
fun! s:InitVariable()
    if !exists("b:sign_place_number")
        let b:sign_place_number = 1
    endif

    if !exists("b:sign_working_id")
        let b:sign_working_id = 0
    endif

    if !exists("b:sign_work_mode")
        let b:sign_work_mode = 1    "0 -> lineno, 1->id
    endif

    if !exists("b:allSignsSortByLine")
        let b:allSignsSortByLine=[]
    endif
    call GetAllSigns()
    call s:SyncData()
    call DrawAllSigns()
endfun
" ---------------------------------------------------------------------
"  GetVimCmdOutput: {{{1 PRIVATE
fun! s:GetVimCmdOutput(cmd)
    " Save the original locale setting for the messages
    let old_lang = v:lang
    " Set the language to English
    exec ":lan mes en_US"
    let output   = ''
    try
        redir => output 
        silent exe a:cmd
    catch /.*/
        let v:errmsg = substitute(v:exception, '^[^:]\+:', '', '')
    endtry
    redir END
    " Restore the original locale
    exec ":lan mes " . old_lang
    return output
endfun
" ---------------------------------------------------------------------
" GetAllSigns() "{{{1 PRIVATE
fun! GetAllSigns()        
    let signStr = s:GetVimCmdOutput('sign place buffer=' . winbufnr(0))
    let b:allSignsSortByLine=[]
    let start_from = 0
    while 1
        let begin = matchend(signStr, "line=", start_from)
        if begin <= 0
            break
        endif
        let end = match(signStr, " ", begin)
        let lineno = strpart(signStr, begin, end-begin)
        let begin = matchend(signStr, "id=", end)
        let end = match(signStr, " ", begin)
        let id = strpart(signStr,begin,end-begin)
        call add(b:allSignsSortByLine,[lineno,id])
        let start_from  = end
    endw
endfun
" ---------------------------------------------------------------------
" DrawAllSigns() {{{1
fun! DrawAllSigns()
    for item in b:allSignsSortByLine
        call SignDefine(item[1])
        exe 'sign place '. item[1] . ' line=' . item[0] . ' name=SignBlue' . item[1] . ' buffer=' . winbufnr(0)
    endfor
endfun
" ---------------------------------------------------------------------
"  PlaceSign: {{{1 PRIVATE
fun! s:PlaceSign()
    let ln = line(".")
    call SignDefine(b:sign_place_number)
    exe 'sign place ' . b:sign_place_number . ' line=' . ln . ' name=SignBlue' . b:sign_place_number . ' buffer=' . winbufnr(0)
    let b:sign_place_number = b:sign_place_number + 1
    call GetAllSigns()
    call s:SyncData()
endfun
" ---------------------------------------------------------------------
" ClearSign: {{{1	PRIVATE
fun! s:ClearSign(sign_id)
    silent! exe 'sign unplace ' . a:sign_id . ' buffer=' . winbufnr(0)
    call GetAllSigns()
    call s:SyncData()
endfun
" ---------------------------------------------------------------------
fun! s:SyncData()    "PRIVATE {{{1
    let b:allSignsSortByID=[]
    for i in b:allSignsSortByLine
        call add(b:allSignsSortByID,[i[1], i[0]])     "[id, lineno]
    endfor
    call sort(b:allSignsSortByID)
endfun

" ---------------------------------------------------------------------
"PrevID(id): PRIVATE {{{1
fun! s:PrevID(id) 
    let size = len(b:allSignsSortByID)
    if size == 0 
        return -1
    endif
    if size == 1
        return b:allSignsSortByID[0][0]
    endif
    let signID = -1
    let i = 0
    while i < size-1
        if b:allSignsSortByID[i][0] < a:id
            if b:allSignsSortByID[i+1][0] >= a:id
                let signID = b:allSignsSortByID[i][0]
                break
            endif
        endif
        let i = i + 1
    endwhile
    if signID == -1
        let signID = b:allSignsSortByID[size-1][0]
    endif
    return signID
endfun
" ---------------------------------------------------------------------
" NextID(id): {{{1 PRIVATE {{{1
fun! s:NextID(id)
    let size = len(b:allSignsSortByID)
    if size == 0 
        return -1
    endif
    let signID = -1
    for item in b:allSignsSortByID
        if item[0] > a:id
            let signID = item[0]
            break
        endif
    endfor
    if signID == -1
        let signID = b:allSignsSortByID[0][0]
    endif
    return signID
endfun
" ---------------------------------------------------------------------
" GetSignIDFromLineNo: {{{1 PRIVATE
fun! s:GetSignIDFromLineNo(lineNO)
    let id=-1
    for item in b:allSignsSortByLine
        if item[0] == a:lineNO
            let id = item[1]
            break
        endif
    endfor
    return id
endfun
" ---------------------------------------------------------------------
" GetNextSignLine_ByLineNo: {{{1 PRIVATE
fun! s:GetNextSignLine_ByLineNo(curLineNo)
    let size = len(b:allSignsSortByLine)
    if size == 0 
        return -1
    endif
    let signLine = -1
    for item in b:allSignsSortByLine
        if item[0] > a:curLineNo
            let signLine = item[0]
            break
        endif
    endfor
    if signLine == -1
        let signLine = b:allSignsSortByLine[0][0]
    endif
    return signLine
endfun

" ---------------------------------------------------------------------
" GetNextSignLine_ByID: {{{1 PRIVATE
fun! s:GetNextSignLine_ByID(signID)
    let size = len(b:allSignsSortByID)
    if size == 0 
        return -1
    endif
    let signLine = -1
    for item in b:allSignsSortByID
        if item[0] > a:signID
            let signLine = item[1]
            break
        endif
    endfor
    if signLine == -1
        let signLine = b:allSignsSortByID[0][1]
    endif
    return signLine
endfun
" ---------------------------------------------------------------------
" GetPrevSignLine_ByLineNo: {{{1 PRIVATE
fun! s:GetPrevSignLine_ByLineNo(curLineNo)
    let size = len(b:allSignsSortByLine)
    if size == 0 
        return -1
    endif
    if size == 1
        return b:allSignsSortByLine[0][0]
    endif
    let signLine = -1
    let i = 0
    while i < size-1
        if b:allSignsSortByLine[i][0] < a:curLineNo
            if b:allSignsSortByLine[i+1][0] >= a:curLineNo
                let signLine = b:allSignsSortByLine[i][0]
                break
            endif
        endif
        let i = i + 1
    endwhile
    if signLine == -1
        let signLine = b:allSignsSortByLine[size-1][0]
    endif
    return signLine
endfun
" ---------------------------------------------------------------------
" GetPrevSignLine_ByID: {{{1 PRIVATE
fun! s:GetPrevSignLine_ByID(signID)
    let size = len(b:allSignsSortByID)
    if size == 0 
        return -1
    endif
    if size == 1
        return b:allSignsSortByID[0][1]
    endif
    let signLine = -1
    let i = 0
    while i < size-1
        if b:allSignsSortByID[i][0] < a:signID
            if b:allSignsSortByID[i+1][0] >= a:signID
                let signLine = b:allSignsSortByID[i][1]
                break
            endif
        endif
        let i = i + 1
    endwhile
    if signLine == -1
        let signLine = b:allSignsSortByID[size-1][1]
    endif
    return signLine
endfun
" -------l-------------------------------------------------------------
" GotoNextSign: PUBLIC {{{1
fun! GotoNextSign()
    if b:sign_work_mode == 0
        let curLineNo      = line(".")
        let next_sign_line_number = s:GetNextSignLine_ByLineNo(curLineNo)
    else
        let next_sign_line_number = s:GetNextSignLine_ByID(b:sign_working_id)
        let b:sign_working_id = s:NextID(b:sign_working_id)
    endif
    if next_sign_line_number >= 0
        exe ":" . next_sign_line_number
    endif
endfun
" ---------------------------------------------------------------------
" GotoPrevSign: PUBLIC {{{1
fun! GotoPrevSign()
    if b:sign_work_mode == 0
        let curLineNo      = line(".")
        let prev_sign_line_number = s:GetPrevSignLine_ByLineNo(curLineNo)
    else
        let prev_sign_line_number = s:GetPrevSignLine_ByID(b:sign_working_id)
        let b:sign_working_id=s:PrevID(b:sign_working_id)
    endif
    if prev_sign_line_number >= 0
        exe ":". prev_sign_line_number 
    endif
endfun
" ---------------------------------------------------------------------
" ToggleSign:  PUBLIC {{{1 
fun! ToggleSign()
    let curLineNo = line(".")
    let sign_id  = s:GetSignIDFromLineNo(curLineNo)
    if sign_id < 0
        call s:PlaceSign()
    else
        call s:ClearSign(sign_id)
    endif
endfun
" -------l-------------------------------------------------------------
fun! s:ToggleMode()
    if b:sign_work_mode==0
        let b:sign_work_mode=1
    else
        let b:sign_work_mode=0
    endif
    echo "sign working mode: " . (b:sign_work_mode==0 ? "pos" : "ID")
endfun
" ---------------------------------------------------------------------
"  vim:fdm=marker ts=4 sw=4:
" RmAllSigns: PUBLIC {{{1
fun! RmAllSigns()
    let b:sign_place_number = 1
    let b:allSignsSortByLine=[]
    let b:sign_working_id = 0
    call s:SyncData()
    silent! exe 'sign unplace *'
endfun

" ---------------------------------------------------------------------
" EchoAllSigns() {{{1	PUBLIC
fun! s:EchoAllSigns()    
"    call GetAllSigns()
    let size = len(b:allSignsSortByLine)
    for d in b:allSignsSortByLine
        echo "lineno->".d[0]. " id->".d[1]
    endfor
endfun
" ---------------------------------------------------------------------
