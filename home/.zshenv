# Timezone
export TZ=America/Los_Angeles

# Language settings
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Disable brew analytics
export HOMEBREW_NO_ANALYTICS=1

# Enable `ls` colors
export CLICOLOR=1

# Set XDG values
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

if [ -f "/usr/local/bin/brew" ]; then
    eval $(/usr/local/bin/brew shellenv)
fi

if [ -f "/opt/homebrew/bin/brew" ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

if [ -d "$HOMEBREW_PREFIX/opt/mysql-client/bin" ]; then
    path+=$HOMEBREW_PREFIX/opt/mysql-client/bin
fi

# JAVA_HOME_<version> points at an installed JDK for that version.
# Versions with no installed JDK stay unset.
for _jdk_version in 8 11 17 21 25; do
    unset "JAVA_HOME_$_jdk_version"

    _jdk_home=
    if [[ "$OSTYPE" == darwin* ]] && [[ -x /usr/libexec/java_home ]]; then
        _jdk_selector=$_jdk_version
        [[ "$_jdk_version" == 8 ]] && _jdk_selector=1.8
        _jdk_home=$(/usr/libexec/java_home -v "$_jdk_selector" 2>/dev/null)
    fi

    _jdk_candidates=(
        /usr/lib/jvm/java-$_jdk_version-amazon-corretto*(N-/)
        /usr/lib/jvm/java-$_jdk_version-openjdk*(N-/)
        /usr/lib/jvm/java-$_jdk_version(N-/)
    )

    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        _jdk_candidates+=(
            "$HOMEBREW_PREFIX/opt/openjdk@$_jdk_version/libexec/openjdk.jdk/Contents/Home"
            "$HOMEBREW_PREFIX/opt/openjdk@$_jdk_version"
        )
    fi

    for _jdk_candidate in "$_jdk_home" "${_jdk_candidates[@]}"; do
        _jdk_home=$_jdk_candidate
        if [[ -n "$_jdk_home" ]] && [[ -x "$_jdk_home/bin/javac" ]]; then
            typeset -gx "JAVA_HOME_$_jdk_version=$_jdk_home"
            break
        fi
    done
done

unset JAVA_HOME_LATEST JAVA_HOME

_jdk_home=
if [[ "$OSTYPE" == darwin* ]] && [[ -x /usr/libexec/java_home ]]; then
    _jdk_home=$(/usr/libexec/java_home 2>/dev/null)
fi

_jdk_candidates=()
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    _jdk_candidates+=(
        "$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
        "$HOMEBREW_PREFIX/opt/openjdk"
    )
fi
_jdk_candidates+=(
    /usr/lib/jvm/java(N-/)
    "$JAVA_HOME_25"
    "$JAVA_HOME_21"
    "$JAVA_HOME_17"
    "$JAVA_HOME_11"
    "$JAVA_HOME_8"
)

for _jdk_candidate in "$_jdk_home" "${_jdk_candidates[@]}"; do
    _jdk_home=$_jdk_candidate
    if [[ -n "$_jdk_home" ]] && [[ -x "$_jdk_home/bin/javac" ]]; then
        export JAVA_HOME_LATEST=$_jdk_home
        export JAVA_HOME=$_jdk_home
        break
    fi
done

if [[ -n "$JAVA_HOME" ]]; then
    path=("$JAVA_HOME/bin" ${path:#"$JAVA_HOME/bin"})
fi

unset _jdk_version _jdk_selector _jdk_home _jdk_candidate _jdk_candidates

if [ ! -d "$HOME/.nvm" ]; then
  mkdir ~/.nvm
fi

export NVM_DIR="$HOME/.nvm"

if [ -d "$HOME/go/bin" ]; then
    path+=$HOME/go/bin
fi

if [ -d "$HOMEBREW_PREFIX/opt/go" ]; then
    export GOPATH="${HOME}/.go"
    export GOROOT=$(brew --prefix golang)/libexec
    path+=$GOROOT/bin
    path+=$GOPATH/bin
fi

if [ -d "$HOME/.npm/bin" ]; then
    path+=$HOME/.npm/bin
fi

if [ -d "$HOME/.local/bin" ]; then
    path+=$HOME/.local/bin
fi

if [ -d "$HOME/.npm-global/bin" ]; then
    path+=$HOME/.npm-global/bin
fi

if [ -d "$HOME/nvim/bin" ]; then
    path+=$HOME/nvim/bin/
fi

if [ -f "$HOME/.zshenv.local" ]; then
    source "$HOME/.zshenv.local"
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
