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

Describe 'Get-ItemPropertyNames' {
    InModuleScope Item {

        Context 'When Item is null' {
            It 'Returns an empty array.' {
                $names = Get-ItemPropertyNames -Item $null
                $names | Should -BeNullOrEmpty
                $names | Should -Be @()
                $names | Test-Any | Should -BeFalse
                $names | Test-None | Should -BeTrue
            }
            It 'Returns an empty array for a HashTable.' {
                Get-ItemPropertyNames -Item ([hashtable]$null) | Should -BeNullOrEmpty
            }
            It 'Returns an empty array for a custom object.' {
                Get-ItemPropertyNames -Item ([PSCustomObject]$null) | Should -BeNullOrEmpty
            }
        }

        Context 'When Item is a HashTable' {
            It 'Returns an empty array when the Item has no property.' {
                Get-ItemPropertyNames -Item @{ } | Should -Be @()
            }
            It 'Returns an array of strings when the Item has one property.' {
                $names = Get-ItemPropertyNames -Item @{ name = '1' }
                # $names.GetType() | Should -Be ([object[]])
                $names | Should -HaveCount 1
                $names | Should -Be @('name')
                $names | Test-Any | Should -BeTrue
            }
            It 'Returns an array of strings when the Item has one property.' {
                $names = Get-ItemPropertyNames -Item @{ firstname = '1' ; lastname = '2' }
                $names.GetType() | Should -Be ([object[]])
                $names | Should -HaveCount 2
                $names | Should -Be @('lastname', 'firstname')
                $names | Test-Any | Should -BeTrue
            }
        }

        Context 'When Item is a custom object' {
            It 'Returns an empty array when the Item has no property.' {
                Get-ItemPropertyNames -Item ([PSCustomObject]@{ }) | Should -Be @()
            }
            It 'Returns an array of strings when the Item has one property.' {
                $names = Get-ItemPropertyNames -Item ([PSCustomObject]@{ name = '1' })
                # $names.GetType() | Should -Be ([object[]])
                $names | Should -HaveCount 1
                $names | Should -Be @('name')
                $names | Test-Any | Should -BeTrue
            }
            It 'Returns an array of strings when the Item has one property.' {
                $names = Get-ItemPropertyNames -Item ([PSCustomObject]@{ firstname = '1' ; lastname = '2' })
                $names.GetType() | Should -Be ([object[]])
                $names | Should -HaveCount 2
                $names | Should -Be @('firstname', 'lastname')
                $names | Test-Any | Should -BeTrue
            }
        }

    }
}