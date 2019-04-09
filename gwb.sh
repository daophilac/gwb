#!/bin/bash

express_mode=false
check_icoutils_command=$(command -v wrestool)
set_icon=false
new_icon_path=""
copy_to_desktop=false
use_default_out_directory=true
output_directory="/home/$USER/Backdoor/"
input_file_path=""
input_filename=""
use_default_output_filename=true
output_filename=""
comment=""
app_type=""



check_wine_command=$(command -v wine)
if [ "$check_wine_command" = "" ]; then
	echo 'This application is about to make shortcut for .exe file. So please consider installing Wine first'
fi

read -p 'Advanced or Express? [a/x] ' user_select
if [[ (${user_select::1} = 'a') || (${user_select::1} = 'a') ]]; then

	# Section 1: get input file from user
	while true; do
		read -p 'Input .exe file: ' input_file_path
		if [ "${input_file_path::1}" = "'" ]; then
			input_file_path=${input_file_path//"'"}
		fi
		# echo 'input_file_path = '$input_file_path
		input_filename=$(basename -- "$input_file_path")
		# echo 'input_filename = '$input_filename
		extension="${input_filename##*.}"
		# echo 'extension = '$extension
		input_filename="${input_filename%.*}"
		# echo 'input_filename = '$input_filename
		if [[ ($extension != 'exe') && ($extension != "exe'") ]]; then
			echo 'That is not a .exe file' # test case 1: check whether user give true .exe file or not ----------OK
		else
			break
		fi
	done
	# End of section 1





	# Section 2: check whether icoutils is installed
	if [ "$check_icoutils_command" = "" ]; then
		read -p 'icoutils has not been installed yet. icoutils helps you to extract icon from .exe file. Do you want to install it? [Y/n] ' user_select
		if [[ (${user_select::1} = 'y') || (${user_select::1} = 'Y') ]]; then
			sudo apt-get install icoutils
			set_icon=true
			# echo 'set_icon = '$set_icon # test case 2: icoutils hasn't been installed, user choose yes to install it ----------OK
		else
			set_icon=false
			# echo 'set_icon = '$set_icon # test case 3: icoutils hasn't been installed, user choose no to not install it ----------OK
		fi
	else
	    	set_icon=true
		# echo 'set_icon = '$set_icon # test case 4: icoutiles has already been installed -----------OK
	fi
	# End of section 2





	# Section 3: ask user whether he wants to use the default output directory
	read -p 'Do you want to use the default output directory? [Y/n] ' user_select
	if [[ (${user_select::1} = 'y') || (${user_select::1} = 'Y') ]]; then
		use_default_out_directory=true
		# echo 'use_default_out_directory = '$output_directory # test case 5: user choose yes to use the default output directory -----------OK
	else
		read -p 'So what is your output directory? ' output_directory
		use_default_out_directory=false
		# echo 'use_default_out_directory = '$output_directory # test case 6: user choose no to use his own output directory ----------OK
	fi

	if [ ! -d "$output_directory" ]; then
  		mkdir -p "$output_directory"
	fi
	# End of section 3





	# Section 4: ask user whether he wants to keep the output file as the original one
	read -p 'Do you want to keep the output file name as the original one? [Y/n] ' user_select
	if [[ (${user_select::1} = 'y') || (${user_select::1} = 'Y') ]]; then
		output_filename=$input_filename
		# echo 'output_filename = '$output_filename # test case 7: user choose yes to keep the output file as the original one ----------OK
	else
		read -p 'So what new file name? (without extension) ' output_filename
		# echo 'output_filename = '$output_filename # test case 8: user choose no to not keep the output file as the original one ----------OK
	fi
	# End of section 4




	# Section 5: ask user whether he wants to copy output file to the desktop
	read -p 'Do you want to copy output file to the desktop? [Y/n] ' user_select
	if [[ (${user_select::1} = 'y') || (${user_select::1} = 'Y') ]]; then
		copy_to_desktop=true
	else
		copy_to_desktop=false
	fi
	# End of section 5





	# Section 6: extract all resources from .exe file
	if [ ! -d "$output_directory""$output_filename""_resources" ]; then
		mkdir -p "$output_directory""$output_filename""_resources"
	fi
	wrestool -o "$output_directory""$output_filename""_resources" -x "$input_file_path" --raw
	echo "All resources of .exe file were extracted into ""$output_directory""$output_filename""_resources"
	# End of section 6





	# Section 7: ask user whether he wants to set new icon
	read -p "What is icon for this shortcut. Just leave it blank if you don't want to specify " new_icon_path
	if [ "${new_icon_path::1}" = "'" ]; then
		new_icon_path=${new_icon_path//"'"}
	fi
	# End of section 7






	# Section 8: ask user to give the app a comment
	read -p 'What is your comment about this application? ' comment
	# End of section 8

	# Section 9: ask user to give the app a type
	read -p 'What is the type of this application? ' app_type
	# End of section 9


	# Section 10: generate output files
	# Section 10.1: generate .sh file
	sh_file=$output_directory$output_filename'.sh'
	echo '#!/bin/bash' > $sh_file
	echo 'bash_file=$(basename $BASH_SOURCE)' >> $sh_file
	echo 'filename=${bash_file%.*}' >> $sh_file
	echo 'echo "Ready to start" $filename"."' >> $sh_file
	echo "wine '"$input_file_path"'" >> $sh_file
	echo 'echo $filename "terminated."﻿﻿' >> $sh_file
	chmod +x $sh_file
	# End of section 10.1



	# Section 10.2: generate .ico file if user choose to do that
	icon_file=""
	if [ $set_icon = true ]; then
		if [ "$new_icon_path" = "" ]; then
			icon_file=$output_directory$output_filename'.ico'
			wrestool -x -t 14 "$input_file_path" > $icon_file
		else
			icon_file=$new_icon_path
			cp "$new_icon_path" "$output_directory"
		fi
	fi
	# End of section 10.2

	# Section 10.3: generate .desktop file
	desktop_file=$output_directory$output_filename'.desktop'
	echo '[Desktop Entry]' > $desktop_file
	echo 'Encoding=UTF-8' >> $desktop_file
	echo 'Version=1.0' >> $desktop_file
	echo 'Name='$output_filename >> $desktop_file
	echo 'Comment='$comment >> $desktop_file
	echo 'Exec='$sh_file >> $desktop_file
	echo 'Icon='$icon_file >> $desktop_file
	echo 'Terminal=false' >> $desktop_file
	echo 'Type=Application' >> $desktop_file
	echo 'Categories='$app_type';' >> $desktop_file
	chmod +x $desktop_file
	# End of section 10.3
	# End of section 10


	# Section 11: copy output file to desktop if user choosed to do that
	if [ $copy_to_desktop = true ]; then
		cp "$desktop_file" "/home/$USER/Desktop/"$output_filename".desktop"
	fi
	# End of section 11
	
else
	# Section 1: get input file from user
	while true; do
		read -p 'Input .exe file: ' input_file_path
		if [ "${input_file_path::1}" = "'" ]; then
			input_file_path=${input_file_path//"'"}
		fi
		# echo 'input_file_path = '$input_file_path
		input_filename=$(basename -- "$input_file_path")
		# echo 'input_filename = '$input_filename
		extension="${input_filename##*.}"
		# echo 'extension = '$extension
		input_filename="${input_filename%.*}"
		# echo 'input_filename = '$input_filename
		if [[ ($extension != 'exe') && ($extension != "exe'") ]]; then
			echo 'That is not a .exe file' # test case 1: check whether user give true .exe file or not ----------OK
		else
			break
		fi
	done
	# End of section 1



	# Section 2: check whether icoutils is installed. If isn't, install it
	if [ "$check_icoutils_command" = "" ]; then
		sudo apt-get install icoutils
	fi
	# End of section 2
	
	
	# Section 3: check if directory exists. If it doesn't, make it
	if [ ! -d "$output_directory" ]; then
  		mkdir -p "$output_directory"
	fi
	# End of section 3
	

	# Section 4: generate output files
	# Section 4.1: generate .sh file
	output_filename=$input_filename
	sh_file=$output_directory$output_filename'.sh'
	echo '#!/bin/bash' > $sh_file
	echo 'bash_file=$(basename $BASH_SOURCE)' >> $sh_file
	echo 'filename=${bash_file%.*}' >> $sh_file
	echo 'echo "Ready to start" $filename"."' >> $sh_file
	echo "wine '"$input_file_path"'" >> $sh_file
	echo 'echo $filename "terminated."﻿﻿' >> $sh_file
	chmod +x $sh_file
	# End of section 4.1


	# Section 4.2: generate .ico file if user choose to do that
	icon_file=$output_directory$output_filename'.ico'
	wrestool -x -t 14 "$input_file_path" > $icon_file
	# End of section 4.2


	# Section 4.3: generate .desktop file
	desktop_file=$output_directory$output_filename'.desktop'
	echo '[Desktop Entry]' > $desktop_file
	echo 'Encoding=UTF-8' >> $desktop_file
	echo 'Version=1.0' >> $desktop_file
	echo 'Name='$output_filename >> $desktop_file
	echo 'Comment='$comment >> $desktop_file
	echo 'Exec='$sh_file >> $desktop_file
	echo 'Icon='$icon_file >> $desktop_file
	echo 'Terminal=false' >> $desktop_file
	echo 'Type=Application' >> $desktop_file
	echo 'Categories='$app_type';' >> $desktop_file
	chmod +x $desktop_file
	# End of section 4.3
	# End of section 4


	# Section 5: copy output file to desktop if user choosed to do that
	cp "$desktop_file" "/home/$USER/Desktop/"$output_filename".desktop"
	# End of section 5
fi
