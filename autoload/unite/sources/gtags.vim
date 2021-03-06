
let s:save_cpo = &cpo
set cpo&vim

" source gtags/ref {{{
let s:ref = {
      \ 'name' : 'ref',
      \ 'description' : 'global with -rs option',
      \ 'enable_tree_matcher' : 1,
      \ 'hooks'  : {
         \'on_syntax' : function("unite#libs#gtags#on_syntax"),
         \'on_init'   : function("unite#libs#gtags#on_init_common"),
         \ },
      \ 'syntax' : "uniteSource__Gtags",
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:ref.option(args, context)
  if empty(a:args)
    let l:pattern = expand("<cword>")
  else
    let l:pattern = a:args[0]
  endif
  return {
        \'short': 'rs',
        \'long': '',
        \ 'pattern' : l:pattern ,
        \ }
endfunction
" }}}

" source gtags/def {{{
let s:def = {
      \ 'name' : 'def',
      \ 'description' : 'global with -d option',
      \ 'enable_tree_matcher' : 1,
      \ 'hooks'  : {
         \'on_syntax' : function("unite#libs#gtags#on_syntax"),
         \'on_init'   : function("unite#libs#gtags#on_init_common"),
         \ },
      \ 'syntax' : "uniteSource__Gtags",
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:def.option(args, context)
  if empty(a:args)
    let l:pattern = expand("<cword>")
  else
    let l:pattern = a:args[0]
  endif
  if empty(l:pattern)
    call unite#print_message("[unite-gtags] Warning: No word specified ")
    return []
  endif
  return {
        \'short': 'd',
        \'long': '',
        \'pattern' : l:pattern 
        \}
endfunction
" }}}

" source gtags/context {{{
let s:context = {
      \'name' : 'context',
      \ 'description' : 'global with --from-here option',
      \ 'enable_tree_matcher' : 1,
      \ 'hooks'  : {
         \'on_syntax' : function("unite#libs#gtags#on_syntax"),
         \'on_init'   : function("unite#libs#gtags#on_init_common"),
         \ },
      \ 'syntax' : "uniteSource__Gtags",
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:context.option(args, context)
  let l:pattern = expand("<cword>")
  if empty(l:pattern)
    call unite#print_message("[unite-gtags] Warning: No word exists on cursor ")
    return []
  endif
  let l:long = "--from-here=\"" . line('.') . ":" . expand("%") . "\""
  return {
        \'short': '',
        \'long': l:long,
        \'pattern' : l:pattern,
        \}
endfunction
"}}}

" source gtags/completion {{{
let s:completion = { 'name' : 'completion'}

function! s:completion.result(name, result, context)
  if empty(a:result)
    return []
  endif
  let l:symbols = split(a:result, '\r\n\|\r\|\n')
  return map(l:symbols, '{
        \ "source" : "gtags/completion",
        \ "description" : "global with -c option",
        \ "kind" : "gtags_completion",
        \ "word" : v:val,
        \ }')
endfunction

function! s:completion.option(args, context)
  if empty(a:args)
    let l:prefix = ''
  else
    let l:prefix = a:args[0]
  endif
  return {
        \ 'short': 'cs',
        \ 'long' : '',
        \ 'pattern' : l:prefix,
        \}
endfunction
" }}}

" source gtags/grep {{{
let s:grep = {
      \ 'name' : 'grep',
      \ 'description' : 'global with -g option',
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \ 'enable_tree_matcher' : 1,
      \ 'enable_syntax' : 1,
      \ 'hooks'  : {
         \'on_syntax' : function("unite#libs#gtags#on_syntax"),
         \ },
      \ 'syntax' : "uniteSource__Gtags",
      \}

function! s:grep.hooks.on_init(args, context)
  let a:context.is_treelized = 0
  let a:context.source__input = get(a:args, 0, '')
  if a:context.source__input == ''
    let a:context.source__input = unite#util#input('Pattern: ')
  endif
endfunction

function! s:grep.option(args, context)
  return {
        \ 'short': 'g',
        \ 'long' : '',
        \ 'pattern' : a:context.source__input,
        \}
endfunction
" }}}

let s:gtags_commands  = [
      \ s:ref,
      \ s:def,
      \ s:context,
      \ s:completion,
      \ s:grep,
      \]

function! unite#sources#gtags#define()
  let l:sources   = []
  for gtags_command in s:gtags_commands
    let l:source  = {
          \ 'name' : 'gtags/' . gtags_command.name,
          \ 'gtags_option' : gtags_command.option,
          \ 'gtags_result' : gtags_command.result,
          \ 'hooks' : has_key(gtags_command, 'hooks') ? gtags_command.hooks : {},
          \ }
    if has_key(gtags_command, 'enable_tree_matcher')
      let l:source['filters'] = ['gtags_tree_matcher']
    endif
    if has_key(gtags_command, 'syntax')
      let l:source['syntax'] = gtags_command.syntax
    endif
    function! l:source.gather_candidates(args, context)
      let l:options = self.gtags_option(a:args, a:context)
      if type(l:options) != type({})
        return []
      endif
      let l:result = unite#libs#gtags#exec_global(l:options.short, l:options.long, l:options.pattern)
      return self.gtags_result(self.name , l:result, a:context)
    endfunction
    call add(l:sources, l:source)
  endfor
  return l:sources
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

