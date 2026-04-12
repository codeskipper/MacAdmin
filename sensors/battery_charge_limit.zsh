#!/usr/bin/env zsh

# dig through the battery charging state file for battery charge limit and return the value
preference_file_path="/Library/Preferences/com.apple.powerd.charging.plist"
policies_key="policies"

# check if the preference file exists, if not return "Not installed"
if [[ ! -f "$preference_file_path" ]]; then
  echo "Not installed"
  exit 0
fi


# policies is stored as base64 plist data in this file
policies_b64=$(/usr/bin/plutil -extract "$policies_key" raw -o - "$preference_file_path" 2>/dev/null)
if [[ -z "$policies_b64" ]]; then
  echo "No battery charging policies set"
  exit 0
fi

# decode the base64 policies plist to a temp file for parsing
tmp_plist="/tmp/battery_charging_policies.plist"
printf '%s' "$policies_b64" | /usr/bin/base64 -D 2>/dev/null > "$tmp_plist"

if [[ ! -s "$tmp_plist" ]]; then
  echo "soclimit is NOT set"
  rm -f "$tmp_plist"
  exit 0
fi

# extract soclimit from the decoded NSKeyedArchiver plist
# $objects is the keyed archiver array; index 2 is the manualChargeLimit ChargeCtrlPolicy object
soclimit=$(/usr/bin/plutil -extract '$objects'.2.soclimit raw -o - "$tmp_plist" 2>/dev/null)
rm -f "$tmp_plist"

if [[ -n "$soclimit" ]]; then
  echo "$soclimit"
else
  echo "soclimit is NOT set"
fi

exit 0
