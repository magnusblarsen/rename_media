#!/bin/bash

# TODO: flag: keep file names

file_extensions_regex="jpg|jpeg|png|heic|mp4|mov"

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


home_folder=$(pwd)

for folder in "$@"; do
	echo "Looking in folder: $folder"
	cd "$folder" || exit

	sorted_files=$(find . -maxdepth 2 -type f | # Sometimes pictures are in subfolders
		grep -Ei ".*(${file_extensions_regex})$" | 
		xargs -d '\n' stat -c "%y %n" | sort | # Ex: 2007-05-05 18:22:15.000000000 +0200 ./Billeroverførtmajmd07 020.jpg
		sed -E "s/^([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{9} (\+|\-)[0-9]{4}) (.*)$/\1\4/")

	IFS=$'\n'
	for file in $sorted_files; do
		rename_file "$file" || exit
	done;
	unset IFS

	cd "$home_folder" || exit
done;

echo "All done :)"
