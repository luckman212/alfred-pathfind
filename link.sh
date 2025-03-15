#!/bin/zsh --no-rcs

case $1 in
	create_symlink)
		ln -sf $PWD/pathfind.sh $dest_dir/pathfind
		;;
	create_usrlocalbin)
		mkdir -p /usr/local/bin
		chown $USER:staff /usr/local/bin
		chmod 0755 /usr/local/bin
		;;
esac
