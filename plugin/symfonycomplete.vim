let s:current_file=expand('<sfile>:p:h')
if !exists("g:symfony_app_console_path")
    let g:symfony_app_console_path = "app/console"
endif

if !exists("g:symfony_app_console_caller")
    let g:symfony_app_console_caller = "php"
endif

if !exists("g:symfony_enable_shell_mapping")
    let g:symfony_enable_shell_mapping = 0
endif

fun! CompleteSymfonyContainer(base, res)
    let shellcmd = g:symfony_app_console_caller. ' '.g:symfony_app_console_path.' debug:container'
    let output = system(shellcmd)
    if v:shell_error
        echo output
        return 0
    endif

    for m in split(output, "\n")
        let row = split(m)
        if len(row) == 2
            let [service, class] = row
            if service =~ '^' . a:base
                let menu = 'class: '. class
                call add(a:res, { 'word': service, 'menu': menu })
            endif
        endif
    endfor
endfun

fun! CompleteSymfonyRouter(base, res)
    let shellcmd = g:symfony_app_console_caller. ' '.g:symfony_app_console_path.' debug:router'
    let output = system(shellcmd)
    if v:shell_error
        echo output
        return 0
    endif

    for m in split(output, "\n")
        let row = split(m)
        if len(row) == 5
            let [route, method, scheme, host, url] = row
            if route =~ '^' . a:base
                let menu = method.' '.scheme.' '.host.' '.url
                call add(a:res, { 'word': route, 'menu': menu })
            endif
        endif
    endfor
endfun

fun! CompleteSymfony(findstart, base)
    if a:findstart
        " locate the start of the word
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '[a-zA-Z_\-.]'
            let start -= 1
        endwhile
        return start
    else
        " find symfony services id / routes matching with "a:base"
        let res = []
        call CompleteSymfonyContainer(a:base, res)
        call CompleteSymfonyRouter(a:base, res)

        return res
endfun

fun! FindService(name)
    let shellcmd = g:symfony_app_console_caller. ' '.g:symfony_app_console_path.' debug:container ' .a:name
    let output = system(shellcmd)
    echo output
endfun

fun! GoToService(name)
    echo "TODO: check alias"
    let shellcmd = g:symfony_app_console_caller. ' '.g:symfony_app_console_path.' debug:container ' .a:name . " | grep Class | awk '{print $2}'"
    let classname = substitute(system(shellcmd), '\n\+$', '', '')
    let s:reflect_path = s:current_file . '/../reflect.php'
    let s:autoload_path= expand('<sfile>:p:h') . '/app/autoload.php'
    let reflect_command = 'php ' . s:reflect_path . ' '. s:autoload_path .' ' .'"'.classname.'"'
    let dude = system(reflect_command)
    echo dude
    exe "tabnew" dude
endfun

fun! FindRoute(name)
    let shellcmd = g:symfony_app_console_caller. ' '.g:symfony_app_console_path.' debug:router ' .a:name
    let output = system(shellcmd)
    echo output
endfun

" activate completefunc only in twig, php, xml and yaml buffers
let oldcompletefunc = &completefunc

au BufEnter *.twig   setlocal completefunc=CompleteSymfony
au BufEnter *.php    setlocal completefunc=CompleteSymfony
au BufEnter *.yml    setlocal completefunc=CompleteSymfony
au BufEnter *.xml    setlocal completefunc=CompleteSymfony

" once leaved these buffers, switch back to the old completefunc, if any
au BufLeave *.twig   setlocal completefunc=oldcompletefunc
au BufLeave *.php    setlocal completefunc=oldcompletefunc
au BufLeave *.yml    setlocal completefunc=oldcompletefunc
au BufLeave *.xml    setlocal completefunc=oldcompletefunc

map <leader>t yi' :call GoToService(@")<CR>
map <leader>s yi' :call FindService(@")<CR>
map <leader>r yi' :call FindRoute(@")<CR>

" Open console
let g:symfony_enable_shell_cmd = g:symfony_app_console_caller." ".g:symfony_app_console_path." -s"

if(g:symfony_enable_shell_mapping == 1)
    map <C-F> :execute ":!"g:symfony_enable_shell_cmd<CR>
endif
