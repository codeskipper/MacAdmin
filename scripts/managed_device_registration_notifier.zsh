#!/usr/bin/env zsh

# settings for transition from WS1 AadRegistrationTool to Microsoft InTune Company Portal
# for (Portal)SSO and Conditional Access registration
# See https://docs.omnissa.com/bundle/macOS-Device-ManagementVSaaS/page/PSSOEntra.html#enable_feature_flag_for_device_registration_and_compliance_with_entra_id_via_intune_company_portal
plistFile="/Library/Application Support/AirWatch/Data/com.ws1.hub.flags.plist"
featureFlag="MacOSConditionalAccessUsingCompanyPortalFeatureFlag"
if [ -e "$plistFile" ]; then
    echo "the plistFile [$plistFile] exists"
    featureFlagStatus=$(defaults read "$plistFile" "$featureFlag")
    # if featureFlag is set, we don't need to prompt the user, that will
    # be done by Company Portal SSO extension, so just bail out
    if [[ "$featureFlagStatus" == "1" ]]; then
        echo "AadRegistrationTool is N/A -moving to Microsoft Company Portal (P)SSO"
        exit 0
    else
        echo "setting to still use AadRegistrationTool is enabled"
    fi
else
    echo "the plistFile [$plistFile] does not exist, still using AadRegistrationTool"
fi

loggedInUser=$(stat -f '%Su' /dev/console)
uid=$(id -u "${loggedInUser}")

# Bail out if no regular user is logged in yet
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

registrationStatus=$(runAsUser /Applications/Workspace\ ONE\ Intelligent\ Hub.app/Contents/Resources/AadRegistrationTool.app/Contents/MacOS/AadRegistrationTool summary)

echo "${registrationStatus}"

if [[ "$registrationStatus" == "Not registered" ]]; then
    /usr/local/bin/hubcli notify --title "Managed Device registration required" --subtitle "Click here to register your device" --info "for Conditional Access to VPN, AccessIT and more to come" -actionbtn "Register" --script "open wsonehub://conditionalaccess?partner=microsoft"
fi

exit 0
