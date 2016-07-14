#!/usr/bin/env ruby

# This script is licenced under the GNU GPL v3
# http://www.gnu.org/licenses/gpl-3.0.txt
# Copyright Henri Shustak 2010
# Lucid Information Systems : http://www.lucidsystems.org

# Description :
# -------------------------------------------
# This script will attempt the configuration of
# this systems assetname if the mac address and 
# assetnumber is availible within the input_data
# listed below. The @location will also become
# part of the assetname assigned to this system.
#
# This script is designed to work with Mac OS X
# 10.6.x and later systems
#
# Version 1.2

# History 
# 1.0 : early version (not working)
# 1.1 : initial release
# 1.2 : updates for later versions of ruby

# Interface Name 
@interface_name="en0"

# The @location will become part of the start of the name.
@location=""


@input_data="
-------------INPUT DATA---------------
"


# Input Data Example (commented out)
#@input_data="
#10:9A:DD:55:5E:7A	499381
#10:9A:DD:54:51:36	499382
#10:9A:DD:54:50:AE	499383
#10:9A:DD:31:58:68	499384
#10:9A:DD:98:4F:9B	499385
#10:9A:DD:98:6B:48	499386
#"


# Check we are running as root (if not then exit)
current_user = `whoami`
if "#{current_user.chomp}" != "root" then
   puts "ERROR! : This script must be executed with root privileges."
   exit
end

@new_assetname

def process_input_data
    # This hash will be used to store and lookup the input_data
    mac_to_assetnumber_hash = {}
    malformed_entreis_in_data = false

    # Parse the input data and insert this data into the mac_to_assetnumber_hash
    @input_data.split(/\n/).each do |input_line|
        if (input_line != "") && (input_line != "\n") then
            if (input_line.chomp.length > 0) then
                # line is not empty so lets treat it as input
                tab_seperated=input_line.split("	")
                if tab_seperated.length != 2 then
                    malformed_entreis_in_data = true
                end
                mac_address=tab_seperated[0].downcase
                asset_number=tab_seperated[1]
                if mac_address == nil || mac_address.length <= 0 || mac_address == "" || mac_address == "\n" then
                    malformed_entreis_in_data = true
                    next
                end
                if asset_number == nil || asset_number.length <= 0 || asset_number == "" || asset_number == "\n" then
                    malformed_entreis_in_data = true
                    next
                end
                # loads data into the MAC to assetname hash
                if ( mac_to_assetnumber_hash.has_key?("#{mac_address.chomp}") == false ) then
                    # Perhaps adding a to_s on the end of this is a good idea for input parsing
                    mac_to_assetnumber_hash["#{mac_address.chomp}"] = "#{asset_number.chomp}"
                else
                    puts "WARNING : Input data contained more than one data entry for a single MAC address."
                    puts "          The data associated with the first MAC address listed will be used."
                    puts ""
                end
            end
        end
    end
    
    # Report errors within data
    if malformed_entreis_in_data then
        puts "ERROR! : Errors were detected with the input data set."
        puts "         Please review the input data set and then execute the script again"
        puts "         The asset name of this machine will not be updated."
        puts "         Example Input Line : \"MAC-address(tab)Asset-number\""
        puts ""
        return false
    end   
    
    # Retrive this systems MAC address (perhaps there is a more approriate way)
    current_mac_address=`ifconfig #{@interface_name} | grep "ether " | awk -F "ether " '{print $2}'| awk '{print $1}'`
    
    # Check if this machines MAC address is located within the hash and if it is then load the approriate asset name.
    if current_mac_address != nil || current_mac_address.length > 0 && current_mac_address != "" && current_mac_address != "\n" then
        if mac_to_assetnumber_hash.has_key?("#{current_mac_address.chomp}") then
            # Lookup in the has and find the new_assetnumber for this system based upon the macaddress
            new_assetnumber = mac_to_assetnumber_hash["#{current_mac_address.chomp}"]
            if new_assetnumber == nil || new_assetnumber.length <= 0 || new_assetnumber == "" || new_assetnumber == "\n" then
                # No assent name needs to be set on this system because no assetnumber 
                # was specified for this system. This system will not have the name configured.
                puts "ERROR! : No asset number was specified within the input data for this"
                puts "         systems MAC address. The asset name of this machine will not be updated."
                puts "         System MAC Address (interface #{@interface_name}) : #{current_mac_address.chomp}"
                puts ""
                return false
            else
                # Calculate the assetname for this system
                if @location != "" then
                    @new_assetname = "#{@location}-#{new_assetnumber.chomp}"
                else
                    @new_assetname = "#{new_assetnumber.chomp}"
                end
                return true
            end
        else
            # No assent name needs to be set on this system because the MAC address
            # was not found within the input data. This system will not have the name configured.
            puts "ERROR! : This machines MAC address or an associated assetname was not listed in the input data."
            puts "         The asset name of this machine will not be updated."
            puts "         System MAC Address (interface #{@interface_name}) : #{current_mac_address.chomp}" 
            puts ""
            return false
        end
    else
        # No assent name needs to be set on this system because the MAC address
        # was not found within the input data. This system will not have the name configured.
        puts "ERROR! : Unable to determine this systems MAC address for interface #{@interface_name})"
        puts "        The asset name of this machine will not be updated."
        puts ""
        return false
    end
    puts "ERROR : Something went very wrong."
    puts "        The asset name of this machine will not be updated."
    puts ""
    return false
end



def setup_name
    
  # Keeps track of any issues during the configuarion of the machine name.
  error_setting_computer_name = "NO"
    
  # Set computer name 
	`/usr/sbin/systemsetup -setcomputername "#{@new_assetname.chomp}"`
	return_code = $?.to_i / 256
	if return_code != 0 then
	   puts "ERROR! : Unable to name set computer name using the following command :"
	   puts "         /usr/sbin/systemsetup -setcomputername \"#{@new_assetname.chomp}\""
     puts ""
     error_setting_computer_name = "YES"
  end

  # Set computer name 
	`/usr/sbin/systemsetup -setcomputername "#{@new_assetname.chomp}"`
	return_code = $?.to_i / 256
	if return_code != 0 then
	   puts "ERROR! : Unable to name set computer name using the following command :"
	   puts "         /usr/sbin/systemsetup -setcomputername \"#{@new_assetname.chomp}\""
     puts ""
     error_setting_computer_name = "YES"
  end

	
	# Set hostname - Displayed in the termninal
	`/bin/hostname "#{@new_assetname.chomp}"`
	return_code = $?.to_i / 256
	if return_code != 0 then
	   puts "ERROR! : Unable to name set hostname using the following command :"
	   puts "         /bin/hostname \"#{@new_assetname.chomp}\""
	   puts ""
	   error_setting_computer_name = "YES"
  end
	
	# Set in the systems subnet name
	`/usr/sbin/systemsetup -setlocalsubnetname "#{@new_assetname.chomp}.local"`
	return_code = $?.to_i / 256
	if return_code != 0 then
	   puts "ERROR! : Unable to name set local subnet name using the following command :"
	   puts "         /usr/sbin/systemsetup -setlocalsubnetname \"#{@new_assetname.chomp}.local\""
	   puts ""
	   error_setting_computer_name = "YES"
  end

    # Setting the name within the hosts config file is not a requirement in Mac OS X 10.6 so we do not 
    # convern ourselvs with doing this.
    
    # Report the staus of the machine name change.
    if error_setting_computer_name == "NO" then
        return true
    else
        return false
    end
    
end

# Logic and Return codes
if process_input_data then
    if setup_name then
        # Run it a second time (required for some unknowen reason?)
        if setup_name then
            exit 0
        else
            exit -1
        end
    else
        exit -1
    end
else
    exit -1
end




