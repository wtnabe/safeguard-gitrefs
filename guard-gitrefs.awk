#! /usr/bin/awk -f

#
# git server-side `update' hook for guarding important branches
#

#
# Usage: guard-gitrefs.awk -v config=<config file name> -v currev=<current rev> -v newrev=<new rev> -v ref=<ref> commit
#
# Example:
#
# put this line in hooks/update
#
# /usr/bin/awk -f /var/repos/guard-gitrefs.awk -v config=/var/repos/guard-gitrefs -v ref=$1 -v currev=$2 -v newrev=$3
#
# References:
#
# * http://git-scm.com/book/en/Git-Internals-Transfer-Protocols
# * http://stackoverflow.com/questions/1754491/is-there-a-way-to-configure-git-repository-to-reject-git-push-force
# * http://git-scm.com/docs/git-merge-base
#

BEGIN {
    read_config(config)
    if ( will_be_deleted(newrev) && denied("[deny.delete]", ref) ) {
        print "deny_delete"
        exit 1
    }
    if ( will_be_pushed_force(currev, newrev) && denied("[deny.push-force]", ref) ) {
        print "deny_push_force"
        exit 1
    }

    exit 0
}

#
# [param]  string filename
# [return] array
#
function read_config(filename) {
    section = ""
    while ( getline < filename ) {
        if ( match($1, /^\[.*\]$/) ) {
            section = substr($1, RSTART, RLENGTH)
            cnt     = 0
            continue
        }
        deny[section,cnt] = $1
        cnt++
    }
}

#
# [param]  string ref
# [return] boolean
#
function denied(section, ref) {
    for ( i in deny ) {
        if ( index(i, section) && deny[i] == ref ) return 1
    }
}

#
# [param]  newrev
# [return] boolean
#
function will_be_deleted(newrev) {
    return newrev == "0000000000000000000000000000000000000000"
}

#
# [param]  oldrev
# [return] boolean
#
function will_be_added(oldrev) {
    return oldrev == "0000000000000000000000000000000000000000"
}

#
# [param]  string oldrev
# [param]  string newrev
# [return] boolean
#
function will_be_pushed_force(oldrev, newrev) {
    if ( !will_be_deleted(newrev) && !will_be_added(oldrev) ) {
        cmd = "git merge-base " oldrev " " newrev
        cmd | getline mergebase

        return mergebase != oldrev
    }
}
