﻿<#
Copyright 2016-2021 Brian Deyo
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: MPL-2.0

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.

###Change Log
    2019-03-29 - modified Set-AwDevice to use new endpoint

#>


Function Get-WS1BulkDeviceSettings {
<#
        .SYNOPSIS
            Retrieve Bulk Limits for various Device actions
        .DESCRIPTION
            Retreive limits for BUlk actions on devices
        .EXAMPLE
            Get-WS1BulkDeviceSettings -headers (HeaderHashTable)
        
  #>
param (
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )
     $ws1BulkDeviceSettings = Invoke-WebRequest -Uri https://$($headers.ws1ApiUri)/api/mdm/devices/bulksettings -Method GET -Headers $headers
     return $ws1BulkDeviceSettings
}

###############################
###
###  INDIVIDUAL DEVICE MANAGEMENT CMDLETS
###
###############################


<# Send a QUERY or a SYNC command to a device #>
Function Find-ws1Device {
    <#
        .SYNOPSIS
            Issue a QueryAll or Sync to a device
        .DESCRIPTION
            Query or Sync
        .EXAMPLE
            Get-WS1BulkDeviceSettings -headers (HeaderHashTable)        
  #>
param (
        [Parameter(Mandatory=$true, Position=1)][string]$id,
        [Parameter(Mandatory=$true, Position=2)][ValidateSet("Query","SyncDevice")][string]$searchType,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
     )
     $ws1EnvUri = $headers.ws1ApiUri
     $ws1Find = Invoke-RestMethod -Method POST -Uri https://$ws1EnvUri/api/mdm/devices/$id/$searchType -Headers $headers
     return $ws1Find
}


Function Get-WS1Device {
    <#
        .SYNOPSIS
            Retrieve Device Details for a single device
        .DESCRIPTION
            https://as135.awmdm.com/api/help/#!/apis/10002?!/Devices/Devices_GetByAlternateIdAsync
            
        .EXAMPLE
            Get-WS1evice -searchBy {AlternateIDtype} -alternateId {uniqueIdentifier} -headers {HeaderHashTable}
        .PARAMETER searchBy
            Unique Identifier used to specify you are searching by.
            Possible values include:
                Macaddress, 2. Udid, 3. Serialnumber, 4. ImeiNumber, 5. EasId, 6. DeviceId.
        .PARAMETER alternateId
            Possible values include:
                Macaddress, 2. Udid, 3. Serialnumber, 4. ImeiNumber, 5. EasId, 6. DeviceId.
        
  #>
    param (        
        [Parameter(Mandatory=$true)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber","EasId")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true)]
        [string]$alternateId,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )
        
  
    $WS1Device = Invoke-RestMethod -Method GET -uri https://$($headers.ws1ApiUri)/api/mdm/devices?searchby=$searchBy"&"id=$alternateId -Headers $Headers
    return $WS1Device
}


Function Get-WS1BulkDevice {
<#
        .SYNOPSIS
            Retrieve Device Details in Bulk
        .DESCRIPTION
            Retrieve Device Details for more than a single device. Useful to reduce total number of API queries. This is intended for use from a script and not necessarily useful from the command line itself.
        .EXAMPLE
            Get-WS1BulkDevice -searchBy {AlternateIDtype} -bulkIdList {ARRAY OBJECT} -headers {HeaderHashTable}
        .PARAMETER awHost
            The URL to your API server. You can also use the Console URL
        .PARAMETER searchBy
            Unique Identifier used to specify which devices to delete. Possible values include : MacAddress,UDID,SerialNumber, DeviceID, IMEI
        .PARAMETER bulkIdList
            An array containing all the IDs for the Unique Identifier type you are searchign by
        
  #>
param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$searchBy,
        [Parameter(Mandatory=$true, Position=1)]
        [array]$bulkIdList,
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )

     $body = @{
                BulkValues = @{Value = @($bulkIdList)}
            }
     if ($searchBy -ne "DeviceID") {
         $WS1BulkDevices = Invoke-RestMethod -Method POST -uri https://$($headers.ws1ApiUri)/api/mdm/devices?searchby=$searchBy -body (ConvertTo-Json $body) -Headers $Headers
        }
        elseif ($searchBy -eq "DeviceID") {
            $WS1BulkDevices = Invoke-RestMethod -Method POST -uri https://$($headers.ws1ApiUri)/api/mdm/devices/id -body (ConvertTo-Json $body) -Headers $Headers
            write-host $WS1BulkDevices.Devices | format-table
        }
     return $WS1BulkDevices
}



<#
Retrieve *all* devices from an Environment

###Change Log
    2020-06-30 - Brian@BrianDeyo.us         changed $LGID to mandatory. Without the OGID large environments could be a problem since it defaults to customer OG.
    2021-04-12 - Brian@BrianDeyo.us         Updated Query string to use function
#>
Function Search-ws1Devices {
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$false, Position=0)][string]$user,
        [Parameter(mandatory=$false, Position=1)][string]$model,
        [Parameter(mandatory=$false, Position=2)][string]$platform,
        [Parameter(mandatory=$false, Position=3)][dateTime]$lastSeen,
        [Parameter(mandatory=$false, Position=4)][string]$ownership,
        [Parameter(mandatory=$true, Position=5)][int]$lgid,
        [Parameter(mandatory=$false, Position=6)][bool]$compliantStatus,
        [Parameter(mandatory=$false, Position=7)][dateTime]$seenSince,
        [Parameter(mandatory=$false, Position=8)][int]$page,
        [Parameter(mandatory=$false, Position=9)][int]$pageSize,
        [Parameter(mandatory=$false, Position=10)][string]$orderBy,
        [Parameter(mandatory=$false, Position=11)][string]$sortOrder,
        [Parameter(mandatory=$false, Position=12)][bool]$allRecords,
        [Parameter(mandatory=$true, Position=13)][hashtable]$headers
    )

    [hashtable]$stringBuild = @{}
    if (!$page) {$page=0}
    if (!$pageSize) {$pageSize=50}
    
    $parameterList= @("user","model","platform","lastSeen","ownership","lgId","compliantStatus","seenSince","page","pageSize","orderBy","sortOrder","allRecords")
    $parameterList.foreach({
        $param = Get-Variable $_ -ErrorAction SilentlyContinue
        if ($PSBoundParameters.ContainsKey($param)) {$stringBuild.Add("$($param.name)",$param.Value)}
    })   
    $searchUri = "https://$($headers.ws1ApiUri)/api/mdm/devices/search"
    $uri = New-HttpQueryString -Uri $searchUri -QueryParameter $stringBuild    
    

    switch ($PSBoundParameters['verbose']) {
        ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent -eq $true) {
            $deviceSearch = Invoke-WebRequest -method GET -Uri $uri -Headers $headers
        }
        default {
            $deviceSearch = Invoke-RestMethod -method GET -Uri $uri -Headers $headers        
        }
    }
    
    return $deviceSearch
}



<#
###  Move Devices into a different OG
#>



<##TO DO
Pipeline Id not being parsed before input... need to return Device.Id.value
#>
Function Clear-ws1Device {
    <#
    .SYNOPSIS
            Retrieve Device Details in Bulk
        .DESCRIPTION
            Retrieve Device Details for more than a single device. Useful to reduce total number of API queries. This is intended for use from a script and not necessarily useful from the command line itself.
        .EXAMPLE
            Get-WS1BulkDevice -WS1Host xx123.awmdm.com -searchBy SerialNumber -bulkIdList (ARRAY OBJECT) "Asset123" -ownership "CorporateShared" -headers (HeaderHashTable)
        .PARAMETER ws1Host
            The URL to your API server. You can also use the Console URL
        .PARAMETER searchBy
            Unique Identifier used to specify which devices to delete. Possible values include : MacAddress,UDID,SerialNumber, DeviceID, IMEI
        .PARAMETER bulkIdList
            An array containing all the IDs for the Unique Identifier type you are searchign by
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ws1Host,
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)]
        [int]$Id,
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateSet("EnterpriseWipe","DeviceWipe")]
        [string]$wipeType,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $ws1Wipe = Invoke-Restmethod -Method POST -Uri https://$ws1host/api/mdm/devices/$Id/commands?command=$wipeType -Headers $Headers
    $ws1WipeStatus = Get-WS1Device -WS1Host $ws1Host -SearchBy DeviceID -alternateId $Id -headers $headers
    return $ws1WipeStatus
}



Function Clear-ws1DeviceV2 {
     <#
    .SYNOPSIS
            EnterpriseWipe or DeviceWipe a single device.
        .DESCRIPTION
            Uses the v2 API https://censusuat.awfed.com/api/help/#!/apis/10003?!/CommandsV2/CommandsV2_ExecuteByAlternateId
        .EXAMPLE
            clear-ws1DeviceV2 -WS1Host xx123.awmdm.com -searchBy SerialNumber ABC123 -DeviceWipe -DeviceWipeType WIPE -headers (HeaderHashTable)
        .PARAMETER awHost
            The URL to your API server. You can also use the Console URL
        .PARAMETER searchBy
            Unique Identifier used to specify which devices to delete. Possible values include : MacAddress,UDID,SerialNumber, DeviceID, IMEI
        .PARAMETER bulkIdList
            An array containing all the IDs for the Unique Identifier type you are searchign by
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
            [string]$ws1Host,
        [Parameter(Mandatory=$true, Position=1)]
            [ValidateSet("Macaddress","Udid","SerialNumber","ImeiNumber","EasId")]
            [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
            [string]$Id,
        [Parameter(ParameterSetName='enterpriseWipe',Mandatory=$false, Position=3)]    
            [switch]$enterpriseWipe,
        [Parameter(ParameterSetName='deviceWipe',Mandatory=$false, Position=3)]
            [switch]$deviceWipe,
        [Parameter(ParameterSetName='deviceWipe',Mandatory=$false, Position=4)]
            [switch]$disableActivationKey,
        [Parameter(ParameterSetName='deviceWipe',Mandatory=$false, Position=5)]
            [switch]$disableProximitySetup,
        [Parameter(ParameterSetName='deviceWipe',Mandatory=$false, Position=6)]
            [switch]$preserveDataPlan,
        [Parameter(ParameterSetName='deviceWipe',Mandatory=$true, Position=7)]
            [ValidateSet("WIPE", "WIPE_PERSIST_PROVISIONED_DATA", "WIPE_PROTECTED", "WIPE_PERSIST_USER_DATA")]
            [string]$deviceWipeType,
        [Parameter(Mandatory=$false, Position=8)]
            [switch]$workPasscode,
        [Parameter(Mandatory=$false, Position=9)]
            [string]$esim_url,
        [Parameter(Mandatory=$true, Position=10)]
            [hashtable]$headers
    )

    ###Convert Headers to use v2 API
    $headers = convertTo-ws1HeaderVersion $headers -ws1APIVersion 2

    if ($deviceWipe) {
    <#{
        "deviceWipe": {
          "disableActivationKey": true,
          "disallowProximitySetup": true,
          "preserveDataPlan": true,
          "wipeType": "WIPE"
        },
        "workPasscode": true,
        "esim_url": "https://esim.vmware.com"
      }#>
        $commandsModel = @{}
        $deviceWipeModel = @{}
        if ($disableActivationKey) {$deviceWipeModel.add("disableActivationKey","true")}
        if ($disableProximitySetup) {$deviceWipeModel.add("disallowProximitySetup","true")}
        if ($preserveDataPlan) {$deviceWipeModel.add("preserveDataPlan","true")}
        
        $deviceWipeModel.add("wipeType",$deviceWipeType)
        $commandsModel.add("deviceWipe",$deviceWipeModel)

        
        $ws1Wipe = Invoke-Webrequest -method POST -URI https://$ws1host/api/mdm/devices/commands/DeviceWipe/device/$searchBy/$Id -body (convertTo-Json $commandsModel) -headers $headers
        write-host $ws1Wipe

    }

    $ws1WipeStatus = Get-WS1Device -WS1Host $ws1Host -SearchBy $searchBy -alternateId $Id -headers $headers
    return $ws1WipeStatus
}
 


<# Permanently Delete a Device
#>

Function Remove-WS1Device {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Macaddress","Udid","SerialNumber","ImeiNumber","EasId","DeviceId")]
        [string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$alternateId,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $WS1Delete = Invoke-Restmethod -Method DELETE -Uri https://$WS1host/api/mdm/devices?searchby=$searchBy"&"id=$alternateId -Headers $Headers -TimeoutSec 15
    return $WS1Delete
}


<#
    Edit Device Details - Change Asset #, Friendly Name or Ownership


    !!!! - Currently the API guide indicates SN, UDID, and Mac can be used to find device. However in practice seems to not be working: 2018-09-17
#>

Function Set-ws1Device {
    <#
        .SYNOPSIS
            Edit Device Details
        .DESCRIPTION
            Change Asset Tag, Device Friendly Name, or Ownership type for a single device.
        .EXAMPLE
            Set-ws1device -idType SerialNumber "serial1234" -assetNumber "Asset123" -ownership "CorporateShared"        
        .PARAMETER idType
            Unique Identifier used to specify which devices to edit. Possible values include : MacAddress,UDID,SerialNumber
        .PARAMETER assetNumber
            assetNumber
        .PARAMETER deviceFriendlyName
            DeviceFriendlyName
        .PARAMETER ownership
            Ownership type. Possible values includes : CorporateOwned, CorporateShared, or EmployeeOwned.
  #>
    param (
        [Parameter(Mandatory=$true, Position=0)][ValidateSet("DeviceID","Macaddress","Udid","SerialNumber")][string]$searchBy,
        [Parameter(Mandatory=$true, Position=1)][string]$alternateId,
        [Parameter(Mandatory=$false, Position=2)][string]$assetNumber,
        [Parameter(Mandatory=$false, Position=3)][string]$deviceFriendlyName,
        [Parameter(Mandatory=$false, Position=4)][ValidateSet("CorporateOwned","CorporateShared","EmployeeOwned")][string]$ownership,
        [Parameter(Mandatory=$true, Position=5,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )

    $ws1ApiUri = $headers.ws1ApiUri

    ### Creation of JSON payload
    $body = @{}
    
    if ($assetNumber -ne $null) {
        $body.Add("AssetNumber", $assetNumber)
    }
    if ($deviceFriendlyName -ne $null) {
        $body.Add("DeviceFriendlyName", $deviceFriendlyName)
    }
    if ($ownership -ne $null) {
        switch ($ownership) {
            "CorporateOwned" {$ownershipCode = "C"}
            "CorporateShared" {$ownershipCode = "S"}
            "EmployeeOwned" {$ownershipCode = "E"}
        }
        $body.Add("Ownership", $ownershipCode)
    }
    
     
    ### Different REST API URI depending on Unique Identifier used to pinpoint device
    if ($searchBy -eq "DeviceID") {
        $ws1DeviceEdit = Invoke-WebRequest -Method PUT -Uri https://$ws1ApiUri/api/mdm/devices/$alternateId -Body (ConvertTo-Json $body) -Headers $headers
    }
    else {
        $ws1DeviceEdit = Invoke-Webrequest -method PUT -URI https://$ws1ApiUri/api/mdm/devices?searchby=$searchBy"&"id=$alternateId -body (ConvertTo-Json $Body) -headers $Headers
    }
    return $ws1DeviceEdit
}


Function set-ws1deviceMangedSettings {
    <#
        .SYNOPSIS
            Short description
        .DESCRIPTION
            Long description
        .PARAMETER ws1Host
            Parameter description
        .PARAMETER idType
            Parameter description
        .PARAMETER bluetooth
            Parameter description
        .PARAMETER voiceRoamingAllowed
            Parameter description
        .PARAMETER dataRoamingAllowed
            Parameter description
        .PARAMETER personalHotspotAllowed
            Parameter description
        .PARAMETER headers
            Parameter description
        .EXAMPLE
            An example
        .NOTES
        General notes
    #>

    param (
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)][ValidateSet("DeviceID","Macaddress","Udid","ImeiNumber","SerialNumber","EasId")][string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)][string]$deviceId,
        [Parameter(Mandatory=$false, Position=2)][string][ValidateSet("on","off")]$bluetooth,
        [Parameter(Mandatory=$false, Position=3)][string][ValidateSet("on","off")]$voiceRoamingAllowed,
        [Parameter(Mandatory=$false, Position=4)][string][ValidateSet("on","off")]$dataRoamingAllowed,
        [Parameter(Mandatory=$false, Position=5)][string][ValidateSet("on","off")]$personalHotspotAllowed,
        [Parameter(Mandatory=$true, Position=6,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )
    $ws1ApiUri = $headers.ws1ApiUri
    $body = @{}
    switch ($bluetooth) {
        off {$body.add("Bluetooth", "FALSE")}
        on {$body.add("Bluetooth", "TRUE")}
    }
    switch ($voiceRoamingAllowed) {
        off {$body.add("VoiceRoamingAllowed", "FALSE")}
        on {$body.add("VoiceRoamingAllowed", "TRUE")}
    }
    switch ($dataRoamingAllowed) {
        off {$body.add("DataRoamingAllowed", "FALSE")}
        on {$body.add("DataRoamingAllowed", "TRUE")}
    }
    switch ($personalHotspotAllowed) {
        off {$body.add("PersonalHotSpotAllowed", "FALSE")}
        on {$body.add("PersonalHotSpotAllowed", "TRUE")}
    }
    

    ###Execute settings and return values
    $ws1ManagedSettings = invoke-webrequest -method POST -URI https://$ws1ApiUri/api/mdm/devices/managedsettings?searchby=$searchBy"&"id=$deviceId -body (ConvertTo-Json $Body) -headers $Headers
    return $ws1ManagedSettings
}


###############################
###
###  BULK DEVICE AND USER CMDLETS
###
###############################


<# Delete multiple devices #>
Function Remove-ws1BulkDevice {
    <#
    .SYNOPSIS
    Bulk Delete devices
    .DESCRIPTION
    Deletes multiple devices identified by device ID or alternate ID.
    .EXAMPLE
    Remove-AwBulkDevice -awHost ab123.contoso.com -SearchBy SerialNumber -headers [hashtable]$headers_in_json
    .PARAMETER awHost
    The URL to your API server. You can also use the Console URL
    .PARAMETER SearchBy
    Unique Identifier used to specify which devices to delete. Possible values include DeviceID,MacAddress,UDID,SerialNumber,ImeiNumber
    .PARAMETER bulkSnList
    Comma-separated Hashtable of Unique Identifers you want to delete. Must match type specified by SearchBy parameter
  #>
    param (        
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [Hashtable]$bulkDeviceList,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

     $body = @{
                BulkValues = @{Value = @($bulkDeviceList.Values)}
            }
    if ($SearchBy -eq "DeviceID") {
        $WS1Delete = Invoke-Restmethod -Method POST -Uri https://$($headers.ws1ApiUri)/api/mdm/devices/bulk -Headers $Headers
        }
    else {
        $WS1Delete = Invoke-Restmethod -Method POST -Uri https://$($headers.ws1ApiUri)/api/mdm/devices/bulk?searchby=$SearchBy -Body (ConvertTo-Json $body) -Headers $Headers
    }

    
        return $WS1Delete
}



###############################
###
###  MESSAGING CMDLETS
###
###############################

<# Delete multiple devices #>
Function send-WS1Message {
    <#
    .SYNOPSIS
    Send SMS/Email/Push
    .DESCRIPTION
    Send a message to a single device or in Bulk
    .EXAMPLE
    send-WS1Message -sendCount Single -searchBy DeviceID 1234 -messageType Push -message "This is a test Push message" -headers $headers
    .PARAMETER sendCount
    .PARAMETER SearchBy
    .PARAMETER deviceId
    .PARAMETER messageType
    .PARAMETER message
    .PARAMETER headers
    
    #>
    param (        
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Single","Bulk")]
        [String]$sendCount,
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=3)]
        [Hashtable]$deviceId,
        [Parameter(Mandatory=$true, Position=4)]
        [ValidateSet("SMS","Email","Push")]
        [string]$messageType,
        [Parameter(Mandatory=$true, Position=5)]
        [Hashtable]$message,
        [Parameter(Mandatory=$true, Position=6,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $body = @{
        bulkvalues = $bulkSnList
    }
    if ($sendCount -eq "Single") {
        
        $WS1send = Invoke-WebRequest -Method POST -Uri https://$WS1Host/api/mdm/devices/$deviceId/messages/push -Headers $headers
    }
    elseif ($sendCount -eq "Bulk") {
        $WS1Send = Invoke-WebRequest -Method POST -Uri https://$WS1Host/api/mdm/devices/$deviceId/messages/push -Headers $headers
    }
        return $WS1Send
}


Function move-ws1Device {
    <#.SYNOPSIS
    Move a device to a different OG
    .DESCRIPTION
    Move a device specified with a Unique Identifier to a new Organization Group.
    (Moving W10 devices if duplicate records exist in console may lead to unpredictable moves.
    Verify you are issuing a Unique Identifer for each device record.)
    
    .EXAMPLE
    move-ws1Device -WS1Host xxxxx.awmdm.com -
    .PARAMETER SearchBy
    .PARAMETER deviceId
    .PARAMETER ogId
    .PARAMETER headers
    #>
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$deviceId,
        [Parameter(Mandatory=$true, Position=3)]
        [Int]$ogId,
        [Parameter(Mandatory=$true, Position=4,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

    If ($SearchBy -ne "DeviceID") {
        $ws1DeviceMove = Invoke-WebRequest -Method POST -Uri https://$($headers.ws1ApiUri)/api/mdm/devices/commands/changeorganizationgroup?searchby=$SearchBy"&"id=$DeviceId"&"ogid=$ogid -Headers $headers
    }
    elseif ($SearchBy -eq "DeviceID") {
        $ws1DeviceMove = Invoke-WebRequest -Method PUT -Uri https://$($headers.ws1ApiUri)/api/mdm/devices/$DeviceId/commands/changeorganizationgroup/$ogID -Headers $headers   
    }
    else {
        return;
    }
    return;
}


Function get-ws1DeviceCount {
    <#.SYNOPSIS
    Retrieves Device Count Information which are Categorised by Device Info like Platform, EnrollmentStatus, Ownership etc.
    .DESCRIPTION
    Retrieves the device count for the following information.
    * Total number of devices deployed in an OG.
    * Device count breakdown by Security Info.
    * Device count breakdown by Ownership Info.
    * Device count breakdown by Platform Info.
    * Device count breakdown by EnrollmentStatus Info.
    
    .EXAMPLE
    get-ws1DeviceCount -ogId 570 -headers $headers
    .PARAMETER SearchBy
    .PARAMETER deviceId
    .PARAMETER ogId
    .PARAMETER headers
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Int]$ogId,
        [Parameter(Mandatory=$true, Position=4,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

    try {
        $ws1deviceCount = invoke-webrequest -method GET -URI https://$($headers.ws1ApiUri)//API/mdm/devices/devicecountinfo?organizationgroupid=$ogid -headers $headers
        $primaryReturn = (convertFrom-Json $ws1deviceCount.content)
        $apiStatusCode = (convertFrom-Json $ws1deviceCount.StatusCode)
    }
    catch [Exception] {
        
        $errorEvent = $error[0].ErrorDetails
        $errorEvent = (convertFrom-Json $errorEvent.message)
        $apiStatusCode = $errorEvent.errorCode
        $primaryReturn = $errorEvent.message

        #$LogEvent = New-Object psobject -Property @{UDID=$record.Udid;errorCode=$errorEvent.Status;errorMessage=$errorEvent.message;activityId=$errorEvent.HResult}
        
    }
    return $apiStatusCode, $primaryReturn    
}

Function update-ws1DeviceOutput {
    <#.SYNOPSIS
    Appends columns/attributes to device output in case of mixed device environments.
    .DESCRIPTION
    Not all devices have the same attributes populated when pulling data from API. This function will append missing columns to the device that is fed to it.
    
    .EXAMPLE
    update-ws1DeviceOutput $device
    .PARAMETER device
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [array]$device
    )
    
    if (!$device.DeviceCapacity) {$device | add-member -Name "DeviceCapacity" -MemberType NoteProperty -Value "NoSampleListed"}
    if ($device.AvailableDeviceCapacity -eq $null) {$device | add-member -Name "AvailableDeviceCapacity" -MemberType NoteProperty -Value "NoSampleListed"}
    if ($device.DataProtectionStatus -eq $null) {$device | add-member -Name "DataProtectionStatus" -MemberType NoteProperty -Value "NoSampleListed"}
    if (!$device.DeviceCellularNetworkInfo) {$device | add-member -Name "DeviceCellularNetworkInfo" -MemberType NoteProperty -Value "NoSampleListed"}
    if ($device.LastBluetoothSampleTime -eq $null) {$device | add-member -Name "LastBluetoothSampleTime" -MemberType NoteProperty -Value "NoSampleListed"}
    if ($device.ComplianceSummary -eq $null) {$device | add-member -Name "ComplianceSummary" -MemberType NoteProperty -Value "NoSampleListed"}
    if (!$device.IsRemoteManagementEnabled) {$device | add-member -Name "IsRemoteManagementEnabled" -MemberType NoteProperty -Value "NoSampleListed"}
    if (!$device.LastSystemSampleTime) {$device | add-member -Name "LastSystemSampleTime" -MemberType NoteProperty -Value "NoSampleListed"}    
    if (!$device.OSBuildVersion) {$device | add-member -Name "OSBuildVersion" -MemberType NoteProperty -Value "NoSampleListed"}    
    if ($device.HostName -eq $null) {$device | add-member -Name "HostName" -MemberType NoteProperty -Value "NoSampleListed"}    
    if ($device.LocalHostName -eq $null) {$device | add-member -Name "LocalHostName" -MemberType NoteProperty -Value "NoSampleListed"}    
    if (!$device.DeviceNetworkInfo) {$device | add-member -Name "DeviceNetworkInfo" -MemberType NoteProperty -Value "NoSampleListed"}    
    if (!$device.LastNetworkLANSampleTime) {$device | add-member -Name "LastNetworkLANSampleTime" -MemberType NoteProperty -Value "NoSampleListed"}
    return $device
}




function set-ws1DeviceNote {
    <#.SYNOPSIS
    Add a note to a device
    .DESCRIPTION
    Notes survive device wipes. This can be helpful for logging information to individual devices.
    
    .EXAMPLE
    set-ws1DeviceNote $deviceId
    .PARAMETER deviceId
    #>
    param (
     [Parameter(Mandatory=$true,Position=0)][int]$deviceId
    )
}

function set-ws1DeviceRegistration {
    <#.SYNOPSIS
    Register a device to the specified enrollment user.
    .DESCRIPTION
    This cmdlet can be used with DEP or non-DEP devices to register them in the console and generate an enrollment token.
    
    .EXAMPLE
    set-ws1DeviceRegistration
    .PARAMETER deviceId
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)][int]$userId,
        [Parameter(mandatory=$true, Position=1)][int]$locationGroupId,
        [Parameter(mandatory=$false, Position=2)][string]$friendlyName,
        [Parameter(mandatory=$false, Position=3)][string]$ownership,
        [Parameter(mandatory=$false, Position=4)][int]$platformId,
        [Parameter(mandatory=$false, Position=5)][int]$osId,
        [Parameter(mandatory=$false, Position=6)][string]$udid,
        [Parameter(mandatory=$false, Position=7)][string]$serialNumber,
        [Parameter(mandatory=$false, Position=8)][string]$imei,
        [Parameter(mandatory=$false, Position=9)][string]$assetNumber,
        [Parameter(mandatory=$false, Position=10)][int]$messageType,
        [Parameter(mandatory=$false, Position=11)][string]$messageTemplateID,
        [Parameter(mandatory=$false, Position=12)][string]$sim,
        [Parameter(mandatory=$false, Position=13)][string]$toEmailAddress,
        [Parameter(mandatory=$false, Position=14)][string]$toPhoneNumber,
        [Parameter(mandatory=$false, Position=15)][array]$tags,
        [Parameter(mandatory=$false, Position=16)][string]$customAttributes,
        [Parameter(mandatory=$false, Position=17)][bool]$isMigration,
        [Parameter(mandatory=$false, Position=18)][string]$uuid,   
        [Parameter(mandatory=$true, Position=19)][hashtable]$headers
    )

    ### Creation of JSON payload
        [hashtable]$body = @{}
        $parameterList= @("locationGroupId","friendlyName","ownership","platformId","osId","udid","serialNumber","imei","assetNumber","messageType","messageTemplateId","sim","toEmailAddress","toPhoneNumber","tags","customAttributes","isMigration","uuid")
        foreach ($param in $parameterList) {
            if ($PSBoundParameters.ContainsKey("$($param)")) {
                write-host "Key found!"
                $body.add($param,$PSCmdlet.MyInvocation.BoundParameters[$param])
                
            }
        }

    $Uri = "https://$($headers.ws1ApiUri)/api/system/users/$($userId)/registerdevice"   

    switch ($PSBoundParameters['verbose']) {
        ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent -eq $true) {
            $registration = Invoke-WebRequest -method POST -Uri $uri -body (convertTo-Json $body) -Headers $headers
        }
        default {
            $registration = Invoke-RestMethod -method POST -Uri $uri -body (convertTo-Json $body) -Headers $headers        
        }
    }
    return $registration
}