﻿#region Copyright & License

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

Describe 'Compare-Item' {
   InModuleScope Item {

      Context 'When both Items are null' {
         It 'Returns nothing.' {
            Compare-Item -ReferenceItem $null -DifferenceItem $null | Should -BeNullOrEmpty
         }
      }

      Context 'When both Items have one identical entry' {
         It 'Returns nothing.' {
            $left = ConvertTo-Item @{ a = "x" }
            $right = ConvertTo-Item @{ a = "x" }
            Compare-Item -ReferenceItem $left -DifferenceItem $right | Should -BeNullOrEmpty
         }
      }

      Context 'When reference Item contains a key with a null value' {
         It 'Returns ''a <''.' {
            $left = ConvertTo-Item @{ a = $null }
            $right = ConvertTo-Item @{ }

            [object[]]$result = Compare-Item -ReferenceItem $left -DifferenceItem $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'a'
            $result.ReferenceValue | Should -BeNullOrEmpty
            $result.SideIndicator | Should -Be "<"
            $result.DifferenceValue | Should -BeNullOrEmpty
         }
      }

      Context 'When difference Item contains a key with a null value' {
         It 'Returns ''a >''.' {
            $left = ConvertTo-Item @{ }
            $right = ConvertTo-Item @{ a = $null }

            [object[]]$result = Compare-Item -ReferenceItem $left -DifferenceItem $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'a'
            $result.ReferenceValue | Should -BeNullOrEmpty
            $result.SideIndicator | Should -Be ">"
            $result.DifferenceValue | Should -BeNullOrEmpty
         }
      }

      Context 'When reference and difference Items have one property that is different' {
         It 'Returns ''a value <>''.' {
            $left = ConvertTo-Item @{ a = 'value' }
            $right = ConvertTo-Item @{ a = $null }

            [object[]]$result = Compare-Item -ReferenceItem $left -DifferenceItem $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'a'
            $result.ReferenceValue | Should -Be 'value'
            $result.SideIndicator | Should -Be "<>"
            $result.DifferenceValue | Should -BeNullOrEmpty
         }
      }

   }
}
