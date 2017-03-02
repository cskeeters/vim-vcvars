function! vcvars#Strip(str)
    return matchstr(a:str, '\S.*\n\@<!')
endfunction

function! vcvars#VcVars()
    let bufdir = fnamemodify(bufname('%'), ":p:h")

    let gitroot = vcvars#Strip(system("git -C ".l:bufdir." rev-parse --show-toplevel"))
    let isGit = v:shell_error == 0
    let hgroot = vcvars#Strip(system("hg --cwd ".l:bufdir." root"))
    let isHg = v:shell_error == 0

    " If one repo type is embeded in another, use the one with the longest path
    if l:isGit && l:isHg
        if strlen(l:gitroot) < strlen(l:hgroot)
            let isGit=0
        else
            let isHg=0
        endif
    endif

    if l:isHg
        let hgbranch = vcvars#Strip(system("hg --cwd ".l:bufdir." branch"))
        if v:shell_error != 0
            let hgbranch = ''
        endif

        return ['hg', l:hgroot, l:hgbranch]
    endif

    if l:isGit
        let gitbranch = vcvars#Strip(system("git rev-parse --abbrev-ref HEAD"))
        if v:shell_error != 0
            let gitbranch = ''
        endif

        return ['git', l:gitroot, l:gitbranch]
    endif

    return ['', '', '']
endfunction

" Cache for VcVars
function! vcvars#CVcVars()
    let reload=0
    if !exists("b:vcvars")
        let reload=1
    else
        " VcVars has been run, but may be stale
        if 'hg' ==# b:vcvars[0]
            if b:vctime != getftime(b:vcvars[1].'/.hg/branch')
                let reload=1
            endif
        endif
        if 'git' ==# b:vcvars[0]
            if b:vctime != getftime(b:vcvars[1].'/.git/HEAD')
                let reload=1
            endif
        endif
    endif

    if l:reload
        let b:vcvars = vcvars#VcVars()

        "set b:vctime to the modification time of the file that will change
        "when another branch is checked out
        if 'hg' ==# b:vcvars[0]
            let b:vctime = getftime(b:vcvars[1].'/.hg/branch')
        endif
        if 'git' ==# b:vcvars[0]
            let b:vctime = getftime(b:vcvars[1].'/.git/HEAD')
        endif
    endif

    return b:vcvars
endfunction
