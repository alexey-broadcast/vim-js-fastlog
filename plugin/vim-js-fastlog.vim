if exists("g:loaded_js_fastlog") || &cp || v:version < 700
    finish
endif
let g:loaded_js_fastlog = 1

let g:js_fastlog_prefix = get(g:, 'js_fastlog_prefix', '')
let g:js_fastlog_use_semicolon = get(g:, 'js_fastlog_use_semicolon', 1)

let s:logModes = {
\    'simple': 1,
\    'jsonStringify': 2,
\    'showVar': 3,
\    'funcTimestamp': 4,
\    'string': 5,
\}

function! s:GetWord(type)
    let saved_unnamed_register = @@

    if (a:type ==# 'v')
        execute "normal! `<v`>y"
    elseif (a:type ==# 'char')
        execute "normal! `[v`]y"
    else
        return ''
    endif

    let word = escape(@@, "'")
    let @@ = saved_unnamed_register
    return word
endfunction

function! s:WQ(string) " Wrap with Quotes
    return "\'".a:string."\'"
endfunction

function! s:MakeInner(logmode, word)
    let inner = a:word
    if (a:logmode ==# s:logModes.string) " string: 'var' => 'console.log('var');'
        let inner = s:WQ(a:word)
    elseif (a:logmode ==# s:logModes.jsonStringify) " JSON.stringify: 'var' => 'console.log('var='+JSON.stringify(var));'
        let inner = s:WQ(a:word.'=')." + JSON.stringify(".a:word.")"
    elseif (a:logmode ==# s:logModes.showVar)
        let inner = s:WQ(a:word.'=').', '.a:word
    elseif (a:logmode ==# s:logModes.funcTimestamp)
        let filename = expand('%:t:r')
        let inner = 'Date.now() % 10000, '.s:WQ(filename.':'.line('.').' '.a:word)
    endif
    return inner
endfunction

function! s:MakeString(inner)
    let string = 'console.log'
    let string .= '('
    if (!empty(g:js_fastlog_prefix))
        let string .= s:WQ(g:js_fastlog_prefix).', '
    endif
    let string .= a:inner
    let string .= ')'
    let string .= (g:js_fastlog_use_semicolon ? ';' : '')
    return string
endfunction

function! s:JsFastLog(type, logmode)
    let word = s:GetWord(a:type)

    if (match(word, '\v\S') == -1) " check if there is empty (whitespace-only) string
        execute "normal! aconsole.log();\<esc>hh"
    else
        put =s:MakeString(s:MakeInner(a:logmode, word))

        if (a:logmode ==# s:logModes.funcTimestamp)
            normal! ==f(l
        else
            -delete _ | normal! ==f(l
        endif
    endif
endfunction

function! JsFastLog_simple(type)
    call s:JsFastLog(a:type, s:logModes.simple)
endfunction

function! JsFastLog_JSONstringify(type)
    call s:JsFastLog(a:type, s:logModes.jsonStringify)
endfunction

function! JsFastLog_variable(type)
    call s:JsFastLog(a:type, s:logModes.showVar)
endfunction

function! JsFastLog_function(type)
    call s:JsFastLog(a:type, s:logModes.funcTimestamp)
endfunction

function! JsFastLog_string(type)
    call s:JsFastLog(a:type, s:logModes.string)
endfunction

nnoremap <leader>l :set operatorfunc=JsFastLog_simple<cr>g@
vnoremap <leader>l :<C-u>call JsFastLog_simple(visualmode())<cr>

nnoremap <leader>ll :set operatorfunc=JsFastLog_JSONstringify<cr>g@
vnoremap <leader>ll :<C-u>call JsFastLog_JSONstringify(visualmode())<cr>

nnoremap <leader>lk :set operatorfunc=JsFastLog_variable<cr>g@
vnoremap <leader>lk :<C-u>call JsFastLog_variable(visualmode())<cr>

nnoremap <leader>ld :set operatorfunc=JsFastLog_function<cr>g@
vnoremap <leader>ld :<C-u>call JsFastLog_function(visualmode())<cr>

nnoremap <leader>ls :set operatorfunc=JsFastLog_string<cr>g@
vnoremap <leader>ls :<C-u>call JsFastLog_string(visualmode())<cr>
