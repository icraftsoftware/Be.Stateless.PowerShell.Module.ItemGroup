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

function Compare-ItemGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ReferenceItemGroup,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DifferenceItemGroup
    )
    Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $ReferenceItemGroup.Keys + $DifferenceItemGroup.Keys | Sort-Object -Unique -PipelineVariable key | ForEach-Object -Process {
        if ($ReferenceItemGroup.ContainsKey($key) -and !$DifferenceItemGroup.ContainsKey($key)) {
            [PSCustomObject]@{ Key = $key ; ReferenceValue = $ReferenceItemGroup.$key ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        } elseif (!$ReferenceItemGroup.ContainsKey($key) -and $DifferenceItemGroup.ContainsKey($key)) {
            [PSCustomObject]@{ Key = $key ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItemGroup.$key } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        } elseif ($ReferenceItemGroup.$key -is [hashtable] -and $DifferenceItemGroup.$key -is [hashtable]) {
            Compare-HashTable -ReferenceHashTable $ReferenceItemGroup.$key -DifferenceHashTable $DifferenceItemGroup.$key -Prefix $key
        } elseif ($ReferenceItemGroup.$key -is [hashtable] -or $DifferenceItemGroup.$key -is [hashtable]) {
            [PSCustomObject]@{ Key = $key ; ReferenceValue = $ReferenceItemGroup.$key.GetType() ; SideIndicator = '<>' ; DifferenceValue = $DifferenceItemGroup.$key.GetType() } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        } else {
            $referenceItems, $differenceItems = @($ReferenceItemGroup.$key), @($DifferenceItemGroup.$key)
            for ($i = 0; $i -lt [math]::Max($referenceItems.Count, $differenceItems.Count); $i++) {
                if ($i -lt $referenceItems.Count -and $i -lt $differenceItems.Count) {
                    Compare-Item -ReferenceItem $referenceItems[$i] -DifferenceItem $differenceItems[$i] -Prefix ('{0}[{1}]' -f $key, $i)
                } elseif ($i -lt $referenceItems.Count) {
                    [PSCustomObject]@{ Key = "$key[$i]" ; ReferenceValue = $referenceItems[$i] ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
                    Write-Verbose -Message $difference
                } else {
                    [PSCustomObject]@{ Key = "$key[$i]" ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $differenceItems[$i] } | Tee-Object -Variable difference
                    Write-Verbose -Message $difference
                }
            }
        }
    }
}

function Expand-ItemGroup {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]
        $ItemGroup
    )
    begin {
        Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $expandedItemGroup = @{ }
    }
    process {
        # warns about every duplicate ItemGroup and Item
        $ItemGroup | Test-ItemGroup -Unique | Out-Null
        $ItemGroup | ForEach-Object -Process { $_ } -PipelineVariable currentItemGroup | Select-Object -ExpandProperty Keys -PipelineVariable itemGroupName | ForEach-Object -Process {
            Write-Information -MessageData "Expanding ItemGroup '$itemGroupName'."
            if ($currentItemGroup.$itemGroupName -is [hashtable]) {
                # forward property Hashtable to expandedItemGroup and ...
                $expandedItemGroup.$itemGroupName = $currentItemGroup.$itemGroupName
                # ... move to next $itemGroupName in the pipeline, i.e. skip the remaining of the script block, see https://stackoverflow.com/a/7763698/1789441
                return
            }
            if ($currentItemGroup.$itemGroupName -isnot [array]) { throw "ItemGroup '$itemGroupName' must be an array of Items." }
            if ($expandedItemGroup.ContainsKey($itemGroupName)) { Write-Warning -Message "ItemGroup '$itemGroupName' is being redefined." }
            # compute ItemGroup's default Item to be merged into every other Item
            $defaultItem = Resolve-DefaultItem -ItemGroup $currentItemGroup.$itemGroupName
            $expandedItemGroup.$itemGroupName = @(
                $currentItemGroup.$itemGroupName |
                    Where-Object -PipelineVariable validItem -FilterScript {
                        # select valid and non-default Items
                        (Test-Item -Item $_ -Valid -WarningAction SilentlyContinue) `
                            -and ((Test-Item -Item $_ -Property Name -Mode None -WarningAction SilentlyContinue) -or $_.Name -ne '*')
                    } |
                    ForEach-Object -PipelineVariable flattenedItem -Process {
                        if (Test-Item -Item $validItem -Property Path -WarningAction SilentlyContinue) {
                            # flatten Items whose Path is a list of paths
                            $validItem.Path |
                                Resolve-Path -ErrorAction Stop <# throw if Path cannot be resolved #> |
                                ForEach-Object -Process {
                                    # rewrite Name after Path and merges validItem's other properties back into the flattened Item
                                    Merge-HashTable -HashTable (
                                        @{ Name = Split-Path -Path $_.ProviderPath -Leaf ; Path = $_.ProviderPath },
                                        $validItem
                                    )
                                }
                        } else {
                            $validItem
                        }
                    } |
                    ForEach-Object -Process { Merge-HashTable -HashTable $flattenedItem, $defaultItem } |
                    Where-Object -FilterScript { (Test-Item -Item $_ -Property Condition -Mode None) -or $_.Condition } |
                    ConvertTo-Item
            )
        }
    }
    end {
        $expandedItemGroup
    }
}

function Import-ItemGroup {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
    dynamicparam {
        # resolve path to ItemGroup file when invoked through 'Get-Help -Name Import-ItemGroup -Path <ItemGroup.psd1>' as well
        if (-not(Test-Path -Path Variable:Path)) {
            $Path = Get-PSCallStack |
                Select-Object -Last 1 -ExpandProperty Position |
                Select-Object -ExpandProperty Text |
                Where-Object -FilterScript { $_ -match '^Get\-Help\s+(:?\-Name\s+)?Import\-ItemGroup\s+(:?\-Path\s+)''?(?<Path>[^\s'']+)''?.*$' } |
                ForEach-Object -Process { $Matches.Path }
        }
        if ($null -ne $Path -and (Test-Path -Path $Path)) {
            if (-not(Get-Item -Path $Path | Select-Object -ExpandProperty PSIsContainer)) {
                $source = Get-Content -Raw -Path $Path
                $scriptBlock = [scriptblock]::Create($source)
                Convert-ScriptBlockParametersToDynamicParameters -ScriptBlock $scriptBlock
            }
        }
    }
    begin {
        Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $location = Get-Location
    }
    process {
        $absolutePath = Resolve-Path -Path $Path
        Write-Information -MessageData "Importing ItemGroups from file '$absolutePath'."
        # make sure current folder for each ItemGroup definition file is its containing folder
        $itemGroupFolderPath = Split-Path -Path $absolutePath -Parent
        Write-Verbose -Message "Setting location to '$itemGroupFolderPath'."
        Push-Location -Path $itemGroupFolderPath

        ## TODO enrich HashTable with source file to provide better diagnostics info
        Invoke-ScriptBlock -ScriptBlock $scriptBlock -Parameters $PSBoundParameters |
            <# pipe ItemGroups to support array of HashTables and not just a single HashTable #>
            ForEach-Object -Process {
                if ($_ -isnot [hashtable]) {
                    throw "File '$absolutePath' does not contain valid HashTable ItemGroup definitions."
                } else {
                    $_
                }
            }
        Pop-Location
    }
    end {
        Write-Verbose -Message "Restoring initial location to '$location'."
        Set-Location -Path $location
    }
}

function Test-ItemGroup {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]
        $ItemGroup,

        [Parameter(Mandatory = $true)]
        [switch]
        $Unique
    )
    begin {
        Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $allItemGroups = @()
    }
    process {
        if ($Unique) { $allItemGroups += @( $ItemGroup | ForEach-Object -Process { $_ } ) }
    }
    end {

        function Trace-DuplicateItemGroup {
            [CmdletBinding()]
            [OutputType([Microsoft.PowerShell.Commands.GroupInfo])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [Microsoft.PowerShell.Commands.GroupInfo]
                $GroupInfo
            )
            process {
                Write-Warning -Message "ItemGroup '$($GroupInfo.Name)' has been defined multiple times."
                $GroupInfo
            }
        }
        if ($Unique) {
            $itemGroupsAreUnique = $allItemGroups |
                Select-Object -ExpandProperty Keys |
                Group-Object |
                Where-Object -FilterScript { $_.Count -gt 1 } |
                Trace-DuplicateItemGroup |
                Test-None
            $itemsAreUnique = $allItemGroups |
                ForEach-Object -Process { $_.Values } |
                Test-Item -Unique
            $itemGroupsAreUnique -and $itemsAreUnique
        }
    }
}

function Resolve-DefaultItem {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [hashtable[]]
        $ItemGroup
    )
    Resolve-ActionPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # compute default Item, which defines inheritable default properties, from all Items whose Name = '*'
    $ItemGroup |
        ForEach-Object -Process { $_ } |
        Where-Object -FilterScript { (Test-Item -Item $_ -Valid -WarningAction SilentlyContinue) -and (Test-Item -Item $_ -Property Name) -and $_.Name -eq '*' } |
        Merge-HashTable -Exclude 'Name' -Force
}

Import-Module -Name $PSScriptRoot\..\Item
