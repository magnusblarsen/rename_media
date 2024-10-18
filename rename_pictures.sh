#!/bin/bash

# TODO: flag: keep file names

file_extensions_regex="jpg|jpeg|png|heic|mp4|mov"
keep_file_names=false

rename_file() {
	local file_info="$1" # Ex: 2007-05-05Billeroverførtmajmd07 001.jpg

	date=$(echo "$file_info" | sed -E "s/^([0-9]{4}-[0-9]{2}-[0-9]{2})(.*)$/\1/")
	file_path=$(echo "$file_info" | sed -E "s/^([0-9]{4}-[0-9]{2}-[0-9]{2})(.*)$/\2/")
	extension=${file_path##*.}

	number=1
	current_folder=$(dirname "$file_path")
	new_destination="$current_folder/$date ($number).$extension"

	while ls "${new_destination%.*}".* 1> /dev/null 2>&1; do
		((number++))
		new_destination="$current_folder/$date ($number).$extension"
	done

	mv "$file_path" "$new_destination"
}

find_file_info() {
	local file_name="$1"

	creation_date=$(exiftool -CreateDate -d "%Y-%m-%d %H:%M:%S" "$file_name")

	if [[ -n "$creation_date" ]]; then
		new_name="${creation_date} $1"
	fi

	echo "$new_name"
}

export -f find_file_info

home_folder=$(pwd)

for folder in "$@"; do
	echo "Looking in folder: $folder"
	cd "$folder" || exit

	sorted_files=$(find . -maxdepth 2 -type f | # Sometimes pictures are in subfolders
		grep -Ei ".*(${file_extensions_regex})$" | 
		xargs -I {} bash -c 'find_file_info "$@"' _ {} | sort | 
		sed -E "s/^Create Date *: ([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}:[0-9]{2}:[0-9]{2}) (.*)$/\1\3/") # Create Date    : 2006-07-14 21:58:38 ./Billeroverførtmajmd07 020.jpg

	IFS=$'\n'
	for file in $sorted_files; do
		rename_file "$file" || exit
	done;
	unset IFS

	cd "$home_folder" || exit
done;

echo "All done :)"
