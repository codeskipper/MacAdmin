#!/bin/zsh

loggedInUser=$(stat -f '%Su' /dev/console)
uid=$(id -u "${loggedInUser}")

runAsUser() {
  launchctl asuser "${uid}" sudo -iu "${loggedInUser}" "$@"
}

registration_status=$(runAsUser /Applications/Workspace\ ONE\ Intelligent\ Hub.app/Contents/Resources/AadRegistrationTool.app/Contents/MacOS/AadRegistrationTool summary)

echo "${registration_status}"

/usr/local/bin/hubcli notify --title "Managed Device registration - status" --subtitle "status:" --info "$registration_status"

runAsUser pbcopy <<< $registration_status

exit 0
