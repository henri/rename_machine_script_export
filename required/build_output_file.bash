#!/usr/bin/env bash
#
# Released under the GNU GPL v3 or later
# Copyright Henri Shustak 2011
#
# This script will use the output data of machine names and will generator a script which may be used to set the machine names.
#
# If you pass in a reverse domain, you have luggage installed and are running as super user then the script
# will attempt to generate an install package for the output script.
#
#
# Script version 1.1
#
#    Script history  
#       1.0 : initial release
#       1.1 : fixed issue relating to spaces in path to script
#

# determine the absolute path to the parent directory to this script
parent_directory=`dirname "${0}"`
cd "${parent_directory}"
cd ..
project_root_dir=`pwd`

# setup some input and output files (note you must have the correct directory - very little checking is performed) etc.
output_file_path="${project_root_dir}/output/rename_based_upon_mac_address.rb"
flip_path="${project_root_dir}/required/flip.osx"
input_data_file="${project_root_dir}/tmp/machine_name_and_ethernet_id_list_tmp"
input_script_file="${project_root_dir}/required/set_assetname_from_mac_address.rb"
script_split_file_prefix="${project_root_dir}/tmp/script_part."
script_part_a="${script_split_file_prefix}a"
script_part_b="${script_split_file_prefix}b"
tmp_file_for_line_deletion=`mktemp /tmp/build_machine_name_output.XXXX`
current_user=`whoami`
package_source_directory="${project_root_dir}/tmp/source_package"
package_post_flight_script="${package_source_directory}/postflight"
package_reverse_domain=`echo "${1}" | awk '{print $1}'`
package_makefile_template="${project_root_dir}/required/Makefile_template"
package_makefile="${package_source_directory}/Makefile"
output_package_dmg="${project_root_dir}/output/rename_based_upon_mac_address.dmg"



# check the input file is available 
if ! [ -e "${input_script_file}" ] ; then
	echo "ERROR! : No input script file detected within the file system :"
	echo "         ${input_script_file}"
	exit -1
fi

# check the input data file is available
if ! [ -e "${input_data_file}" ] ; then
	echo "ERROR! : No input script file detected within the file system :"
	echo "         ${input_data_file}"
	exit -1
fi

# split the data into two files (we will insert the data between them in a moment).
split -a 1 -p "-------------INPUT DATA---------------" "${input_script_file}" "${script_split_file_prefix}"


# remove the input data line from the top of the second part of the script
tail -n +2 "${script_part_b}" > "${tmp_file_for_line_deletion}"
rm "${script_part_b}"
cp "${tmp_file_for_line_deletion}" "${script_part_b}"
rm "${tmp_file_for_line_deletion}"

# okay suggestions on improving that are welcome - it is horrid.

# if flip is present within the required directory then use it to convert the input to unix line endings
if [ -e "${flip_path}" ] ; then
	"${flip_path}" -u "${input_data_file}"
fi

# first part of the output script
cat "${script_part_a}" > "${output_file_path}"

# data export from some input source (eg. database, spreadsheet text file) 
cat "${input_data_file}" >> "${output_file_path}"

# final part of the script 
cat "${script_part_b}" >> "${output_file_path}"
chmod 755 "${output_file_path}"

# clean up the part files
rm "${script_part_b}" "${script_part_a}"
if [ $? != 0 ] ; then
	echo "    ERROR! : Error removing the split script component files. Check permissions."
	echo "             - \"${script_part_a}\""
	echo "             - \"${script_part_b}\""
	exit -1
fi

# If a reverse domain was provided (currently no input validation) then proceed to build the install package.
if [ "${package_reverse_domain}" != "" ] ; then

	# Check if the luggage is installed (pretty - basic - this could use some work)
	if [ -d /usr/local/share/luggage/ ] ; then

		# Check we are running as root for package generation.
		if [ "${current_user}" != "root" ] ; then
			echo "    ERROR! : Superuser privileges are required when using the luggage"
			echo "             for package generation at present."
			exit -1
		fi

		echo " -  preparing to build package…"

		# setup the package source directory
		if [ -d "${package_source_directory}" ] ; then 
			rm -R "${package_source_directory}"
		fi
		mkdir "${package_source_directory}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : creating source directory for package creation :"
			echo "             ${package_source_directory}"
			exit -1
		fi

		# copy the script into the source directory and name it postflight
		cp "${output_file_path}" "${package_post_flight_script}"
		chmod 755 "${package_post_flight_script}"

		# copy the makefile template into the package source directory.
		tmp_package_makefile=`mktemp /tmp/build_machine_name_makefile.XXXX`
		sed s/XXXXXXXXXXX/${build_version}/g "${package_makefile_template}" > "${tmp_package_makefile}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : Unable to update the makefile for this package : "
			echo "             ${tmp_package_makefile}"
			exit -1
		fi
		cp "${tmp_package_makefile}" "${package_makefile}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : Unable to copy the temporary make file into position in the source directory :"
			echo "             ${package_makefile}"
			exit -1
		fi
		rm -f "${tmp_package_makefile}"

		cd "${package_source_directory}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : Unable to change directory into the source directory :"
			echo "             ${package_source_directory}"
			exit -1
		fi

		echo " -  building package…"
		make dmg > /dev/null
		if [ $? != 0 ] ; then
			echo "    ERROR! : Package building failed :"
			echo "             ${package_source_directory}"
			exit -1
		fi
		
		# locate the dmg output from luggage (probably a better way) - name the file in the template?
		first_dmg_found_within_package_source=`ls "${package_source_directory}"/*.dmg | head -n 1`
		if ! [ -f "${first_dmg_found_within_package_source}" ] ; then
			echo "    ERROR! : Unable to locate the built package : "
			echo "             ${first_dmg_found_within_package_source}"
			exit -1
		fi

		# remove any exiting .dmg file (not nessasary but not a bad idea).
		if [ -d "${output_package_dmg}" ] ; then 
			rm -R "${output_package_dmg}"
			if [ $? != 0 ] ; then
				echo "    ERROR! : Removing the previous output package (.dmg) :"
				echo "             ${output_package_dmg}"
				exit -1
			fi
		fi		

		# copy the package file to the output directory (copy is performed incase you are running on a broken system).
		cp "${first_dmg_found_within_package_source}" "${output_package_dmg}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : Copying the package into the output directory : "
			echo "             ${first_dmg_found_within_package_source}"
			exit -1
		fi

		# Clean up the package_source directory
		rm -R "${package_source_directory}"
		if [ $? != 0 ] ; then
			echo "    ERROR! : Cleaning up the package source directory : "
			echo "             ${first_dmg_found_within_package_source}"
			exit -1
		fi
		
		# Report the package is ready 
		echo " -  package (.dmg) ready for collection from output directory : "
		echo "    ${output_package_dmg}"

	else
		echo "    ERROR! : Unable to detect the luggage as installed on this system."
		echo "             Visit the following URL : http://luggage.apesseekingknowledge.net/"
		exit -1
	fi
fi

exit 0





