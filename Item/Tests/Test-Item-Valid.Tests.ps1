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

Describe 'Test-Item-Valid' {
   InModuleScope Item {

      Context 'Validity check for a non-wellformed Item' {
         It 'Returns always false.' {
            $item = @{ Name = 'Stark' }
            # although the Item is well formed
            Test-Item -Item $item -WellFormed | Should -BeTrue
            # and Validity check is satisfied
            Test-Item -Item $item -Valid | Should -BeTrue

            # it will be assumed not to be well formed
            Mock -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -MockWith { $false <# assumes Item is not wellformed #> }
            Test-Item -Item $item -WellFormed | Should -BeFalse

            # and Validity check will not be satisfied anymore
            Test-Item -Item $item -Valid -WarningAction SilentlyContinue | Should -BeFalse

            Assert-MockCalled -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -Exactly 2
         }
      }

      Context 'Validity check when Items are given by argument' {
         It 'Returns (false, false) when none of both Items have neither a Name nor a Path property.' {
            Test-Item -Item @(@{ Condition = $true }, [PSCustomObject]@{ Condition = $true }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have a null Name property.' {
            Test-Item -Item @(@{ Name = $null }, [PSCustomObject]@{ Name = $null }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) when both Items have a non null Name property.' {
            Test-Item -Item @(@{ Name = 'Stark' }, [PSCustomObject]@{ Name = 'Parker' }) -Valid | Should -Be ($true, $true)
         }
         It 'Returns (false, false) when both Items have a null Path property.' {
            Test-Item -Item @(@{ Path = $null }, [PSCustomObject]@{ Path = $null }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have an invalid Path property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            Test-Item -Item @(@{ Path = 'a:\notfound\file.txt' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have a valid Path property but to a folder and no Name property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            Test-Item -Item @(@{ Path = 'a:\folder' }, [PSCustomObject]@{ Path = 'a:\folder' }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) when both Items have a valid Path property to a file and has no Name property.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            Test-Item -Item @(@{ Path = 'a:\folder\file.txt' }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' }) -Valid | Should -Be ($true, $true)
         }
         It 'Returns (false, false) although Item.Names are non-null because *invalid* Item.Paths have precedence.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            Test-Item -Item @(@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) although Item.Names are null because *valid* Item.Paths have precedence.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            Test-Item -Item @(@{ Path = 'a:\folder\file.txt' ; Name = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null }) -Valid | Should -Be ($true, $true)
         }
      }

      Context 'Validity check when Items are given by pipeline' {
         It 'Returns (false, false) when none of both Items have neither a Name nor a Path property.' {
            @{ Condition = $true }, [PSCustomObject]@{ Condition = $true } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have a null Name property.' {
            @{ Name = $null }, [PSCustomObject]@{ Name = $null } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) when both Items have a non null Name property.' {
            @{ Name = 'Stark' }, [PSCustomObject]@{ Name = 'Parker' } | Test-Item -Valid | Should -Be ($true, $true)
         }
         It 'Returns (false, false) when both Items have a Name property that is an array of values.' {
            @{ Name = @('Stark', 'Potts') }, [PSCustomObject]@{ Name = @('Parker', 'Happy') } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have a null Path property.' {
            @{ Path = $null }, [PSCustomObject]@{ Path = $null } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have an invalid Path property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = 'a:\notfound\file.txt' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) when both Items have a valid Path property but to a folder and no Name property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = 'a:\folder' }, [PSCustomObject]@{ Path = 'a:\folder' }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) when both Items have a valid Path property to a file and has no Name property.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = 'a:\folder\file.txt' }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' }) | Test-Item -Valid | Should -Be ($true, $true)
         }
         It 'Returns (false, false) when both Items have a Path property that is an array of values.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = @('a:\folder\file.txt', 'a:\folder\file.txt') }, [PSCustomObject]@{ Path = @('a:\folder\file.txt', 'a:\folder\file.txt') }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (false, false) although Item.Names are non-null because *invalid* Item.Paths have precedence.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Returns (true, true) although Item.Names are null because *valid* Item.Paths have precedence.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            @(@{ Path = 'a:\folder\file.txt' ; Name = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null }) | Test-Item -Valid | Should -Be ($true, $true)
         }
      }

      Context 'Validity check when Items are made of a mix of FileInfo objects and paths' {
         It 'Returns (true, true) for a FileInfo and a path' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            $item = Get-ChildItem -File -Path $PSScriptRoot -Filter Test-Item-Valid.Tests.ps1
            $path = Get-ChildItem -File -Path $PSScriptRoot -Filter Test-Item-Valid.Tests.ps1 | Resolve-Path | Select-Object -ExpandProperty ProviderPath
            @(@{ Path = $item }, [PSCustomObject]@{ Path = $path }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($true, $true)
         }
         It 'Returns (true, true) for a FileInfo' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> } -ParameterFilter { $PathType -eq 'Leaf' }
            $item1 = Get-ChildItem -File -Path $PSScriptRoot -Filter Test-Item-Valid.Tests.ps1
            $item2 = Get-ChildItem -File -Path $PSScriptRoot -Filter Test-Item-Unique.Tests.ps1
            @(@{ Path = $item1 }, [PSCustomObject]@{ Path = $item2 }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($true, $true)
         }
      }

      Context 'Validity check is warning about any validity issue' {
         Mock -CommandName Test-Path -MockWith { $false <# assumes every path is either invalid or a folder #> } -ParameterFilter { $PathType -eq 'Leaf' }
         Mock -CommandName Write-Warning
         It 'Warns about every property, whether null or invalid, for every invalid Item.' {
            @(@{ Path = 'a:\folder\file.txt' ; Name = $null ; Condition = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null ; Condition = $null }) | Test-Item -Valid | Should -Be ($false, $false)

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Path\s+:\s+a:\\folder\\file\.txt' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Condition\s+:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
         It 'Warns about every property for every invalid Item.' {
            @(@{ Path = 'a:\folder\file.txt' ; Name = 'Stark' ; Condition = $false }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = 'Stark' ; Condition = $false }) | Test-Item -Valid | Should -Be ($false, $false)

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Path\s+:\s+a:\\folder\\file\.txt' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Stark' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Condition\s+:\s+False' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
      }

   }
}
