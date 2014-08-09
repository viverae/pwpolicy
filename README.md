pwpolicy
========

Manage local pwpolicy on OS X

### pwpolicyPerUser

These settings control password policy requirements.

- `maxFailedLoginAttempts='5'` - Number of times a user can try to login unsuccessfully before their account is locked.
- `requiresAlpha='1'` - Requires user password to contain alphabetic characters.
- `requiresNumeric='1'` - Requires user password to contain numeric characters.
- `minChars='8'` - Sets the minimum number of total characters required for a user's password.
- `usingHistory='4'` - This sets the number of previous passwords your computer will remember. When a user changes their password, they are not allowed to reuse a previous one within this range.
- `exemptAccount='admin'` - The shortname of an account you want to be exempt from password policies.
- `pwpolicyDir='/Library/OneHealth/Partners/Library'` - The directory where the scripts and other information should be kept.

### PasswordAgeCheck

- `warnAge="15552000"` - The age in seconds before users start to receive warnings about password age.
- `maxAge="18144000"` - The age in seconds before users start to receive prompts to reset their passwords immediately.
- `termNotifierPath='/Library/OneHealth/terminal-notifier.app/Contents/MacOS/terminal-notifier'` - The path on the system to the terminal-notifier binary for notifications.
- `companyName='OneHealth'` - The name of your company.
- `exemptAccount='admin'` - The shortname of an account you want to be exempt from password age checking.
- `expirationTime='2592000'` - The number of seconds after $maxAge that account lockout happens.

## Authors

* Todd Thoule
* Taylor Price - tprice@onehealth.com

## Copyright

Copyright:: 2014, OneHealth Solutions, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
