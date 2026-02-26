$Docs = [Environment]::GetFolderPath("MyDocuments")
$Folder = "$Docs\repos\DatabasesAndWeb_Documentation\content\SwecoDbaTools-Module"
Import-Module "$Docs\repos\Database-SwecoDbaTools\test\SwecoDbaTools.psd1"
foreach ($cmdlet in (Get-Command -Module SwecoDBATools)) { 
    $h = Get-Help $($cmdlet.Name)
    $meta = @{
        'archetype' = 'platyps';
        'draft' = 'true';
        'title' = $($cmdlet.Name);
        'date' = $(Get-Date -Format yyyy-MM-dd);
    }
    if($h.Synopsis -notmatch "\[|\]") {
        New-MarkdownHelp -Command $cmdlet -OutputFolder $Folder -Metadata $meta -Force
    }
}

