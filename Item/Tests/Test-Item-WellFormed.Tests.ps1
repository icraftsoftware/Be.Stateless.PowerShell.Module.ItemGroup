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

Import-Module -Name $PSScriptRoot\..\Item -Force

Describe 'Test-Item-Wellformed' {
   InModuleScope Item {
      It 'Returns false for null.' {
         $null | Test-Item -Wellformed | Should -Be $false
      }
      It 'Returns false for an empty HashTable.' {
         @{ } | Test-Item -Wellformed | Should -Be $false
      }
      It 'Returns true for a HashTable with a property.' {
         @{Name = 'name' ; x = $null } | Test-Item -Wellformed | Should -Be $true
      }
      It 'Returns false for an empty custom object.' {
         ([pscustomobject]@{ }) | Test-Item -Wellformed | Should -Be $false
      }
      It 'Returns true for a custom object with a property.' {
         [pscustomobject]@{Name = 'name' ; x = $null } | Test-Item -Wellformed | Should -Be $true
      }
      It 'Returns empty for an empty array.' {
         @() | Test-Item -Wellformed | Should -Be @()
      }
      It 'Returns false for each empty HashTable in an array.' {
         @( @{ } , @{ } ) | Test-Item -Wellformed | Should -Be @($false, $false)
      }
      It 'Returns true for each HashTable with a property in an array.' {
         @( @{Name = 'name' ; x = $null } , @{ } ) | Test-Item -Wellformed | Should -Be ($true, $false)
      }
      It 'Returns false for each empty custom object in an array.' {
         @( ([pscustomobject]@{ }) , ([pscustomobject]@{ }) ) | Test-Item -Wellformed | Should -Be @($false, $false)
      }
      It 'Returns true for each custom object with a property in an array.' {
         @( [pscustomobject]@{Name = 'name' ; x = $null } , [pscustomobject]@{ } ) | Test-Item -Wellformed | Should -Be ($true, $false)
      }
   }
}