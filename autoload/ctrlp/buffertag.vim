" =============================================================================
" File:          autoload/ctrlp/buffertag.vim
" Description:   Buffer Tag extension
" Maintainer:    Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_buftag') && g:loaded_ctrlp_buftag
	fini
en
let g:loaded_ctrlp_buftag = 1

let s:buftag_var = ['ctrlp#buffertag#init(s:crfile, s:crbufnr)',
	\ 'ctrlp#buffertag#accept', 'buffer tags', 'bft']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:buftag_var) : [s:buftag_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

fu! s:opts()
	let opts = {
		\ 'g:ctrlp_buftag_systemenc': ['s:enc', &enc],
		\ 'g:ctrlp_buftag_ctags_bin': ['s:bin', ''],
		\ 'g:ctrlp_buftag_types': ['s:usr_types', ''],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
endf
cal s:opts()

fu! s:bins()
	let bins = [
		\ 'ctags-exuberant',
		\ 'exuberant-ctags',
		\ 'exctags',
		\ '/usr/local/bin/ctags',
		\ '/opt/local/bin/ctags',
		\ 'ctags',
		\ 'ctags.exe',
		\ 'tags',
		\ ]
	if empty(s:bin)
		for bin in bins | if executable(bin)
			let s:bin = bin
			brea
		en | endfo
	el
		let s:bin = expand(s:bin, 1)
	en
endf
cal s:bins()

" s:types {{{2
let s:types = {
	\ 'asm'    : '%sasm%sasm%sdlmt',
	\ 'aspperl': '%sasp%sasp%sfsv',
	\ 'aspvbs' : '%sasp%sasp%sfsv',
	\ 'awk'    : '%sawk%sawk%sf',
	\ 'beta'   : '%sbeta%sbeta%sfsv',
	\ 'c'      : '%sc%sc%sdgsutvf',
	\ 'cpp'    : '%sc++%sc++%snvdtcgsuf',
	\ 'cs'     : '%sc#%sc#%sdtncEgsipm',
	\ 'cobol'  : '%scobol%scobol%sdfgpPs',
	\ 'eiffel' : '%seiffel%seiffel%scf',
	\ 'erlang' : '%serlang%serlang%sdrmf',
	\ 'expect' : '%stcl%stcl%scfp',
	\ 'fortran': '%sfortran%sfortran%spbceiklmntvfs',
	\ 'html'   : '%shtml%shtml%saf',
	\ 'java'   : '%sjava%sjava%spcifm',
	\ 'javascript': '%sjavascript%sjavascript%sf',
	\ 'lisp'   : '%slisp%slisp%sf',
	\ 'lua'    : '%slua%slua%sf',
	\ 'make'   : '%smake%smake%sm',
	\ 'pascal' : '%spascal%spascal%sfp',
	\ 'perl'   : '%sperl%sperl%sclps',
	\ 'php'    : '%sphp%sphp%scdvf',
	\ 'python' : '%spython%spython%scmf',
	\ 'rexx'   : '%srexx%srexx%ss',
	\ 'ruby'   : '%sruby%sruby%scfFm',
	\ 'scheme' : '%sscheme%sscheme%ssf',
	\ 'sh'     : '%ssh%ssh%sf',
	\ 'csh'    : '%ssh%ssh%sf',
	\ 'zsh'    : '%ssh%ssh%sf',
	\ 'slang'  : '%sslang%sslang%snf',
	\ 'sml'    : '%ssml%ssml%secsrtvf',
	\ 'sql'    : '%ssql%ssql%scFPrstTvfp',
	\ 'tcl'    : '%stcl%stcl%scfmp',
	\ 'vera'   : '%svera%svera%scdefgmpPtTvx',
	\ 'verilog': '%sverilog%sverilog%smcPertwpvf',
	\ 'vim'    : '%svim%svim%savf',
	\ 'yacc'   : '%syacc%syacc%sl',
	\ }

cal map(s:types, 'printf(v:val, "--language-force=", " --", "-types=")')

if executable('jsctags')
	cal extend(s:types, { 'javascript': { 'args': '-f -', 'bin': 'jsctags' } })
en

if type(s:usr_types) == 4
	cal extend(s:types, s:usr_types)
en
" Utilities {{{1
fu! s:validfile(fname, ftype)
	if ( !empty(a:fname) || !empty(a:ftype) ) && filereadable(a:fname)
		\ && index(keys(s:types), a:ftype) >= 0 | retu 1 | en
	retu 0
endf

fu! s:exectags(cmd)
	if exists('+ssl')
		let [ssl, &ssl] = [&ssl, 0]
	en
	if &sh =~ 'cmd\.exe'
		let [sxq, &sxq, shcf, &shcf] = [&sxq, '"', &shcf, '/s /c']
	en
	let output = system(a:cmd)
	if &sh =~ 'cmd\.exe'
		let [&sxq, &shcf] = [sxq, shcf]
	en
	if exists('+ssl')
		let &ssl = ssl
	en
	retu output
endf

fu! s:exectagsonfile(fname, ftype)
	let [ags, ft] = ['-f - --sort=no --excmd=pattern --fields=nKs ', a:ftype]
	if type(s:types[ft]) == 1
		let ags .= s:types[ft]
		let bin = s:bin
	elsei type(s:types[ft]) == 4
		let ags = s:types[ft]['args']
		let bin = expand(s:types[ft]['bin'], 1)
	en
	if empty(bin) | retu '' | en
	let cmd = s:esctagscmd(bin, ags, a:fname)
	if empty(cmd) | retu '' | en
	let output = s:exectags(cmd)
	if v:shell_error || output =~ 'Warning: cannot open' | retu '' | en
	retu output
endf

fu! s:esctagscmd(bin, args, ...)
	if exists('+ssl')
		let [ssl, &ssl] = [&ssl, 0]
	en
	let fname = a:0 == 1 ? shellescape(a:1) : ''
	let cmd = shellescape(a:bin).' '.a:args.' '.fname
	if exists('+ssl')
		let &ssl = ssl
	en
	if has('iconv')
		let last = s:enc != &enc ? s:enc : !empty($LANG) ? $LANG : &enc
		let cmd = iconv(cmd, &enc, last)
	en
	if empty(cmd)
		cal ctrlp#msg('Encoding conversion failed!')
	en
	retu cmd
endf

fu! s:process(fname, ftype)
	if !s:validfile(a:fname, a:ftype) | retu [] | endif
	let ftime = getftime(a:fname)
	if has_key(g:ctrlp_buftags, a:fname)
		\ && g:ctrlp_buftags[a:fname]['time'] >= ftime
		let data = g:ctrlp_buftags[a:fname]['data']
	el
		let data = s:exectagsonfile(a:fname, a:ftype)
		let cache = { a:fname : { 'time': ftime, 'data': data } }
		cal extend(g:ctrlp_buftags, cache)
	en
	let [raw, lines] = [split(data, '\n\+'), []]
	for line in raw | if len(split(line, ';"')) == 2
		cal add(lines, s:parseline(line))
	en | endfo
	retu lines
endf

fu! s:parseline(line)
	let eval = '\v^([^\t]+)\t(.+)\t\/\^(.+)\$\/\;\"\t(.+)\tline(no)?\:(\d+)'
	let vals = matchlist(a:line, eval)
	if empty(vals) | retu '' | en
	retu vals[1].'	'.vals[4].'|'.vals[6].'| '.vals[3]
endf
" Public {{{1
fu! ctrlp#buffertag#init(fname, bufnr)
	sy match CtrlPTabExtra '\zs\t.*\ze$'
	hi link CtrlPTabExtra Comment
	retu s:process(a:fname, get(split(getbufvar(a:bufnr, '&ft'), '\.'), 0, ''))
endf

fu! ctrlp#buffertag#accept(mode, str)
	cal ctrlp#exit()
	if a:mode == 't'
		tab sp
	elsei a:mode == 'h'
		sp
	elsei a:mode == 'v'
		vs
	en
	cal ctrlp#j2l(str2nr(matchstr(a:str, '^[^\t]\+\t\+[^\t|]\+|\zs\d\+\ze|')))
endf

fu! ctrlp#buffertag#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
