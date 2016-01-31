get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value="$(tmux show-option -gqv "$option")"
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

is_osx() {
	[ $(uname) == "Darwin" ]
}

is_freebsd() {
	[ $(uname) == "FreeBSD" ]
}

is_linux() {
	[ $(uname) == "Linux" ]
}

is_cygwin() {
	command -v WMIC &> /dev/null
}

is_linux_iostat() {
	iostat -V &> /dev/null
}

cpus_number() {
	if is_linux; then
		nproc
	else
		sysctl -n hw.ncpu
	fi
}

command_exists() {
	local command="$1"
	command -v "$command" &> /dev/null
}
