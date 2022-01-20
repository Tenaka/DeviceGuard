<#
.Synopsis
Create Device Guard Policy and enforce
​
.Description
Device Guard has the following requirements:

Hardware Requirements

UEFI Native Mode
Windows 10/2016 x64
SLAT and Virtualization Extensions (Intel VT or AMD V)
TPM
​

Windows Features

    Windows Defender Application Guard (Isolation mode prior to 1703)

    Hyper-V Platform (Not required after 1603)

    Hyper-V Hypervisor

GPO Settings

Computer Configuration > Administrative Templates > System > Device Guard

Turn on Virtualization Based Security (enable)

Secure Boot and DMA Protection

Enable Virtualization Based Protection of Code

Deploy Code Integrity Policy (enable)

C:\DeviceGuard\SIPolicy.p7b 

(C:\DeviceGuard\SIPolicy.p7b is automatically copied and converted to C:\Windows\System32\Codeintegrity\)

From PowerShell execute Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName update -Arguments @{filepath = "C:\Windows\system32\CodeIntegrity\SIPolicy.p7b"}

The system will create SIPolicy.p7b and a reboot will enforce Device Guard

.Version
#>

#Sets Working Folder for DG
$CIPolicyPath = "C:\DeviceGuard"
New-Item $CIPolicyPath -ItemType directory -Force

#C:\DeviceGuard\InitalScan.xml 
$IntialCIPolicy = $CIPolicyPath+"\initialScan.xml"
$HashCIPolicy = $CIPolicyPath+"\HashScan.xml"
$MergedCIPolicy = $CIPolicyPath+"\Merged.xml"

#C:\DeviceGuard\SIPolicy.p7b
$CIPolicyBin = $CIPolicyPath+"\SIPolicy.p7b"

#C:\DeviceGuard\CIPolicy.txt - Output from initial policy audit
$CIPolicyTxt = $CIPolicyPath+"\CIPolicy.txt"
$HashCIPolicyTxt = $CIPolicyPath+"\HashCIPolicy.txt"


#Creates SIPolicy.p7b based on the IntialCIPolicy.xml
New-CIPolicy -Level FilePublisher -Fallback Hash -FilePath $IntialCIPolicy -UserPEs 3> $CIPolicyTxt -ScanPath C:\
New-CIPolicy -Level Hash -FilePath $HashCIPolicy -UserPEs 3> $HashCIPolicyTxt -ScanPath "C:\Windows\SystemApps\"


#Merge the 2 outputs
Merge-CIPolicy -PolicyPaths $IntialCIPolicy,$HashCIPolicy -OutputFilePath $MergedCIPolicy

#Enforces UMCI
Set-RuleOption -FilePath $MergedCIPolicy -Option 0
    
#Enforcement Mode Enabled
Set-RuleOption -FilePath $MergedCIPolicy -Option 3 -delete

#Converts the Audit to a p7b file copies to C:\DeviceGuard\
#GPO is set to move SIPolicy.p7b to C:\Windows\System32\CodeIntegrity
ConvertFrom-CIPolicy -XmlFilePath $MergedCIPolicy  -BinaryFilePath $CIPolicyBin 

#Enable DG to enforce
Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName update -Arguments @{filepath = "C:\Windows\System32\CodeIntegrity\SIPolicy.p7b"}