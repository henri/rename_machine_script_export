
----------------------------------------
 README : rename_machine_script_export
----------------------------------------

This directory contains various files and programs including the build_output_file.bash script which you execute to start the process.

This tool is designed to run on OS X. However, if you are not building packages then it will probably work on most systems with ruby and GNU tools installed. It is possible that some modification will be required to get it to work on some systems.

Note regarding line endings. It is possible to script around this with various tools. However, if you are moving files between systems or say out of filemaker, then it is recommended that you download a copy of 'flip.osx' and place that into this directory. Links follow : 

  - https://ccrma.stanford.edu/~craig/utility/flip/
  - http://flip.darwinports.com/

The input data file should be called : machine_name_and_ethernet_id_list_tmp

Importantly, this file should be located within the '../tmp', relative from this readme.txt files parent directory.

This input data is a tab separated list of mac addresses (including colons - first column) and of the assetnames (second column) or assetnumbers (second column). tThere is an example of input data provided within the 'set_assetname_from_mac_address.rb' script.

This system is very basic and will probably require modification for your purposes.

