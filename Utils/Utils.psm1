#region Copyright & License

# Copyright © 2012 - 2020 François Chabot
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

#endregion

Set-StrictMode -Version Latest

# seealso https://powershell.org/2014/01/getting-your-script-module-functions-to-inherit-preference-variables-from-the-caller/
# seealso https://powershell.org/2014/01/revisited-script-modules-and-variable-scopes/
# seealso https://gallery.technet.microsoft.com/Inherit-Preference-82343b9d

function Resolve-WarningAction([psobject] $boundParameters) {
    # SilentlyContinue, Stop, Continue, Inquire, Ignore, Suspend
    if ($boundParameters.ContainsKey('WarningAction')) {
        $boundParameters.WarningAction
    } else {
        $WarningPreference
    }
}
