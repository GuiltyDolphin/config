" Vim config file
" Part of GuiltyDolphin's dotfiles
" Hosted at: https://www.github.com/GuiltyDolphin/config

set nocompatible              " be iMproved


" Vim-Plug {{{

" Bootstrap vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent execute '!curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  augroup VimPlugInit
    autocmd!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif

call plug#begin('~/.vim/bundle')

" Disable to prevent loading of syntax plugins.
let g:use_syntax_plugins = 1

if g:use_syntax_plugins
  Plug 'lervag/vimtex'
  Plug 'lesliev/vim-inform7'       " Syntax file highlighting for inform
  Plug 'vim-ruby/vim-ruby'         " Convinient bindings for Ruby
  Plug 'Twinside/vim-haskellConceal'
  " Plug 'pbrisbin/vim-syntax-shakespeare'  " Highlighting for Yesod Shakespeare
  Plug 'idris-hackers/idris-vim' " General plugin for Idris
  Plug 'rust-lang/rust.vim' " General plugin for Rust
endif

Plug 'altercation/vim-colors-solarized' " Solarized colorscheme
Plug 'bitc/vim-hdevtools'
Plug 'dbakker/vim-lint'
Plug 'eagletmt/neco-ghc'
Plug 'honza/vim-snippets'        " Default ultisnips snippets
Plug 'jpalardy/vim-slime'        " One way communication to a tmux session
Plug 'kien/ctrlp.vim'
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdtree'
Plug 'sirver/ultisnips'          " Snippet integration
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'        " Git integration
Plug 'tpope/vim-surround'        " Allow manipulation of surrounding characters
Plug 'godlygeek/tabular'         " Text filtering and alignment
Plug 'plasticboy/vim-markdown'   " Must come after 'godlygeek/tabular'
Plug 'mustache/vim-mustache-handlebars' " Mustache & Handlebars integration
Plug 'neoclide/coc.nvim', {'branch': 'release'} " LSP, autocompletion, IDE features

Plug 'guiltydolphin/tex-headings-vim' " Who doesn't love to change section headers?
Plug 'guiltydolphin/project-root-vim' " Easier project navigation

call plug#end()

" }}}

" Colorscheme {{{

syntax on
set t_Co=256
set background=dark
colorscheme solarized

" }}}

" Custom mappings {{{

" Helpers {{{

" Bind a local leader mapping to the given action (buffer-local)
function MyMapLocalLeader(mode, bind, what)
  exec a:mode . " <buffer><silent><localleader>" . a:bind . " " . a:what
endfunction

function! MyMapLocalLeaderCommand(bind, what)
  call MyMapLocalLeader('nnoremap', a:bind, ':' . a:what . '<CR>')
endfunction

function! MyMapLocalLeaderCall(bind, what)
  call MyMapLocalLeaderCommand(a:bind, 'call ' . a:what . '()')
endfunction

function MyMapLocalLeaderAu(ft, mode, bind, what)
  exec printf("au FileType %s call MyMapLocalLeader(%s, %s, %s)", a:ft, string(a:mode), string(a:bind), string(a:what))
endfunction

function MyMapLocalLeaderAuCommand(ft, bind, what)
  call MyMapLocalLeaderAu(a:ft, 'nnoremap', a:bind, ':' . a:what . '<CR>')
endfunction

function MyMapLocalLeaderAuCommands(ft, binds)
  for [bind, target] in a:binds
    call MyMapLocalLeaderAuCommand(a:ft, bind, target)
  endfor
endfunction

function MyMapLocalLeaderAuCall(ft, bind, what)
  call MyMapLocalLeaderAuCommand(a:ft, a:bind, 'call ' . a:what . '()')
endfunction

function MyMapLocalLeaderAuCalls(ft, binds)
  for [bind, target] in a:binds
    call MyMapLocalLeaderAuCall(a:ft, bind, target)
  endfor
endfunction

" Execute code when the filetype matches the spec
function MyWhenFiletypeMatching(match, body)
  if match(&filetype, '^\(' . a:match . '\)$') > -1
    exec a:body
  endif
endfunction

" Execute code when the buffer name matches the spec
function MyWhenBufMatching(match, body)
  if match(buffer_name(), a:match) > -1
    exec a:body
  endif
endfunction

" Autocommand that executes when the buffer name matches the spec
function MyAuBufMatching(match, body)
  " Check when entering a buffer or the buffer name changes
  exec "au BufEnter,BufFilePost * :call MyWhenBufMatching(" . string(a:match) . ", " . string(a:body) . ')'
endfunction

" }}}

" Standard {{{

" Space as leader.
let mapleader = "\<Space>"
nnoremap <Space> <nop>
" Comma as local leader.
let maplocalleader = ','
nnoremap , <nop>

" Provide alternate methods of reversing find.
nnoremap \ ,
nnoremap ,, ,

" Move in actual lines rather than virtual
nnoremap <silent> k gk
nnoremap <silent> j gj

" Jump to parens
nnoremap gp %

" Open .vimrc
nnoremap <silent> <leader>ev :vsplit $MYVIMRC<cr>
" Source .vimrc
nnoremap <silent> <leader>sv :source $MYVIMRC<cr>

" Use ; to access command-line
nnoremap ; :
nnoremap : ;
xnoremap ; :
xnoremap : ;

" Faster saving
nnoremap <silent> <leader>w :write<cr>

" Turn off highlighting for last search
nnoremap <silent> <leader>cs :nohlsearch<CR>

" Toggle spell-checking for current buffer
nnoremap <silent> <leader>cS :setlocal spell!<CR>

" Avoid tmux conflict
nnoremap <silent> <c-n> <nop>

" }}}

" Plugins {{{

" Tagbar {{{

" Toggle tagbar window
nnoremap <silent> <leader>b :TagbarToggle<cr>
" Toggle NERDTree window
nnoremap <silent> <leader>n :NERDTreeToggle<cr>

augroup MyTagbar
  au!
  au FileType tagbar nnoremap <buffer><silent>Q :TagbarClose<CR>
augroup END

" }}}

" Linting and LSP (generic) {{{

" Linting (Generic) {{{

let g:my_lint_config = {}

function! MyLintCHasCommand(name, command)
  try
    let l:cmdlist = g:my_lint_config[a:name]['commands']
    return has_key(l:cmdlist, a:command)
  catch /Key not present/
    return v:false
  endtry
endfunction

function! MyLintCGetCommandConfig(name, command)
  return g:my_lint_config[a:name]['commands'][a:command]
endfunction

function! MyLintCGetThisCommand(command)
  return MyLintCGetCommandConfig(&filetype, a:command)
endfunction

" Run autofix for the current setup
function! MyLintAutofix()
  exec MyLintCGetThisCommand('autofix')
endfunction

" Restart lint service
function! MyLintRestart()
  exec MyLintCGetThisCommand('restart')
endfunction

" Show lint errors for entire project
function! MyLintShowProject()
  exec MyLintCGetThisCommand('lintProject')
  " open the current error list
  copen
endfunction

" Configure linting
function! MyLintConfigure()
  exec MyLintCGetThisCommand('configure')
endfunction

" Configure standard bindings for linting
function! MyConfigureLinterBindings(ft)
  for [cmd, bind, target] in [
        \ ['autofix', 'la', 'MyLintAutofix'],
        \ ['lintProject', 'll', 'MyLintShowProject'],
        \ ['restart', 'lR', 'MyLintRestart'],
        \ ['configure', 'lC', 'MyLintConfigure']
        \ ]
    if MyLintCHasCommand(a:ft, cmd)
      call MyMapLocalLeaderCall(bind, target)
    endif
  endfor
endfunction

" }}}

" Show error list
function! MyShowFileErrorList()
  CocDiagnostics
endfunction

" Hover (e.g., show type at cursor)
function! MyHover()
  call CocAction("doHover")
endfunction

function! MyHasHoverSafe()
  try
    return len(CocAction('getHover')) !=# 0
  catch /Error on "getHover" request/
    return 0
  endtry
endfunction

" Hover, but don't replace any active floats and don't print a message if no
" hover is found. Useful for e.g., CursorHold where warning about no hover
" information may get noisy.
function! MyHoverNoOverride()
  if !CocHasProvider('hover')
    return
  endif

  " Don't override existing floats
  if !coc#float#has_float()
    " Check if there's any hover information available
    if MyHasHoverSafe()
      call CocAction('doHover')
    endif
  endif
endfunction

function! MyGoToDefinition()
  if CocHasProvider('definition')
    call CocAction('jumpDefinition')
  else
    normal! gd
  endif
endfunction

function! MyGoToReferences()
  call CocAction('jumpReferences')
endfunction

function! MyRefactor()
  call CocAction('refactor')
endfunction

function! MyRenameSymbol()
  if CocAction('hasProvider', 'rename')
    call CocActionAsync('rename')
  endif
endfunction

nnoremap <silent> <leader>fl :call MyShowFileErrorList()<CR>
nnoremap <silent> gd :call MyGoToDefinition()<CR>
nnoremap <silent> <localleader>gr :call MyGoToReferences()<CR>
nnoremap <silent> <localleader>RR :call MyRefactor()<CR>
nnoremap <silent> <localleader>Rr :call MyRenameSymbol()<CR>
nnoremap <silent> <localleader>fd :<C-u>CocList diagnostics<CR>
nnoremap <silent> <localleader>fo :<C-u>CocList outline<CR>
nnoremap <silent> <localleader>fs :<C-u>CocList -I symbols<CR>

" }}}

" coc {{{

" Extensions to install on startup if they aren't already installed
let g:coc_global_extensions = []

" Use 0.5 seconds before hover info
set updatetime=500

" Coc recommends Vim >= v8.2.0750. Disable the errors as they'll happen on
" every Vim start.
let g:coc_disable_startup_warning = 1

" Set up standard bindings for interacting with managed languages.
"
" Example:
" augroup TypeScript
"   au!
"   call s:MyBindCocStandard('javascript,typescript')
" augroup END
function s:MyBindCocStandard(ft)
  " Insert current entry from popup
  exec printf('au FileType %s inoremap <silent><expr> <C-b> coc#pum#visible() ? coc#pum#insert() : "\<C-b>"', a:ft)

  " Hover (e.g., show type at cursor)
  call MyMapLocalLeaderAu(a:ft, 'nnoremap', 'th', ':call MyHover()<CR>')

  " Show hover (e.g., type) info when cursor is held, providing there isn't
  " already a float showing
  exec printf("au CursorHold * call MyWhenFiletypeMatching(%s, 'call MyHoverNoOverride()')", string(join(split(a:ft, ','), '\|')))

  " Applying code actions (e.g., filling expansion arms)
  call MyMapLocalLeaderAu(a:ft, 'nmap', 'tT', '<Plug>(coc-codeaction-selected)')
  call MyMapLocalLeaderAu(a:ft, 'xmap', 'tT', '<Plug>(coc-codeaction-selected)')
  call MyMapLocalLeaderAu(a:ft, 'nmap', 'tt', '<Plug>(coc-codeaction-cursor)')
endfunction

" Scrolling for the floating (documentation) window
" coc#float#scroll() requires nvim >= 0.4.0 or vim >= 8.2.0750
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-e> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-e>"
  nnoremap <silent><nowait><expr> <C-y> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-y>"
  inoremap <silent><nowait><expr> <C-e> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-e>"
  inoremap <silent><nowait><expr> <C-y> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-y>"
  vnoremap <silent><nowait><expr> <C-e> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-e>"
  vnoremap <silent><nowait><expr> <C-y> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-y>"
endif

function! s:MyCocBindObjects()
  function! MyCocBindObjectsInner(providesOK)
    if a:providesOK
      xmap <buffer> af <Plug>(coc-funcobj-a)
      xmap <buffer> if <Plug>(coc-funcobj-i)
      omap <buffer> af <Plug>(coc-funcobj-a)
      omap <buffer> if <Plug>(coc-funcobj-i)
      xmap <buffer> ac <Plug>(coc-classobj-a)
      xmap <buffer> ic <Plug>(coc-classobj-i)
      omap <buffer> ac <Plug>(coc-classobj-a)
      omap <buffer> ic <Plug>(coc-classobj-i)
    endif
  endfunction
  call <SID>MyCocActionAsyncWithCallback(function('MyCocBindObjectsInner'), 'hasProvider', 'documentSymbol')
endfunction

function! s:MyCocActionAsyncWithCallback(callback, ...)
  call <SID>MyCocWaitForServices(function('<SID>MyCocActionAsyncWithCallbackNoWait', [a:callback] + a:000))
endfunction

function! s:MyCocActionAsyncWithCallbackNoWaitInner(iter_settings, iters, callback, args, e, r)
  if a:e ==# 'Plugin not ready'
    exec 'sleep ' . a:iter_settings.iter_len . 'm'
    call <SID>MyCocActionAsyncWithCallbackNoWaitCheck(a:iter_settings, a:iters + 1, a:callback, a:args)
  elseif a:e ==# 'v:null'
    try
      call a:callback(a:r)
    catch
      echom "Error in call: " v:exception
    endtry
  else
    echom "unknown error: " a:e
  endif
endfunction

function! s:MyCocActionAsyncWithCallbackNoWaitCheck(iter_settings, iters, callback, args)
  if a:iters > a:iter_settings.max_iters
    echom "Max iterations hit"
    return
  endif
  call function('CocActionAsync', a:args + [{e, r -> <SID>MyCocActionAsyncWithCallbackNoWaitInner(a:iter_settings, a:iters, a:callback, a:args, e, r)}])()
endfunction

function! s:MyCocActionAsyncWithCallbackNoWait(callback, ...)
  " in milliseconds
  let l:max_wait = 2000
  let l:iter_len = 100
  let l:max_iters = l:max_wait / l:iter_len
  let l:iter_settings = { 'max_iters': l:max_iters, 'iter_len': l:iter_len }

  call <SID>MyCocActionAsyncWithCallbackNoWaitCheck(l:iter_settings, 0, a:callback, a:000)
endfunction

function! s:MyCocWaitForServicesCheckServices(iter_settings, iters, callback, services)
  for service in a:services
    if service.state ==# 'starting'
      exec 'sleep ' . a:iter_settings.iter_len . 'm'
      call <SID>MyCocWaitForServicesCheck(a:iter_settings, a:iters + 1, a:callback)
      return
    endif
  endfor
  call a:callback()
endfunction

function! s:MyCocWaitForServicesCheck(iter_settings, iters, callback)
  if a:iters > a:iter_settings.max_iters
    echom "Max iterations hit"
    return
  endif
  call <SID>MyCocActionAsyncWithCallbackNoWait({services -> <SID>MyCocWaitForServicesCheckServices(a:iter_settings, a:iters, a:callback, services)}, 'services')
endfunction

function! s:MyCocWaitForServices(callback)
  " in milliseconds
  let l:max_wait = 2000
  let l:iter_len = 100
  let l:max_iters = l:max_wait / l:iter_len
  let l:iter_settings = { 'max_iters': l:max_iters, 'iter_len': l:iter_len }

  call <SID>MyCocWaitForServicesCheck(l:iter_settings, 0, a:callback)
endfunction

augroup MyCocNewBuf
  autocmd!
  au FileType * call <SID>MyCocBindObjects()
augroup END

" }}}

" ctrlp {{{

" Open ctrlp tag window
nnoremap <silent> <C-p> :CtrlP<cr>

" In git repos: list all files (including untracked), except those excluded
" (e.g., via .gitignore)
let g:ctrlp_user_command = {
    \ 'types': {
        \ 1: ['.git', 'cd %s && git ls-files -co --exclude-standard'],
    \ },
\ }

" }}}

" Ultisnips
let g:UltiSnipsJumpForwardTrigger = '<c-b>'
let g:UltiSnipsExpandTrigger = '<c-b>'

" fugitive {{{

nnoremap <silent> <leader>ga :Git add %<cr>
nnoremap <silent> <leader>gs :Gstatus<cr>
nnoremap <silent> <leader>gd :Git diff %<cr>

" }}}

" project-root {{{

let s:proot_leader_key = 'p'
exec 'nnoremap <silent> <leader>' . s:proot_leader_key . 'ra :ProjectRootTest<cr>'
exec 'nnoremap <silent> <leader>' . s:proot_leader_key . 'rt :ProjectRootTestFile<cr>'
exec 'nnoremap <silent> <leader>' . s:proot_leader_key . 'br :ProjectRootBrowseRoot<cr>'
exec 'nnoremap <silent> <leader>' . s:proot_leader_key . 'tf :ProjectRootOpenTest<cr>'

" }}}

" }}}

" Filetypes {{{

" Haskell {{{

augroup HaskellKeys
  autocmd!
  call MyMapLocalLeaderAuCommands('haskell', [
        \ ['ct', 'HdevtoolsType'],
        \ ['cc', 'HdevtoolsClear'],
        \ ['ci', 'HdevtoolsInfo']
        \ ]
        \)
augroup END

" }}}

" Ruby {{{

augroup RubyKeys
  autocmd!
  call MyMapLocalLeaderAuCommand('ruby', 'ir', 'exec "!irb" . ruby_version')
augroup END

" }}}

" Git {{{

augroup GitCommitKeys
  autocmd!
  for [bind, target] in [
        \ ['r', 'reword'],
        \ ['s', 'squash'],
        \ ['e', 'edit'],
        \ ['p', 'pick'],
        \ ['f', 'fixup'],
        \ ['x', 'exec']
        \ ]
    call MyMapLocalLeaderAu('gitrebase', 'nnoremap', bind, '^ciw' . target . '<esc>')
  endfor
augroup END

" }}}

" Help {{{

augroup HelpKeys
  au!
  call MyMapLocalLeaderAuCall('help,text', 'th', '<SID>ToggleHelpType')
augroup END

function! s:ToggleHelpType()
  if &filetype =~# '\vt[e]xt'
    setlocal filetype=help
  elseif &filetype =~# 'help'
    setlocal filetype=text
  endif
endfunction

" }}}

" Vim {{{

augroup VimKeys
  autocmd!
  call MyMapLocalLeaderAuCommand('vim', 'sf', 'source %')
augroup END

" }}}

" TeX {{{

augroup GenericTeXKeys
  autocmd!
  call MyMapLocalLeaderAuCalls('lhaskell,tex,plaintex', [
        \ ['hh', 'TexHeaderHigher'],
        \ ['hl', 'TexHeaderLower']
        \ ]
        \)
augroup END

" }}}

" }}}

" }}}

" Abbreviations {{{

cnorea fl function-list

" }}}

" Options {{{

" Boolean options {{{

" Line numbers
set number         " Display line numbers on left
set relativenumber " Display line numbers relative to current

" Indenting {{{

set autoindent     " Keep indentation of previous line
set copyindent     " Copy indent character used for previous line
set shiftround     " Round autoindenting to a multiple of 'shiftwidth'
set expandtab      " Expand tabs to spaces
set smarttab       " Insert tabs according to shiftwidth

" }}}

" Searching {{{

set ignorecase     " Ignore cases in searches
set smartcase      " Override 'ignorecase' if pattern contains upper case characters
set hlsearch       " Highlight matches for last search
set incsearch      " Highlight next match

" }}}

set hidden         " Hide buffers instead of closing
set nowrap         " Don't show lines wrapping in the buffer
set noerrorbells   " Don't use alerts for errors that have messages
" Backups
set noswapfile     " Don't use swap files for the current buffer
set nobackup       " Don't make backup copies of files when overwriting
"set notimeout     " Allow umlimited time to enter symbols (mathematic.vim)

" }}}

" Number options {{{

" Indenting {{{

set laststatus=2 " Shows the statusline.
set shiftwidth=2 " Generally use 2 spaces for indenting
set softtabstop=2
set tabstop=2

" }}}

" Bash {{{

let g:is_bash = 1 " Default to using bash as filetype.
let g:sh_fold_enabled = 5 " Enable function & if/do/for folding.

" }}}

" }}}

" String options {{{

" Spelling {{{

set dictionary+=/usr/share/dict/words
set dictionary-=/usr/share/dict/words " Avoid duplicate words
set spelllang=en_us " Language to use when spell-checking

" }}}

set backspace=indent,eol,start        " Use backspace jumping in insert mode

" Statusline {{{

set statusline=                 " clear stl for when reloaded
set statusline+=%f\             " Path to the file
set statusline+=[%h%m%r%w]\ -\  " Flags
set statusline+=FileType:       " Label
set statusline+=%y              " Filetype of the file
set statusline+=%=              " Switch to the right side
set statusline+=(%l,\ %c)       " Current line, current column
set statusline+=/               " Separator
set statusline+=%-L             " Total # lines
set statusline+=%4p             " Percentage through file (lines)

" }}}

" Ignored Files {{{

set wildignore=
set wildignore+=*/.git " VCS
set wildignore+=*.ibc  " Idris compilation files
set wildignore+=*.ho   " Haskell compilation files
set wildignore+=*.pdf
set wildignore+=*.toc,*.aux " LaTeX build files

" }}}

" }}}

" Variable {{{

" Plugins {{{

" vim-slime {{{

let g:slime_target = 'tmux'
let g:slime_paste_file = tempname()

" }}}

" haskellmode {{{

let g:haddock_browser = '/usr/bin/lynx'
let g:ghc = '/usr/bin/ghc'

" }}}

" }}}

" }}}

" FileTypes {{{

" Ruby {{{

let ruby_version = '2.0' " Preferred ruby version

" }}}

" }}}

" }}}

" Plugin Config {{{

" project-root-vim {{{

" Project settings

" Ruby {{{

let s:pr_ruby =
      \ { 'root_globs': ['[Rr]akefile'],
      \   'test_command': 'rake test',
      \ }

call proot#initialize_project('ruby', s:pr_ruby)

function! s:RubySpecTestFile(root_dir)
  return 'spec/' . fnamemodify(a:root_dir, ':t:r') . '_spec.rb'
endfunction

function! s:RubySpecTestFileCommand(test_path)
  return 'ruby ' . a:test_path
endfunction

let s:pr_ruby_spec =
      \ { 'test_globs': ['spec'],
      \   'inherits': ['ruby'],
      \   'test_file_gen': function('s:RubySpecTestFile'),
      \   'test_command_file': function('s:RubySpecTestFileCommand'),
      \ }

call proot#initialize_project('ruby_spec', s:pr_ruby_spec)

" Set the ruby project type based on the type of tests used.
function! s:SetRubyProject()
  let spec_match = globpath(b:project_root_project.root_directory, 'spec')
  if !empty(spec_match)
    call proot#set_project_type('ruby_spec')
  endif
endfunction

call proot#add_project_runners('ruby', [function('s:SetRubyProject')])

" }}}

" Python {{{

function! s:PythonTestFile(root_dir)
  return 'tests/test_' . fnamemodify(a:root_dir, ':t')
endfunction

function! s:PythonTestFileCommand(test_path)
  let test_module = 'tests.' . fnamemodify(a:test_path, ':t:r')
  return '[ -e "setup.py" ] && python3 setup.py test -s ' . test_module . ' || '
        \ . 'PYTHONPATH=$PYTHONPATH:./src python3 -m ' . test_module
endfunction

let s:pr_python =
      \ { 'root_globs': ['setup.py', 'src'],
      \   'test_command': 'python3 setup.py test',
      \   'test_file_gen': function('s:PythonTestFile'),
      \   'test_command_file': function('s:PythonTestFileCommand'),
      \ }

call proot#initialize_project('python', s:pr_python)

" }}}

" Haskell {{{

let s:pr_haskell =
      \ { 'root_globs': ['*.cabal'],
      \   'test_command': 'cabal test',
      \ }

call proot#initialize_project('haskell', s:pr_haskell)

" }}}

" Perl {{{

function! s:PerlTestFile(root_dir)
  return 't/' . fnamemodify(a:root_dir, ':t:r') . '.t'
endfunction

function! s:PerlTestFileCommand(test_path)
  return 'prove -Ilib ' . a:test_path
endfunction

let s:pr_perl =
      \ { 'root_globs': ['lib', 't'],
      \   'test_command': 'prove -lr',
      \   'test_file_gen': function('s:PerlTestFile'),
      \   'test_command_file': function('s:PerlTestFileCommand'),
      \ }

call proot#initialize_project('perl', s:pr_perl)

" DuckDuckGo {{{

function! s:SetPerlProject()
  setlocal shiftwidth=4
  let a:dir = fnamemodify(b:project_root_project.root_directory, ':t')
  if a:dir =~# '\v(duckduckgo|p5-app-duckpan)'
    call proot#set_project_type('ddg_backend')
  elseif a:dir =~# '\v^(zeroclickinfo-.*)'
    call proot#set_project_type('ddg_zci')
  endif
endfunction

call proot#add_project_runners('perl', [function('s:SetPerlProject')])

let s:pr_ddg_backend = { 'inherits': ['perl'] }

call proot#initialize_project('ddg_backend', s:pr_ddg_backend)

function! s:SetDDGBackendProject()
  setlocal noexpandtab
  setlocal shiftwidth=2
endfunction

call proot#add_project_runners('ddg_backend', [function('s:SetDDGBackendProject')])

function! s:DDGZCITestFile(root_dir)
  if a:root_dir =~# '.*Role\/.*'
    return 't/00-roles.t'
  elseif a:root_dir =~# '.*share.*'
    return matchstr(a:root_dir, '\v.*share/\zs([_\w]+)\ze/?.*')
  endif
  return 't/' . fnamemodify(a:root_dir, ':t:r') . '.t'
endfunction

function! s:DDGZCITestFileCommand(test_path)
  if a:test_path ==# 't/00-roles.t'
    return 'prove -Ilib t/00-roles.t'
  endif
  let ia_name = fnamemodify(a:test_path, ':t:r')
  return 'duckpan test ' . ia_name
endfunction

let s:pr_ddg_zci =
      \ { 'inherits': ['perl'],
      \   'test_command': 'duckpan test',
      \   'test_file_gen': function('s:DDGZCITestFile'),
      \   'test_command_file': function('s:DDGZCITestFileCommand'),
      \ }

call proot#initialize_project('ddg_zci', s:pr_ddg_zci)

" }}}

" }}}

" }}}

" }}}

" Autocommands {{{

" Buffer-based {{{

" Quickfix {{{

function! MyGetCurrentQuickfixType()
  if getqflist({'qfbufnr': 0}).qfbufnr ==# bufnr()
    return 'qf'
  elseif getloclist(0, {'qfbufnr': 0}).qfbufnr ==# bufnr()
    return 'loclist'
  else
    return 'none'
  endif
endfunction

function! MyCloseCurrentQuickfix()
  let l:qf_type = MyGetCurrentQuickfixType()
  if l:qf_type ==# 'qf'
    cclose
  elseif l:qf_type ==# 'loclist'
    lclose
  endif
endfunction

augroup Quickfix
  au!
  au FileType qf nnoremap <buffer><silent>Q :call MyCloseCurrentQuickfix()<CR>
augroup END

" }}}

" Whitespace {{{

" Delete trailing whitespace when saving
augroup writer
    autocmd!
    autocmd BufWritePre * call <SID>RemoveTrailingWhitespace()
augroup END

function! s:RemoveTrailingWhitespace()
  if !exists('b:allow_trailing_whitespace')
    exec '%s/\v\s+$//e'
  endif
endfunction

" }}}

" Automatically jump to (and center on) last place in file
augroup newfile
    autocmd!
    autocmd BufRead * execute 'normal!' . "'" . '"zz'
augroup END

" }}}

" Bash {{{

call add(g:coc_global_extensions, 'coc-sh')

augroup bash
  autocmd!
  autocmd FileType bash :setlocal foldmethod=syntax
  call s:MyBindCocStandard('sh,bash')
augroup END

" }}}

" Inform {{{

augroup inform7
  autocmd!
  au FileType inform7 setlocal noexpandtab
augroup END

" }}}

" JavaScript {{{

call add(g:coc_global_extensions, 'coc-eslint')

let g:my_lint_config['javascript'] = {
      \ 'commands': {
        \ 'autofix': 'CocCommand eslint.executeAutofix',
        \ 'configure': 'CocCommand eslint.createConfig',
        \ 'lintProject': 'CocCommand eslint.lintProject',
        \ 'restart': 'CocCommand eslint.restart'
      \ }
    \ }

augroup JavaScript
  au!
  au FileType javascript setlocal shiftwidth=4
  au FileType javascript,typescript call MyConfigureLinterBindings('javascript')
augroup END

" TypeScript {{{

call add(g:coc_global_extensions, 'coc-tsserver')

augroup TypeScript
  au!
  call s:MyBindCocStandard('javascript,typescript')
augroup END

" }}}

" JSON {{{

call add(g:coc_global_extensions, 'coc-json')

augroup JSON
  au!
  au FileType json setlocal shiftwidth=4
augroup END

" }}}

" Python {{{

call add(g:coc_global_extensions, 'coc-pyright')

augroup Python
  autocmd!
  autocmd FileType python setlocal shiftwidth=4
  call s:MyBindCocStandard('python')
augroup END

" }}}

" Vim {{{

augroup Vim
  autocmd!
  au FileType vim :setlocal foldmethod=marker
augroup END

" }}}

" Haskell {{{

augroup Haskell
  autocmd!
  au FileType haskell setlocal omnifunc=necoghc#omnifunc
augroup END

" }}}

" Rust {{{

" Install appropriate coc extensions
call add(g:coc_global_extensions, 'coc-rust-analyzer')

let g:rustfmt_fail_silently = 0 " Don't prevent rustfmt from showing errors

let g:my_lint_config['rust'] = {
      \ 'commands': {
        \ 'autofix': "call CocAction('format')"
      \ }
    \ }

augroup Rust
  autocmd!

  " Automatically format on buffer save
  au FileType rust let b:rustfmt_autosave = 1

  " General project bindings
  call MyMapLocalLeaderAuCommands('rust', [
        \ ['rr', 'Crun'],
        \ ['rt', 'Ctest'],
        \ ['rb', 'Cbuild'],
        \ ['rB', 'Cbench'],
        \ ['rU', 'Cupdate']
        \ ]
        \)

  " Coc bindings
  call s:MyBindCocStandard('rust')

  " Allow easily quitting the cargo-generated buffers
  call MyAuBufMatching('!cargo .*', "nnoremap <buffer><silent>Q :bdelete<CR>")

  " Linting
  au FileType rust call MyConfigureLinterBindings('rust')
augroup END

" }}}

" Git {{{

augroup gitdiff
  au!
  au FileType diff let b:allow_trailing_whitespace = 1
augroup END

" }}}

" Spelling {{{

augroup SpellCheck
  au!
  au FileType gitrebase,gitcommit,bib,tex,plaintex,lhaskell,*markdown*
        \ setlocal spell
augroup END

" }}}

" Hasktags (tagbar) {{{

let g:tagbar_type_haskell = {
    \ 'ctagsbin'  : 'hasktags',
    \ 'ctagsargs' : '-x -c -o-',
    \ 'kinds'     : [
        \  'm:modules:0:1',
        \  'd:data: 0:1',
        \  'd_gadt: data gadt:0:1',
        \  't:type names:0:1',
        \  'nt:new types:0:1',
        \  'c:classes:0:1',
        \  'cons:constructors:1:1',
        \  'c_gadt:constructor gadt:1:1',
        \  'c_a:constructor accessors:1:1',
        \  'ft:function types:1:1',
        \  'fi:function implementations:0:1',
        \  'o:others:0:1'
    \ ],
    \ 'sro'        : '.',
    \ 'kind2scope' : {
        \ 'm' : 'module',
        \ 'c' : 'class',
        \ 'd' : 'data',
        \ 't' : 'type'
    \ },
    \ 'scope2kind' : {
        \ 'module' : 'm',
        \ 'class'  : 'c',
        \ 'data'   : 'd',
        \ 'type'   : 't'
    \ }
    \ }

" }}}

" }}}

" Custom functions {{{

" Haskell {{{

" Attempts to generate a suitable Haskell module name for the
" current file.
"
" If the file is part of a cabal project (i.e there exists a .cabal file)
" then the name can be generated intelligently, otherwise the basename
" of the file (without the extension) will be used.
"
" Example:
" If the project is /stuff/cabal-dir/src/Foo/Bar/Baz.hs then the generate
" module name will be Foo.Bar.Baz
"
" If there were no directory containing a .cabal file, then the generated
" module name would be Baz.
function! HaskellModuleName()
 let cabal_path = b:project_root_directory
 if expand('%') =~? '\v^$'
   echoerr 'Not in a valid module file'
   return -1
 endif
 if cabal_path =~? '\v^$'
   return expand('%:t:r')
 endif
 let full_path = expand('%:p:r')
 let below_cabal = substitute(full_path, cabal_path, '', '')
 let module_path = matchlist(below_cabal, '\v/[^/]+/(.*)')[1]
 return substitute(module_path, '/', '.', 'g')
endfunction

" }}}

" }}}
