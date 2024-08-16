#!/bin/zsh

loggedInUser=$(stat -f '%Su' /dev/console)
uid=$(id -u "${loggedInUser}")

runAsUser() {
  launchctl asuser "${uid}" sudo -iu "${loggedInUser}" "$@"
}


# execute AadRegistrationTool with leave
runAsUser /Applications/Workspace\ ONE\ Intelligent\ Hub.app/Contents/Resources/AadRegistrationTool.app/Contents/MacOS/AadRegistrationTool leave

# check status
registration_status=$(runAsUser /Applications/Workspace\ ONE\ Intelligent\ Hub.app/Contents/Resources/AadRegistrationTool.app/Contents/MacOS/AadRegistrationTool summary)
echo "${registration_status}"

# if [[ ! "$registration_status" == "Not registered" ]]; then
/usr/local/bin/hubcli notify --title "Managed Device registration - LEAVE" --subtitle "Status:" --info "$registration_status"
# fi

runAsUser pbcopy <<< $registration_status

exit 0

