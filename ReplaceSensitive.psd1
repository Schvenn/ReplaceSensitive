@{RootModule = 'ReplaceSensitive.psm1'
ModuleVersion = '1.0'
GUID = '5cd1df3c-5f0d-433c-badd-98bb5feade71'
Author = 'Craig Plath'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '© Craig Plath. All rights reserved.'
Description = 'A PowerShell script to replace usernames, e-mail addresses, IPv4 and IPv6 addresses in a text file for anonymization before using with web services such as LLMs.'
PowerShellVersion = '5.1'
FunctionsToExport = @('ReplaceSensitive')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @('Anon, Anonymize')
FileList = @('ReplaceSensitive.psm1')

PrivateData = @{PSData = @{Tags = @('IPv4', 'IPv6', 'LLM', 'passwords', 'random', 'usernames', 'anonymous')
LicenseUri = 'https://github.com/Schvenn/ReplaceSensitive/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/ReplaceSensitive'
ReleaseNotes = 'Initial release.'}}}
