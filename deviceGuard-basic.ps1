<#
.Synopsis
Create Device Guard Policy and enforce

.Description
Device Guard has the following requirements:

https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/wdac-and-applocker-overview

Hardware Requirements

UEFI Native Mode
Windows 10/2016 x64
SLAT and Virtualization Extensions (Intel VT or AMD V)
TPM

Windows Features
    Windows Defender Application Guard (Isolation mode prior to 1703)
    Hyper-V Platform (Not required after 1603)
    Hyper-V Hypervisor
    
Set-RuleOption -FilePath $IntialCIPolicy -Option #Number
    0 Enabled:UMCI	
    1 Enabled:Boot Menu Protection	
    2 Required:WHQL	By default
    3 Enabled:Audit Mode (Default)	
    4 Disabled:Flight Signing	
    5 Enabled:Inherit Default Policy
    6 Enabled:Unsigned System Integrity Policy (Default)
    7 Allowed:Debug Policy Augmented
    8 Required:EV Signers
    9 Enabled:Advanced Boot Options Menu
    10 Enabled:Boot Audit on Failure
    11 Disabled:Script Enforcement
    12 Required:Enforce Store Applications
    13 Enabled:Managed Installer
    14 Enabled:Intelligent Security Graph Authorization	
    15 Enabled:Invalidate EAs on Reboot	
    16 Enabled:Update Policy No Reboot
    17 Enabled:Allow Supplemental Policies
    18 Disabled:Runtime FilePath Rule Protection
    19 Enabled:Dynamic Code Security

GPO Settings
Computer Configuration > Administrative Templates > System > Device Guard
    Turn on Virtualization Based Security (enable)
        Secure Boot and DMA Protection
    Enable Virtualization Based Protection of Code
        Deploy Code Integrity Policy (enable)

C:\DeviceGuard\Initial.bin 
(C:\DeviceGuard\Initial.bin is automatically copied and converted to C:\Windows\System32\Codeintegrity\)

Applies DG policy without a reboot 
From PowerShell execute Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName update -Arguments @{filepath = "C:\Windows\system32\CodeIntegrity\SIPolicy.p7b"}

.Version
#>

#Sets Working Folder for DG
$CIPolicyPath = "C:\DeviceGuard"
New-Item -Path $CIPolicyPath -ItemType Directory -Force

#C:\DeviceGuard\InitalScan.xml 
$IntialCIPolicy = $CIPolicyPath+"\initialScan.xml"

#C:\DeviceGuard\SIPolicy.p7b, set the GPO as per above instructions
$CIPolicyBin = $CIPolicyPath+"\Initial.bin"

#C:\DeviceGuard\CIPolicy.txt - Output from initial policy audit
$CIPolicyTxt = $CIPolicyPath+"\CIPolicy.txt"

#Creates SIPolicy.p7b based on the IntialCIPolicy.xml
New-CIPolicy -Level FilePublisher -Fallback Hash -FilePath $IntialCIPolicy -UserPEs 3> $CIPolicyTxt -ScanPath C:\

#Enforces UMCI
Set-RuleOption -FilePath $IntialCIPolicy -Option 0
    
#Enforcement Mode Enabled
Set-RuleOption -FilePath $IntialCIPolicy -Option 3 -delete

#Converts the Audit to a p7b file copies to C:\DeviceGuard\
#GPO is set to move SIPolicy.p7b to C:\Windows\System32\CodeIntegrity
ConvertFrom-CIPolicy -XmlFilePath $IntialCIPolicy  -BinaryFilePath $CIPolicyBin 

gpupdate /force

#Enable DG to enforce
Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName update -Arguments @{filepath = "C:\Windows\System32\CodeIntegrity\SIPolicy.p7b"}

#Now reboot 
