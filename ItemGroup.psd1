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

@{
   RootModule            = 'ItemGroup.psm1'
   ModuleVersion         = '2.1.0.0'
   GUID                  = 'bf08c9f4-bf1f-4e94-92d4-7e3b47a9baee'
   Author                = 'François Chabot'
   CompanyName           = 'be.stateless'
   Copyright             = '(c) 2020 be.stateless. All rights reserved.'
   Description           = 'Commands to define and process ItemGroups that can later be used to drive operations according to the nature of the Items.'
   ProcessorArchitecture = 'None'
   PowerShellVersion     = '5.0'
   NestedModules         = @('Item\Item.psm1', 'Group\Group.psm1')
   RequiredModules       = @('Psx')

   AliasesToExport       = @()
   CmdletsToExport       = @()
   FunctionsToExport     = @('Compare-ItemGroup', 'Expand-ItemGroup', 'Import-ItemGroup', 'Test-ItemGroup')
   VariablesToExport     = @()
}
