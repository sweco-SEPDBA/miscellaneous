
# $Docs = [Environment]::GetFolderPath("MyDocuments")
# $Folder = "$Docs\test\DatabasesAndWeb_Documentation\content\SwecoDbaTools-Module"
# Import-Module "$Docs\repos\Database-SwecoDbaTools\test\SwecoDbaTools.psd1"
# foreach ($cmdlet in (Get-Command -Module SwecoDBATools)) { 
#     $h = Get-Help $($cmdlet.Name)
#     $meta = @{
#         'archetype' = 'platyps';
#         'draft' = 'true';
#         'title' = $($cmdlet.Name);
#         'date' = $(Get-Date -Format yyyy-MM-dd);
#     }
#     if($h.Synopsis -notmatch "\[|\]") {
#         New-MarkdownHelp -Command $cmdlet -OutputFolder $Folder -Metadata $meta -Force
#     }
# }

$meta = @{
            'archetype' = 'platyps';
            'draft' = 'true';
            'title' = 'cmdlet_name';
            'date' = $(Get-Date -Format yyyy-MM-dd);
        }

Import-Module "$Docs\repos\Database-SwecoDbaTools\test\SwecoDbaTools.psd1"
$Docs = [Environment]::GetFolderPath("MyDocuments")
$OutputFolder = "$Docs\repos\DatabasesAndWeb_Documentation\content\SwecoDbaTools"
$parameters = @{
    'Module' = 'SwecoDbaTools'
    'OutputFolder' = "$OutputFolder"
    'AlphabeticParamsOrder' = $true
    'WithModulePage' = $true
    'ExcludeDontShow' = $true
    'Encoding' = [System.Text.Encoding]::UTF8
}
New-MarkdownHelp @parameters  -Metadata $meta -Force

# New-MarkdownAboutHelp -OutputFolder $OutputFolder -AboutName "topic_name" 
