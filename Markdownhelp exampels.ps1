Update-MarkdownHelp C:\Users\sepdba_da\Documents\Repos\DatabasesAndWeb_Documentation\content\SwecoDbaTools-Module


New-ExternalHelp C:\Users\sepdba_da\Documents\Repos\DatabasesAndWeb_Documentation\content\SwecoDbaTools-Module -OutputPath en-US\

Import-Module SwecoDbaTools -Force
new-markdownhelp -Module SwecoDbaTools -OutputFolder c:\temp\docs2 
Update-MarkdownHelp -path "c:\temp\docs" -logpath "c:\temp\markdown.log"
Update-MarkdownHelpModule -path "c:\temp\docs" -logpath "c:\temp\markdown.log"

import-module .\Test\SwecoDbaTools.psd1 -force
New-MarkdownHelp -Module SwecoDbaTools -OutPutFolder C:\Users\sepdba_da\Documents\Repos\DatabasesAndWeb_Documentation\content\SwecoDbaTools-Module
