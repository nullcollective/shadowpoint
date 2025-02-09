#!/usr/bin/env bash

# shadowpoint
# Ad-Hoc Encrypted Messaging
####################################################################
# Usage: ./shadowpoint.sh
# Depends on [age, zenity]
####################################################################
# Copyright 2025 nullcollective
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#---------------- USER CONFIG ----------------#
SHADOW_DIR="${HOME}/.shadowpoint"
personal_key="${SHADOW_DIR}/key.txt"
recipient_file="${SHADOW_DIR}/recipients.txt"

pastebin_api_key=""
pastebin_expiration="1H"
#---------------------------------------------#
# DO NOT EDIT BELOW THIS LINE
#---------------------------------------------#

VERSION="0.2.1"
HEADER="ShadowPoint Encryption v${VERSION}"

#---------------- FUNCTIONS ----------------#
init () {
    # Check to make sure age and zenity apps are installed
    if ! [[ -f /usr/bin/age && -f /usr/bin/zenity ]]; then
        echo "Check to ensure that age & zenity are installed" ; exit 1
    fi
    if ! [ -d "${SHADOW_DIR}" ]; then
        echo "Initializing ShadowPoint Directory ~/.shadowpoint"
        mkdir ${SHADOW_DIR}
    fi
}

add_recipient () {
    new_recipient=$(zenity --forms --title="Add Recipient" \
    --text="Enter Recipient Info" --separator="," \
	--add-entry="Name" \
	--add-entry="Public Key")

    new_user_name=$(echo ${new_recipient} | awk -F\, '{ print $1 }')
    new_user_key=$(echo ${new_recipient} | awk -F\, '{ print $2 }')

    if [[ -z ${new_recipient} ]]; then
        :
    else
        if [[ $new_user_key == age* ]]; then
            echo -e "# ${new_user_name}\n${new_user_key}" >> ${recipient_file}
        else
            zenity --warning --text="Incorrect Recipient Format"
        fi
    fi
}

list_recipients () {
    if ! [ -f ${recipient_file} ]; then
        zenity --warning --text="Recipient File Empty: \"${recipient_file}\""
    else
        zenity --width=900 --height=500 --text-info \
       --title="List of Available Recipient(s)" \
       --filename=${recipient_file}
    fi
}

encrypt_file () {
    # Recipient Selection
    list_users=`sed "s/^# /FALSE /g" ${recipient_file} | tr '\n' ' '`
    encrypt_recip=$(zenity --width=900 --height=500 --list --title="Select Recipient(s)" \
    --checklist --column "Check" --column="Name" --column="Public Key" \
    --separator=" -r " --print-column=3 ${list_users} 2>/dev/null)

    # Check if a recipient was selected
    if ! [ -n "${encrypt_recip}" ]; then
        :
    else
        # File Selection
        encrypt_filename=$(zenity --file-selection --title="Select a file to encrypt" 2>/dev/null)

        # Check if a file was selected
        if ! [ -n "${encrypt_filename}" ]; then
            :
        else
            # ENCRYPTION PROCESS
            age -o "${encrypt_filename}.age" -r ${encrypt_recip} "${encrypt_filename}"
            zenity --info --text="FILE ENCRYPTED: ${encrypt_filename}.age"
        fi
    fi
}

decrypt_file () {
    # File Selection
    decrypt_filename=$(zenity --file-selection --title="Select a file to encrypt" 2>/dev/null)
    file_type=$(file -b ${decrypt_filename} | awk -F\, '{ print $1 }')

    # Check if a file was selected & is an "age encrypted file"
    if ! [ -n "${decrypt_filename}" ]; then
        zenity --error --text="No File Selected!"
    elif ! [[ $file_type == "age encrypted file" ]]; then
        zenity --error --text="Selected File Not Encrypted!"
    else
        # Decrypt Using User's Key
        output_file=$(echo "${decrypt_filename}" | sed 's/.age//g')
        directory="$(dirname ${output_file})"
        age -d -o "${output_file}" -i ${personal_key} "${decrypt_filename}"

        # Display Decrypted File Location
        zenity --info --text="FILE DECRYPTED: ${output_file}"
    fi
}

generate_key () {
    if ! [ -f ${personal_key} ]; then
        # Get Users Name
        your_name=$(zenity --forms --title="Generate New Key" \
        --text="Enter Your Info" --add-entry="Name" | tr -d "[:space:]")

        if [ -n "$your_name" ]; then
            # Generate Key
            age-keygen -o ${personal_key}
            # Add Key to Recipient File
            echo -e "# ${your_name}\n$(age-keygen -y ${personal_key})" > ${recipient_file}

            zenity --width=900 --height=500 --text-info \
            --title="Personal Encryption Key Generated" \
            --filename=${personal_key}
        else
            zenity --warning --text="No Key Generated Due to Empty Name"
        fi
    else
        zenity --warning \
        --text="File \"${personal_key}\" exists, please manually delete this file and try again"
    fi
}

send_message() {
    # Recipient Selection
    list_users=`sed "s/^# /FALSE /g" ${recipient_file} | tr '\n' ' '`
    encrypt_recip=$(zenity --width=900 --height=500 --list --title="Select Recipient(s)" \
    --checklist --column "Check" --column="Name" --column="Public Key" \
    --separator=" -r " --print-column=3 ${list_users} 2>/dev/null)

    # Check if a recipient was selected
    if ! [ -n "${encrypt_recip}" ]; then
        :
    else
        # Enter Message
        message=$(zenity --forms --title="Send Encrypted Messge via PasteBin" \
	        --text="Enter Message" --add-entry="Message")

        # Check if a file was selected
        if ! [ -n "${message}" ]; then
            :
        else
            # Encrypt Message
            enc_message=$(echo "${message}" | age -r ${encrypt_recip} --armor)
            
            # Destroy Plain-Text Before cURL
            unset message

            # POST to Pastebin
            msg_post=$(curl -sX POST -d "api_dev_key=${pastebin_api_key}" \
            -d "api_paste_code=${enc_message}" -d "api_option=paste" \
            -d "api_paste_private=1" -d "api_paste_expire_date=${pastebin_expiration}"
            "https://pastebin.com/api/api_post.php")

            # Display cURL Output to User
            zenity --info --text="${msg_post}"
        fi
    fi
}

rcv_message() {
    # Check to ensure user's personal key is available
    if ! [ -f ${personal_key} ]; then
        zenity --warning \
        --text="Personal Key Does Not Exist, Please Ensure Your Key is Available"
    else
        paste_key=$(zenity --forms --title="Enter Pastebin ID of Message" \
	        --text="Enter ID" --add-entry="ID")
        # Check to ensure an ID value was entered
        if ! [ -n "${paste_key}" ]; then
            :
        else
            # Grab Encrypted Message From Pastebin
            enc_message=$(curl -s "https://pastebin.com/raw/${paste_key}")

            # Decrypt Message with User Key
            decrypted_msg=$(age -d -i ${personal_key})

            # Display cURL Output to User
            zenity --info --text="${decrypted_msg}"

            # Destroy Message Data
            unset enc_message
            unset decrypted_msg
        fi
    fi
}

reset () {
    zenity --warning \
    --text="Please manually delete the directory \"${SHADOW_DIR}\""
}

cmd_prompt () {
    shadow_cmd=$(zenity --width=900 --height=500 --list --title="${HEADER}" \
    --column "Task" --column="Description" --print-column=1 \
    List "List Available Recipient(s)" \
    Add "Add New Recipient" \
    Encrypt "Encrypt File to Selected Recipient(s)" \
    Decrypt "Decrypt File" \
    Generate "Generate New Key" \
    Send "Send Encrypted Message through Pastebin.com" \
    Receive "Receive & Decrypt Message through Pastebin.com" \
    Reset "Wipe Existing Recipient(s) and Key Files" 2>/dev/null)

    echo -e "${GREEN}"
    # Run Selected Function
    case $shadow_cmd in
    List)
        list_recipients;;
    Add)
        add_recipient;;
    Encrypt)
        encrypt_file;;
    Decrypt)
        decrypt_file;;
    Generate)
        generate_key;;
    Send)
        send_message;;
    Receive)
        rcv_message;;
    Reset)
        reset;;
    *)
        exit;;
    esac
    echo -e "${NC}"
}

#---------------- MAIN ----------------#
init
while true;do cmd_prompt ; done
