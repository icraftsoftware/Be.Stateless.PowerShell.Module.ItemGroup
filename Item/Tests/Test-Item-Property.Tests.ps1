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

Describe 'Test-Item-Property' {
   InModuleScope Item {

      Context 'Property membership check for a non-wellformed Item' {
         It 'Returns always false.' {
            $item = @{ Condition = $null }
            # even though the Item is well formed
            Test-Item -Item $item -WellFormed | Should -BeTrue
            # and property membership is satisfied
            Test-Item -Item $item -Property Condition | Should -BeTrue

            # it will be assumed not to be well formed
            Mock -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -MockWith { $false <# assumes Item is not wellformed #> } -Verifiable
            Test-Item -Item $item -WellFormed | Should -BeFalse

            # and property membership will not be satisfied anymore
            Test-Item -Item $item -Property Condition | Should -BeFalse

            Assert-VerifiableMock
         }
      }

      Context 'When checking the membership of all of the properties and Items are given by argument' {
         It 'Returns (false, false) when testing the existence of all of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Firstname -Mode All | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of all of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition -Mode All | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of all of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false } , [pscustomobject]@{ Condition = $false } ) -Property Condition, Name -Mode All | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of all of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition, Name -Mode All | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of all of the properties and Items are given by pipeline' {
         It 'Returns (false, false) when testing the existence of all of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Firstname -Mode All | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of all of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Condition -Mode All | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of all of several properties for two Items.' {
            @(@{ Condition = $false } , [pscustomobject]@{ Condition = $false }) | Test-Item -Property Condition, Name -Mode All | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of all of several properties for two Items.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Condition, Name -Mode All | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of any of the properties and Items are given by argument' {
         It 'Returns (false, false) when testing the existence of any of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname -Mode Any | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of any of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition -Mode Any | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of any of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname, Lastname -Mode Any | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of any of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition, Name -Mode Any | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of any of the properties and Items are given by pipeline' {
         It 'Returns (false, false) when testing the existence of any of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Fisrtname -Mode Any | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of any of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Condition -Mode Any | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of any of several properties for two Items.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Fisrtname, Lastname -Mode Any | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of any of several properties for two Items.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Condition, Name -Mode Any | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of none of the properties and Items are given by argument' {
         It 'Returns (false, false) when testing the existence of none of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Name -Mode None | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of none of one property for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname -Mode None | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of none of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Name, Fisrtname -Mode None | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of none of several properties for two Items.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Firstname, Lastname -Mode None | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of none of the properties and Items are given by pipeline' {
         It 'Returns (false, false) when testing the existence of none of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Name -Mode None | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of none of one property for two Items.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Fisrtname -Mode None | Should -Be @($true, $true)
         }
         It 'Returns (false, false) when testing the existence of none of several properties for two Items.' {
            @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) | Test-Item -Property Name, Fisrtname -Mode None | Should -Be @($false, $false)
         }
         It 'Returns (true, true) when testing the existence of none of several properties for two Items.' {
            @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) | Test-Item -Property Firstname, Lastname -Mode None | Should -Be @($true, $true)
         }
      }

   }
}