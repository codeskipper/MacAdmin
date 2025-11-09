# Google Chrome - TEST settings to dispel the account picker shown when visiting sites that use MS Entra federated ID

# AI prompt
# how can I automatically select the main account in the dialog to pick an account for the entra id provider in chrome on a mac


# Set the default account for Entra ID provider
# defaults write com.google.Chrome AccountConsistencyMirrorRequired -bool true

# AccountConsistency (suppress account picker)
defaults write com.google.Chrome AccountConsistency -string "disabled"

# Force a specific sign-in pattern
defaults write com.google.Chrome BrowserSignin -int 2
# defaults write com.google.Chrome RestrictSigninToPattern -string ".*@yourdomain\.com"
# Tested, causes Chrome to crash at startup

# Or to set a specific account email
defaults write com.google.Chrome SigninInterceptionIDPCookieURL -string "https://login.microsoftonline.com"
# defaults write com.google.Chrome AutoSelectCertificateForUrls -array-add -dict pattern "https://[*.]microsoftonline.com" filter '{"ISSUER":{"CN":"Your Organization"}}'
defaults write com.google.Chrome AutoSelectCertificateForUrls -array-add -dict pattern "https://[*.]microsoftonline.com" filter '{"ISSUER":{"CN":"Equinor"}}'

# Set the profile email to auto-select
defaults write com.google.Chrome ProfilePickerOnStartupAvailability -int 0


