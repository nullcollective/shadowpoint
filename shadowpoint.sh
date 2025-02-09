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

VERSION="0.2.2"
HEADER="ShadowPoint Encryption v${VERSION}"

# Source Functions Script
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/functions.sh

#---------------- MAIN ----------------#
init
while true;do cmd_prompt ; done
