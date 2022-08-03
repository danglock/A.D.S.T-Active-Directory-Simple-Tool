. .\config.ps1

[bool] $script_launched = $true
############################## DECLARATION DE FONCTIONS - BEGIN
function help_adst {
    Write-Output "[Info commands]"
    Write-Output "==============="
    Write-Output "- help         => List all commands of the tool"
    Write-Output "- InfoUser     => Return user information from his SamAccountName"
    Write-Output "- find         => Find the SamAccountName of a user using his name or firstname"
    Write-Output "- find_dep     => Find the department of a user"
    Write-Output "- find_bydep   => List all users of a department"

    Write-Output "`n[Utility commands]"
    Write-Output "=================="
    Write-Output "- AllUsers     => Returns all users in Active Directory"
    Write-Output "- get_password => Returns a random password"
    Write-Output "- check_sam    => Returns True if SamAccountName is already used"
    Write-Output "- powershell   => Open a PowerShell shell"


    Write-Output "`n[AAD commands]"
    Write-Output "=============="
    Write-Output "- Bouffe!      => Synchronizes AD and AAD."

    Write-Output ""
    
}
# Exit
# PowerShell



function Test-ADUser {
    param(
      [Parameter(Mandatory = $true)]
      [String] $sAMAccountName
    )
    $null -ne ([ADSISearcher] "(sAMAccountName=$sAMAccountName)").FindOne()
  }

function New-RandomPassword {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][int]$Length,
        [Parameter(Mandatory=$false)][int]$Uppercase=1,
        [Parameter(Mandatory=$false)][int]$Digits=1,
        [Parameter(Mandatory=$false)][int]$SpecialCharacters=1
    )
    Begin {
        $Lowercase = $Length - $SpecialCharacters - $Uppercase - $Digits
        $ArrayLowerCharacters = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
        $ArrayUpperCharacters = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
        $ArraySpecialCharacters = @('_','*','$','%','#','?','!','-')
    }
    Process {
            [string]$NewPassword = $ArrayLowerCharacters | Get-Random -Count $Lowercase
            $NewPassword += 0..9 | Get-Random -Count $Digits
            $NewPassword += $ArrayUpperCharacters | Get-Random -Count $Uppercase
            $NewPassword += $ArraySpecialCharacters | Get-Random -Count $SpecialCharacters

            $NewPassword = $NewPassword.Replace(' ','')

            $characterArray = $NewPassword.ToCharArray()  
            $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length    
            $NewRandomPassword = -join $scrambledStringArray
    }
    End {
            Return $NewRandomPassword
    }
}


Function Remove-StringSpecialCharacters
{

   Param([string]$String)

   $String -replace 'é', 'e' `
           -replace 'è', 'e' `
           -replace 'ç', 'c' `
           -replace 'ë', 'e' `
           -replace 'à', 'a' `
           -replace 'ö', 'o' `
           -replace 'ô', 'o' `
           -replace 'ü', 'u' `
           -replace 'ï', 'i' `
           -replace 'î', 'i' `
           -replace 'â', 'a' `
           -replace 'ê', 'e' `
           -replace 'û', 'u' `
           -replace '-', '' `
           -replace ' ', '' `
           -replace '/', '' `
           -replace '\*', '' `
           -replace "'", "" 
}




function Bouffe! {

    Write-Host "Pushing on... $AAD_Server"

    $session = New-PSSession -ComputerName $AAD_Server
    Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
    Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
    Remove-PSSession $session
}

############################## DECLARATION DE FONCTIONS - END

help_adst


while ($script_launched -eq $true) {
    
    $choix_utilisateur = Read-Host -Prompt "Enter a command "

    if  ($choix_utilisateur -ieq "help") {

        Clear-Host
        help_adst
    
    } elseif ($choix_utilisateur -ieq "clear" -Or $choix_utilisateur -ieq "cls") {

        Clear-Host
    
    } elseif ($choix_utilisateur -ieq "Bouffe!") {

        Bouffe!
        continue

    } elseif ($choix_utilisateur -ieq "allusers") {

        Get-ADUSER -LDAPFilter '(!userAccountControl:1.2.840.113556.1.4.803:=2)'
    
    } elseif ($choix_utilisateur -ieq "infouser") {

        Clear-Host
        $user_to_find = Read-Host -Prompt "Enter username (SamAccountName)"
        GET-ADUSER -Identity $user_to_find -Properties c, CanonicalName, co, Department, initials, title, st, ipPhone, manager, whenChanged, whenCreated
    
    } elseif ($choix_utilisateur -ieq "find") {
    
        Clear-Host
        $user_tofind = Read-Host -Prompt "Firstname / Name "
        Get-AdUser -Filter "givenName -eq '$user_tofind'" -Properties SamAccountName
        Get-AdUser -Filter "Surname -eq '$user_tofind'" -Properties SamAccountName
    }
    elseif ($choix_utilisateur -ieq "get_password")
    {
        New-RandomPassword -Length 10 -Uppercase 4 -SpecialCharacters 3
    
    } elseif ($choix_utilisateur -ieq "powershell") {

        powershell.exe
        Clear-Host
        help_adst

    } elseif ($choix_utilisateur -ieq "find_dep") {

        $dep_to_find_user = Read-Host -Prompt "Entrez l'utilisateur dont vous souhaitez trouver le departement (SamAccountName)"
	    Get-ADUser -Identity $dep_to_find_user -Properties Department
    
    } elseif ($choix_utilisateur -ieq "check_sam") {

        Clear-Host
        $user_sam_tocheck = Read-Host -Prompt "SamAccountName"
        Test-ADUser -sAMAccountName $user_sam_tocheck
    
    } elseif ($choix_utilisateur -ieq "find_bydep") {

        $departement_like = Read-Host -Prompt "Quel est le departement "
        Write-Output "Recherche dans departement : $departement_like"
	    Get-ADUser -Filter 'department -like $departement_like' -Properties * | Select-Object name , UserPrincipalName,samaccountname,displayname
    
    } elseif ($choix_utilisateur -ieq "copy_user") {

        Clear-Host
        Write-Output "----------------`n Nouvel User`n----------------`n"


        $copy_from = Read-Host -Prompt "Copy from (SamAccountName)"

        Get-ADUser -Identity $copy_from -Properties * | Select-Object DisplayName, Mail, telephonenumber, Title, Department, Office | Format-List

        $user_is_correct = Read-Host -Prompt "Is the user correct [Y/n]"

        if ( $user_is_correct -ieq "y" ){

            Clear-Host
            Write-Output "----------------`n Nouvel User`n----------------`n"


            $new_employee_prenom = Read-Host -Prompt "New user Firstname "
            $new_employee_nom = Read-Host -Prompt "New user Lastname "


            $new_employee_displayname = "$new_employee_nom, $new_employee_prenom"
            

            Write-Host "`nGenerating a username..." -ForegroundColor "Yellow"
            # Generation of a SamAccountName
            $new_employee_username = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($new_employee_prenom.Substring(0,1).ToLower()+$new_employee_nom.ToLower()))

            
            ############################ VREIF SI USERNAME EXISTE DEJA

            while ($null -ne ([ADSISearcher] "(sAMAccountName=$new_employee_username)").FindOne()){
                Write-Host "The username '$new_employee_username' is already used !`n" -ForegroundColor "red"
                $new_employee_username = Read-Host -Prompt "Manually enter a username "
            }

            Write-Host "Generating a password..." -ForegroundColor "Yellow"
            $new_employee_password = New-RandomPassword -Length 10 -Uppercase 4 -SpecialCharacters 3


            Start-Sleep -Seconds 1.5
            Clear-Host
            Write-Host "===========`n| Summary |`n===========" -ForegroundColor "Yellow"

            Write-Host "`nDisplayName : $new_employee_displayname`nPrenom : $new_employee_prenom`nNom : $new_employee_nom`nUsername : $new_employee_username`nPassword : $new_employee_password`n"

            $quest_choix_correctes = Read-Host -Prompt "Est-ce correct ? [Y/n]"
                
            if ($quest_choix_correctes -ieq "Y") {
                # Creation of the user
                Write-Host "Creation of the user..." -ForegroundColor "Yellow"

                # Get copy from** attributes
                $user_template = Get-ADUser -Identity $copy_from -Properties *

                # Cre
                New-ADUser -Name $new_employee_displayname -Instance $user_template
    
            } else {
    
                Write-Host "Annulation !" -ForegroundColor "red"
                Start-Sleep -Seconds 1
                Clear-Host
                help_Adst
            }
        }   
    } elseif ($choix_utilisateur -ieq "exit") {  
        break
        
    } else {

        Write-Host -ForegroundColor Red "`nUnknown command"
        Write-Host -ForegroundColor Yellow "help"
        help_adst

    }
}
