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

Import-Module -Name $PSScriptRoot\..\Group -Force

Describe 'Expand-ItemGroup' {
   BeforeAll {
      # create some empty files
      '' > TestDrive:\one.txt
      '' > TestDrive:\two.txt
      '' > TestDrive:\six.txt
      '' > TestDrive:\ten.txt
      '' > TestDrive:\abc.txt
   }
   InModuleScope Group {

      Context 'Expansion allows mixing HashTables as meta properties with arrays as Items.' {
         It 'Supports property HashTable.' {
            $actualItemGroup = @{
               MetaData   = @{ Name = 'metadata-name' ; Description = 'metadata-description' }
               Group      = @( @{ Path = 'TestDrive:\one.txt' } )
               Properties = @{ Name = 'property-name' ; Description = 'property-description' }
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               MetaData   = @{ Name = 'metadata-name' ; Description = 'metadata-description' }
               Group      = @( ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath } )
               Properties = @{ Name = 'property-name' ; Description = 'property-description' }
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion computes Name property after Path property' {
         It 'Computes Name property after Path property.' {
            $actualItemGroup = @(
               @{ Group = @( @{ Path = 'TestDrive:\one.txt' } ) }
            )

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group = @(ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Computes and overwrites Name property after Path property.' {
            $actualItemGroup = @(
               @{ Group = @( @{ Name = 'item-name' ; Path = 'TestDrive:\one.txt' } ) }
            )

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group = @(ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion fails if Item.Path cannot be resolved.' {
         It 'Throws on the first Item whose Path cannot be resolved.' {
            $actualItemGroup = @{ Group1 = @(@{ Path = 'not-found-item-1.dll' }, @{ Path = 'not-found-item-2.exe' }) }

            { Expand-ItemGroup -ItemGroup $actualItemGroup } |
               Should -Throw -ExpectedMessage 'not-found-item-1.dll' -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
         }
      }

      Context 'Expansion when ItemGroups are given by arguments.' {
         It 'Returns empty when expanding an empty ItemGroup.' {
            Expand-ItemGroup -ItemGroup @{ } -InformationAction SilentlyContinue | Should -BeNullOrEmpty
         }
         It 'Returns an empty ItemGroup when expanding an ItemGroup made only of a default Item.' {
            $actualItemGroup = @{
               Group1 = @( @{ Name = '*' ; Condition = ($false) } )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Returns an empty ItemGroup when expanding duplicate ItemGroups whose one is made only of a default Item.' {
            $actualItemGroup = @(
               @{ Group1 = @( @{ Name = '*' ; Condition = $true } ) }
               @{ Group1 = @(
                     @{ Name = '*' ; Condition = $false }
                     @{ Name = 'Item' })
               })

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup -WarningAction SilentlyContinue

            $expectedItemGroups = @{ Group1 = @( ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroup -Verbose | Should -BeNullOrEmpty
         }
         It 'Returns one ItemGroup when expanding one ItemGroup.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{ Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Filters out Items whose Condition predicate is not satisfied.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $false })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(ConvertTo-Item @{ Name = 'Item11' })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Returns several ItemGroups when expanding several ItemGroups.' {
            $actualItemGroup = @(
               @{ Group1 = @( @{ Name = 'Item11' } , @{ Name = 'Item12' ; Condition = $true } ) }
               @{ Group2 = @( @{ Name = 'Item21' } , @{ Name = 'Item22' ; Condition = $true } ) }
            )

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @((ConvertTo-Item @{ Name = 'Item11' }), (ConvertTo-Item @{ Name = 'Item12' ; Condition = $true }))
               Group2 = @((ConvertTo-Item @{ Name = 'Item21' }), (ConvertTo-Item @{ Name = 'Item22' ; Condition = $true }))
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Merges default Item''s properties back into every Item.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = '*' ; Account = 'Account' }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{ Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' ; Account = 'Account' }
                  ConvertTo-Item @{ Name = 'Item12' ; Account = 'Account' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Merges default Item''s condition property back in every Item but does not overwrite it.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = '*' ; Condition = $false }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(ConvertTo-Item @{ Name = 'Item12' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion when ItemGroups are given by pipeline.' {
         It 'Returns empty when expanding an empty ItemGroup.' {
            @{ } | Expand-ItemGroup | Should -BeNullOrEmpty
         }
         It 'Returns an empty ItemGroup when expanding an ItemGroup made only of a default Item.' {
            $actualItemGroup = @{
               Group1 = @( @{ Name = '*' ; Condition = ($false) } )
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Returns an empty ItemGroup when expanding duplicate ItemGroups whose one is made only of a default Item.' {
            $actualItemGroup = @(
               @{ Group1 = @( @{ Name = '*' ; Condition = $true } ) }
               @{ Group1 = @(
                     @{ Name = '*' ; Condition = $false }
                     @{ Name = 'Item' })
               })

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup -WarningAction SilentlyContinue

            $expectedItemGroups = @{ Group1 = @( ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroup -Verbose | Should -BeNullOrEmpty
         }
         It 'Returns one ItemGroup when expanding one ItemGroup.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{ Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Filters out Items whose Condition predicate is not satisfied.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $false })
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(ConvertTo-Item @{ Name = 'Item11' })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Returns several ItemGroups when expanding several ItemGroups.' {
            $actualItemGroup = @(
               @{ Group1 = @( @{ Name = 'Item11' } , @{ Name = 'Item12' ; Condition = $true } ) }
               @{ Group2 = @( @{ Name = 'Item21' } , @{ Name = 'Item22' ; Condition = $true } ) }
            )

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @((ConvertTo-Item @{ Name = 'Item11' }), (ConvertTo-Item @{ Name = 'Item12' ; Condition = $true }))
               Group2 = @((ConvertTo-Item @{ Name = 'Item21' }), (ConvertTo-Item @{ Name = 'Item22' ; Condition = $true }))
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Merges default Item''s properties back into every Item.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = '*' ; Account = 'Account' }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{ Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' ; Account = 'Account' }
                  ConvertTo-Item @{ Name = 'Item12' ; Account = 'Account' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Merges default Item''s condition property back in every Item but does not overwrite it.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = '*' ; Condition = $false }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12' ; Condition = $true })
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(ConvertTo-Item @{ Name = 'Item12' ; Condition = $true })
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion flattens Item.Path property' {
         It 'Flattens Item whose Path property denotes an array of paths.' {
            $actualItemGroup = @(@{ Group1 = @(@{Path = @('TestDrive:\one.txt', 'TestDrive:\two.txt', 'TestDrive:\six.txt') ; Condition = $true }) })

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true }
                  ConvertTo-Item @{ Name = 'two.txt' ; Path = 'TestDrive:\two.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true }
                  ConvertTo-Item @{ Name = 'six.txt' ; Path = 'TestDrive:\six.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup -Verbose | Should -BeNullOrEmpty
         }
         It 'Flattens Item whose Path property denotes an array of paths and merges default Item''s properties.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Name = '*' ; Condition = $false ; Extra = 'Dummy' }
                  @{ Path = @('TestDrive:\one.txt', 'TestDrive:\two.txt', 'TestDrive:\six.txt') ; Condition = $true })
            }

            $expandedItemGroup = $actualItemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true ; Extra = 'Dummy' }
                  ConvertTo-Item @{ Name = 'two.txt' ; Path = 'TestDrive:\two.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true ; Extra = 'Dummy' }
                  ConvertTo-Item @{ Name = 'six.txt' ; Path = 'TestDrive:\six.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath ; Condition = $true ; Extra = 'Dummy' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Flattens Items whose Path property denotes arrays of FileInfos or paths.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Path = @((Get-ChildItem -Path TestDrive:\ -Filter one.txt), (Get-Item -Path TestDrive:\two.txt)) }
                  @{ Path = 'TestDrive:\six.txt' }
                  @{ Path = @('TestDrive:\ten.txt', 'TestDrive:\abc.txt') })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'two.txt' ; Path = 'TestDrive:\two.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'six.txt' ; Path = 'TestDrive:\six.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'ten.txt' ; Path = 'TestDrive:\ten.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'abc.txt' ; Path = 'TestDrive:\abc.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Flattens Items whose Path property denotes mixed arrays of FileInfos and paths.' {
            $actualItemGroup = @{ Group1 = @(
                  @{ Path = @((Get-ChildItem -Path TestDrive:\ -Filter one.txt), 'TestDrive:\abc.txt') }
                  @{ Path = 'TestDrive:\six.txt' }
                  @{ Path = @('TestDrive:\ten.txt', (Get-Item -Path TestDrive:\two.txt)) })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'abc.txt' ; Path = 'TestDrive:\abc.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'six.txt' ; Path = 'TestDrive:\six.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'ten.txt' ; Path = 'TestDrive:\ten.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'two.txt' ; Path = 'TestDrive:\two.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Flattens Item whose Path is the result of command returning several FileInfos.' {
            $actualItemGroup = @{ Group1 =
               @(@{ Path = @(Get-ChildItem -Path TestDrive:\ -Filter *.txt) })
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $actualItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'abc.txt' ; Path = 'TestDrive:\abc.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'one.txt' ; Path = 'TestDrive:\one.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'six.txt' ; Path = 'TestDrive:\six.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'ten.txt' ; Path = 'TestDrive:\ten.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
                  ConvertTo-Item @{ Name = 'two.txt' ; Path = 'TestDrive:\two.txt' | Resolve-Path | Select-Object -ExpandProperty ProviderPath }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion informs about progress' {
         Mock -CommandName Write-Information
         It 'Informs about each ItemGroup that is expanded.' {
            $actualItemGroup = @(
               @{ ApplicationBindings = @(@{ Name = 'a' ; Condition = $false }) }
               @{ Schemas = @(@{ Name = 's' ; Condition = $false }) }
               @{ Transforms = @(@{ Name = 't' ; Condition = $false }) }
               @{ Orchestrations = @(@{ Name = 'o' ; Condition = $false }) }
            )
            Expand-ItemGroup -ItemGroup $actualItemGroup -InformationAction Continue

            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' }
            Assert-MockCalled -CommandName Write-Information -Exactly 4
         }
      }

      Context 'Expansion is warning about every issue' {
         Mock -CommandName Write-Warning -ModuleName Group
         Mock -CommandName Write-Warning -ModuleName Item
         It 'Warns about every invalid Item.' {
            $actualItemGroup = @{ Group = @(@{ LastName = 'Stark' }, @{ LastName = 'Potts' }) }

            Expand-ItemGroup -ItemGroup $actualItemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+:\s+Stark' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+:\s+Potts' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 4
         }
         It 'Warns about every redefined ItemGroup.' {
            $actualItemGroup = @(
               @{ ApplicationBindings = @(@{ Name = 'a' ; Condition = $false }) }
               @{ ApplicationBindings = @(@{ Name = 'a' ; Condition = $false }) }
            )
            Expand-ItemGroup -ItemGroup $actualItemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''ApplicationBindings'' is being redefined.' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Group -Exactly 1
         }
         It 'Warns about duplicate Items that are not ignored.' {
            $actualItemGroup = @{  ApplicationBindings = @(
                  @{ Name = 'a' ; Condition = $true }
                  @{ Name = 'a' ; Condition = $true })
            }
            Expand-ItemGroup -ItemGroup $actualItemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''a'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Condition\s+:\s+True' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+a' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 6
         }
         It 'Does not warn about duplicate Items that are ignored.' {
            $actualItemGroup = @{  ApplicationBindings = @(
                  @{ Name = 'a' ; Condition = $false }
                  @{ Name = 'a' ; Condition = $false })
            }
            Expand-ItemGroup -ItemGroup $actualItemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 0
         }
      }

   }
}
