#!/bin/zsh

# if [[ ! -d "/Applications/Company Portal.app" ]]; then
#     echo "Company Portal not (yet) installed - exiting"
#     exit 0
# fi


loggedInUser=$(stat -f '%Su' /dev/console)
uid=$(id -u "${loggedInUser}")

if [[ "${loggedInUser}" == "loginwindow" ]]; then
    exit 0
elif [[ "${loggedInUser}" == "_mbsetupuser" ]]; then
    exit 0
elif [[ "${loggedInUser}" == "root" ]]; then
    exit 0
fi

runAsUser() {  
  launchctl asuser "${uid}" sudo -iu "${loggedInUser}" "$@"
}

registration_status=$(runAsUser /Applications/Workspace\ ONE\ Intelligent\ Hub.app/Contents/Resources/AadRegistrationTool.app/Contents/MacOS/AadRegistrationTool summary) 

echo "${registration_status}"

if [[ "$registration_status" == "Not registered" ]]; then
  /usr/local/bin/hubcli notify --title "Managed Device registration required" --subtitle "Click here to register your device" --info "for Conditional Access to VPN, AccessIT and more to come" -actionbtn "Register" --script "open wsonehub://conditionalaccess?partner=microsoft"
fi

exit 0

