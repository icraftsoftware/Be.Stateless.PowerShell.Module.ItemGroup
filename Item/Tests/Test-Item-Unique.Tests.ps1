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

Describe 'Test-Item-Unique' {
   InModuleScope Item {

      Context 'Unicity check for an invalid Item' {
         It 'Ignores invalid Items during Unicity check.' {
            $items = @( @{ Name = 'one' }, @{ Name = 'two' }, @{ Path = $null ; Name = 'same' }, @{Path = $null ; Name = 'same' } )
            # even though last two Items have the same Name they are invalid
            Test-Item -Item $items -Valid -WarningAction SilentlyContinue | Should -Be @($true, $true, $false, $false)
            # and unicity check is consequently satisfied because invalid Items are discarded
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -BeTrue

            # whereas if all Items are assumed to be valid
            Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { @($true, $true, $true, $true) <# assumes Items are not valid #> } -Verifiable
            Test-Item -Item $items -Valid | Should -Be @($true, $true, $true, $true)

            # unicity check will not be satisfied anymore because the last two Items have the same Name
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -BeFalse

            Assert-VerifiableMock
         }
      }

      Context 'Unicity check when Items are given by argument' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         It 'Returns true when hashtable Items have different Names.' {
            Test-Item -Item @( @{ Name = 'one' }, @{ Name = 'two' } ) -Unique | Should -BeTrue
         }
         It 'Returns false when hashtable Items have the same Name.' {
            Test-Item -Item @( @{ Name = 'one' }, @{ Name = 'one' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when a mix of Items have different Names.' {
            Test-Item -Item @( @{ Name = 'one' }, [PSCustomObject]@{ Name = 'two' } ) -Unique | Should -BeTrue
         }
         It 'Returns false when a mix of Items have the same Name.' {
            Test-Item -Item @( @{ Name = 'one' }, [PSCustomObject]@{ Name = 'one' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when object Items have different Names.' {
            Test-Item -Item @( [PSCustomObject]@{ Name = 'one' }, [PSCustomObject]@{ Name = 'two' } ) -Unique | Should -BeTrue
         }
         It 'Returns false when object Items have the same Name.' {
            Test-Item -Item @( [PSCustomObject]@{ Name = 'one' }, [PSCustomObject]@{ Name = 'one' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when Items have different Paths.' {
            Test-Item -Item @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\two' } ) -Unique | Should -BeTrue
         }
         It 'Returns false when Items have the same Path.' {
            Test-Item -Item @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\one' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns false when Items have different Names but the same Path because Path has precedence over Name.' {
            Test-Item -Item @( @{ Name = 'Stark' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'Parker' ; Path = 'z:\one' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when Items have the same Name but different Paths because Path has precedence over Name.' {
            Test-Item -Item @( @{ Name = 'same' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'same' ; Path = 'z:\two' } ) -Unique | Should -BeTrue
         }
         It 'Returns false for an array of Items.' {
            $items = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true only if all the properties of hashtable Items are different.' {
            Test-Item -Item @( @{ Name = 'one' ; Type = 'a' }, @{ Name = 'one' ; Type = 'b' } ) -Unique | Should -BeTrue
         }
         It 'Returns true only if all the properties of object Items are different.' {
            Test-Item -Item @( [PSCustomObject]@{ Name = 'one' ; Type = 'a' }, [PSCustomObject]@{ Name = 'one' ; Type = 'b' } ) -Unique | Should -BeTrue
         }
         It 'Returns true if Item.Paths are different regardlessly of other properties.' {
            Test-Item -Item @( [PSCustomObject]@{ Path = 'Z:\one' ; Name = 'one' ; Type = 'a' }, [PSCustomObject]@{ Path = 'z:\two' ; Name = 'one' ; Type = 'a' } ) -Unique | Should -BeTrue
         }
         It 'Returns false if Item.Paths are the same regardlessly of other properties.' {
            Test-Item -Item @( @{ Path = 'Z:\one' ; Name = 'one' ; Type = 'a' }, @{ Path = 'z:\one' ; Name = 'two' ; Type = 'b' } ) -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns false for an array of array of Items.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
      }

      Context 'Unicity check when Items are given by pipeline' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         It 'Returns true when Items have different Names.' {
            @{ Name = 'one' }, [PSCustomObject]@{ Name = 'two' } | Test-Item -Unique | Should -BeTrue
         }
         It 'Returns false when Items have the same Name.' {
            @{ Name = 'one' }, [PSCustomObject]@{ Name = 'one' } | Test-Item -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when Items have different Paths.' {
            @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\two' } | Test-Item -Unique | Should -BeTrue
         }
         It 'Returns false when Items have the same Path.' {
            @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\one' } ) | Test-Item -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns false when Items have different Names but the same Path because Path has precedence over Name.' {
            @( @{ Name = 'Stark' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'Parker' ; Path = 'z:\one' } ) | Test-Item -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns true when Items have the same Name but different Paths because Path has precedence over Name.' {
            @( @{ Name = 'same' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'same' ; Path = 'z:\two' } ) | Test-Item -Unique | Should -BeTrue
         }
         It 'Returns false for an array of Items.' {
            $items = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            $items | Test-Item -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
         It 'Returns false for an array of array of Items.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            $items | Test-Item -Unique -WarningAction SilentlyContinue | Should -BeFalse
         }
      }

      Context "Unicity check is warning about any unicity issue" {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         Mock -CommandName Write-Warning
         It 'Warns about each property of every duplicate Item.' {
            @{ Path = 'z:\one' ; Name = 'One' ; City = 'City' ; Street = 'one' }, @{ Path = 'z:\two' ; Name = 'Two' ; City = 'City' ; Street = 'two' }, @{ Path = 'z:\one' ; Name = 'One' ; City = 'City' ; Street = 'six' } | Test-Item -Unique | Should -BeFalse

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''z:\one'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Path\s+:\s+z:\\one' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Street\s+:\s+one' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Street\s+:\s+six' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'City\s+:\s+City' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 10
         }
         It 'Warns about any duplicate Item when Items are given by the pipeline.' {
            @{ Name = 'One' }, @{ Name = 'Two' }, @{ Name = 'One' }, @{ Name = 'Two' }, @{ Name = 'Three' } | Test-Item -Unique | Should -BeFalse

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
         It 'Warns about any duplicate Item when Items are contained in one array which is given by argument.' {
            $item = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            Test-Item -Item $item -Unique | Should -BeFalse

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
         It 'Warns about any duplicate Item when Items are contained in several arrays which are given by argument.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            Test-Item -Item $items -Unique | Should -BeFalse

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
      }

   }
}
