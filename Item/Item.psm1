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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.u
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

Set-StrictMode -Version Latest

function Compare-Item {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [PSCustomObject]
        $ReferenceItem,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [PSCustomObject]
        $DifferenceItem,

        [Parameter(Mandatory = $false, DontShow)]
        [string]
        $Prefix = ''
    )
    Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $ReferenceItem = if ($null -eq $ReferenceItem) { [PSCustomObject]@{ } } else { [PSCustomObject]$ReferenceItem }
    $DifferenceItem = if ($null -eq $DifferenceItem) { [PSCustomObject]@{ } } else { [PSCustomObject]$DifferenceItem }
    $referenceProperties = @(Get-ItemPropertyNames -Item $ReferenceItem)
    $differenceProperties = @(Get-ItemPropertyNames -Item $DifferenceItem)
    $referenceProperties + $differenceProperties | Select-Object -Unique -PipelineVariable key | ForEach-Object -Process {
        $propertyName = if ($Prefix) { "$Prefix.$key" } else { $key }
        if ($referenceProperties.Contains($key) -and !$differenceProperties.Contains($key)) {
            [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $ReferenceItem.$key ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        } elseif (!$referenceProperties.Contains($key) -and $differenceProperties.Contains($key)) {
            [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItem.$key } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        } else {
            $referenceValue, $differenceValue = $ReferenceItem.$key, $DifferenceItem.$key
            if ($referenceValue -ne $differenceValue) {
                [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $referenceValue ; SideIndicator = '<>' ; DifferenceValue = $differenceValue } | Tee-Object -Variable difference
                Write-Verbose -Message $difference
            }
        }
    }
}

function ConvertTo-Item {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]
        $HashTable
    )
    begin {
        Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    process {
        @(
            $HashTable |
                Where-Object -FilterScript { $_.Count } <# filter out empty HashTables #> -PipelineVariable currentHashTable |
                ForEach-Object -Process {
                    $item = New-Object -TypeName PSCustomObject
                    $currentHashTable.Keys | ForEach-Object -Process {
                        if ($currentHashTable.$_ -is [ScriptBlock]) {
                            Add-Member -InputObject $item -MemberType ScriptProperty -Name $_ -Value $currentHashTable.$_
                        } else {
                            Add-Member -InputObject $item -MemberType NoteProperty -Name $_ -Value $currentHashTable.$_
                        }
                    }
                    $item
                }
        )
    }
}

function Test-Item {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [psobject[]]
        $Item,

        [Parameter(Mandatory = $true, ParameterSetName = 'membership')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Property,

        [Parameter(Mandatory = $false, ParameterSetName = 'membership')]
        [ValidateSet('All', 'Any', 'None')]
        [string]
        $Mode = 'All',

        [Parameter(Mandatory = $true, ParameterSetName = 'unicity')]
        [switch]
        $Unique,

        [Parameter(Mandatory = $true, ParameterSetName = 'validity')]
        [switch]
        $Valid,

        [Parameter(Mandatory = $true, ParameterSetName = 'well-formedness')]
        [switch]
        $WellFormed
    )

    begin {
        Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        switch ($PSCmdlet.ParameterSetName) {
            'unicity' {
                $allValidItems = @()
            }
        }
    }
    process {

        function Trace-InvalidItem {
            [CmdletBinding()]
            [OutputType([void])]
            param(
                [Parameter(Mandatory = $true)]
                [AllowNull()]
                [psobject]
                $Item
            )
            if ($WarningPreference -notin ('SilentlyContinue', 'Ignore')) {
                Write-Warning -Message 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:'
                # cast to PSCustomObject to ensure Format-List has an output format consistent across HashTable and PSCustomObject
                ([PSCustomObject]$Item) | Format-List | Out-String -Stream | Where-Object { -not([string]::IsNullOrWhitespace($_)) } | ForEach-Object -Process {
                    Write-Warning -Message $_.Trim()
                }
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'membership' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    $isMember = $false
                    if (Test-Item -Item $currentItem -WellFormed) {
                        $members = @(Get-ItemPropertyNames -Item $currentItem)
                        switch ($Mode) {
                            'All' {
                                $isMember = $Property | Where-Object -FilterScript { $members -notcontains $_ } | Test-None
                            }
                            'Any' {
                                $isMember = $Property | Where-Object -FilterScript { $members -contains $_ } | Test-Any
                            }
                            'None' {
                                $isMember = $Property | Where-Object -FilterScript { $members -contains $_ } | Test-None
                            }
                        }
                    }
                    $isMember
                }
            }
            'unicity' {
                $allValidItems += @(
                    $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | Where-Object -FilterScript {
                        Test-Item -Item $currentItem -Valid
                    }
                )
            }
            'validity' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    $isValid = $false
                    if (Test-Item -Item $currentItem -WellFormed) {
                        # Path property has the precedence over the Name property, but either one is required
                        if (Test-Item -Item $currentItem -Property Path) {
                            $isValid = $null -ne $currentItem.Path `
                                <# ensure that Item.Path is single valued #> `
                                -and (-not ($currentItem.Path -is [array]) -or $currentItem.Path.Length -eq 1) `
                                <# ensure that Item.Path is a valid path to a file #> `
                                -and ($currentItem.Path | Test-Path -PathType Leaf)
                        } elseif (Test-Item -Item $currentItem -Property Name) {
                            $isValid = -not([string]::IsNullOrWhitespace($currentItem.Name)) `
                                <# ensure that Item.Name is single valued #> `
                                -and (-not ($currentItem.Name -is [array]) -or $currentItem.Name.Length -eq 1)
                        }
                    }
                    if (-not $isValid) {
                        Trace-InvalidItem -Item $currentItem
                    }
                    $isValid
                }
            }
            'well-formedness' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    @(Get-ItemPropertyNames -Item $currentItem) | Test-Any
                }
            }
        }
    }
    end {

        function Trace-DuplicateItem {
            [CmdletBinding()]
            [OutputType([Microsoft.PowerShell.Commands.GroupInfo])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [Microsoft.PowerShell.Commands.GroupInfo]
                $GroupInfo
            )
            process {
                if ($WarningPreference -notin ('SilentlyContinue', 'Ignore')) {
                    $GroupInfo.Group | ForEach-Object -Process {
                        Write-Warning -Message "The following Item '$($GroupInfo.Name)' has been defined multiple times:"
                        # cast to PSCustomObject to ensure Format-List has an output format consistent across HashTable and PSCustomObject
                        ([PSCustomObject]$_) | Format-List | Out-String -Stream | Where-Object { -not([string]::IsNullOrWhitespace($_)) } | ForEach-Object -Process {
                            Write-Warning -Message $_.Trim()
                        }
                    }
                }
                $GroupInfo
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'unicity' {
                # Path property has the precedence over the Name property when grouping Items
                $allValidItems |
                    Group-Object -Property { if (Test-Item -Item $_ -Property Path) { $_.Path } else { $_.Name } } |
                    Where-Object -FilterScript { $_.Count -gt 1 } -PipelineVariable duplicateItems |
                    Where-Object -FilterScript {
                        # unicity test is performed wrt the Path property only for Items having such a property
                        (Test-Item -Item $duplicateItems.Group[0] -Property Path) -or (
                            # while the test is performed wrt all the properties for Items missing a Path property
                            $duplicateItems.Group |
                                Select-Object -Skip 1 |
                                Where-Object -FilterScript { Compare-Item -ReferenceItem $duplicateItems.Group[0] -DifferenceItem $_ | Test-None } |
                                Test-Any
                        )
                    } |
                    Trace-DuplicateItem |
                    Test-None
            }
        }
    }
}

function Get-ItemPropertyNames {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [psobject]
        $Item
    )
    # see https://stackoverflow.com/a/18477004/1789441
    if ($Item -is [hashtable]) {
        @($Item.Keys)
    } elseif ($Item -is [PSCustomObject]) {
        @(Get-Member -InputObject $Item -MemberType  NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
    } else {
        @()
    }
}
