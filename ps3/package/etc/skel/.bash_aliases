HISTSIZE=100000
EDITOR=vim
PS1='[\u@\h \W]\$ '
PS1='\[\033k\033\\\]'$PS1
export PS1 EDITOR

##if [ -d /cgroup/cpu/user ]; then
##    mkdir -m 0700 /cgroup/cpu/user/$$
##    echo $$ > /cgroup/cpu/user/$$/tasks
##    echo "1" > /cgroup/cpu/user/$$/notify_on_release
##    echo 512 > /cgroup/cpu/user/$$/cpu.shares
##fi
if [ -e /cgroup/blkio/tasks ]; then
    mkdir -m 0700 /cgroup/blkio/$$
    echo $$ > /cgroup/blkio/$$/tasks
    echo "1" > /cgroup/blkio/$$/notify_on_release
    echo 100 > /cgroup/blkio/$$/blkio.weight
fi

# perl extra
eval `perl -V:version`
PERL5LIB=$PERL5LIB:~/.perl5lib/share/perl/$version
PERL5LIB=$PERL5LIB:~/.perl5lib/lib/perl/$version
MANPATH=$MANPATH:~/.perl5lib/man

# python extra
PYTHONPATH=~/.pythonlib

# lua extra
LUA_PATH=~/.luarocks/share/lua/5.1/?.lua
LUA_CPATH=~/.luarocks/lib/lua/5.1/?.so

export PERL5LIB MANPATH PYTHONPATH LUA_PATH LUA_CPATH

function play (){
    url="$1"
    shift
    python ~/youtube-dl "$url" -o /dev/stdout -q|mplayer - -cache 8000 $*
}

export -f play
