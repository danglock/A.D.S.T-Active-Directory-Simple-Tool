import-module ActiveDirectory
. .\config.ps1

[bool] $script_launched = $true



Write-Host "Loading script..." -ForegroundColor "Yellow"
$users_count = (Get-ADUser -Filter *).Count
$groups_count = (Get-ADGroup -Filter *).Count
$computers_count = (Get-ADComputer -Filter *).Count

Clear-Host

function welcome {
    Write-Host "`n     #    ######   #####  ####### "
    Write-Host "    # #   #     # #     #    #    "
    Write-Host "   #   #  #     # #          #    "
    Write-Host "  #     # #     #  #####     #    "
    Write-Host "  ####### #     #       #    #    "
    Write-Host "  #     # #     # #     #    #    "
    Write-Host "  #     # ######   #####     #    `n"
    Write-Host "- [$users_count] users loaded"
    Write-Host "- [$groups_count] groups loaded"
    Write-Host "- [$computers_count] computers loaded`n"
    Write-Host "Type " -NoNewline
    Write-Host "help " -ForegroundColor "Yellow" -NoNewline
    Write-Host "for the list of commands`n"
    

}

welcome

function help_adst {
    Write-Output "[Info commands]"
    Write-Output "==============="
    Write-Output "- help         => List all commands of the tool"
    Write-Output "- InfoUser     => Return user information from his SamAccountName"
    Write-Output "- find         => Find the SamAccountName of a user using his name or firstname"
    Write-Output "- find_dep     => Find the department of a user"
    Write-Output "- find_bydep   => List all users of a department"
    Write-Output "- get_locked   => This command returns all users whose account is locked out"

    Write-Output "`n[Utility commands]"
    Write-Output "=================="
    Write-Output "- AllUsers     => Returns all users in Active Directory"
    Write-Output "- get_password => Returns a random password"
    Write-Output "- check_sam    => Returns True if SamAccountName is already used"
    Write-Output "- powershell   => Open a PowerShell shell"

    Write-Output "`n[Import / Export]"
    Write-Output "================="
    Write-Output "- export_users => This command exports all AD users to a CSV file. The user must choose the path"
    Write-Output "- export_user  => This command exports the attributes of the chosen user"

    if ( $use_AAD -eq $true ) {
        Write-Output "`n[AAD commands]"
        Write-Output "=============="
        Write-Output "- sync      => Synchronizes AD and AAD."
    }

    Write-Output ""
    # Commandes manquantes dans le help : clear, exit
}


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




function sync {
    $session = New-PSSession -ComputerName $AAD_Server
    Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
    Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
    Remove-PSSession $session
}



while ($script_launched -eq $true) {
    
    $choix_utilisateur = Read-Host -Prompt "Enter a command "

    if  ($choix_utilisateur -ieq "help") {

        Clear-Host
        help_adst
    
    } elseif ($choix_utilisateur -ieq "clear" -Or $choix_utilisateur -ieq "cls") {

        Clear-Host
    
    } elseif ($choix_utilisateur -ieq "allusers") {

        Get-ADUSER -LDAPFilter '(!userAccountControl:1.2.840.113556.1.4.803:=2)'
    
    } elseif ($choix_utilisateur -ieq "infouser") {

        Clear-Host
        $user_to_find = Read-Host -Prompt "Enter username (SamAccountName)"
        GET-ADUSER -Identity $user_to_find -Properties c, CanonicalName, co, Department, initials, title, st, ipPhone, manager, whenChanged, whenCreated






    } elseif ( $choix_utilisateur -ieq "get_locked" ) {
        Clear-Host
        $compteur = 0

        $locked_users = @()
        Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, AccountExpirationDate, LastLogonDate | ForEach-Object {
            $compteur += 1
            $locked_users += New-Object -TypeName psobject -Property @{Id="[$compteur]"; Name=$_.Name; SamAccountName=$_.SamAccountName; AccountExpirationDate=$_.AccountExpirationDate; LastLogonDate=$_.LastLogonDate}
        }

        $locked_users | Select-Object Id, Name, SamAccountName, AccountExpirationDate, LastLogonDate| Format-Table

        Write-Host "Commands:`n- unlock <id>`n- unlock_all`n" -ForegroundColor "Yellow"

        [bool] $locked_users_menu = $true

        while ( $locked_users_menu -eq $true ) {
            $locked_user_choice = Read-Host -Prompt "Enter a command (unlocking) "

            if ( $locked_user_choice -ieq "unlock" ) {
                $user_to_unlock_id = Read-Host -Prompt "User Id "

                ForEach ( $user in $locked_users ) {

                    if ( $user.Id -eq "[$user_to_unlock_id]" ) {
                        $name = $user.Name
                        Write-Host "Trying to unlock $name" -ForegroundColor "Yellow"
                        Unlock-ADAccount -Identity $user.SamAccountName
                    }
                }

            } elseif ( $locked_user_choice -ieq "unlock_all" ) {
                ForEach ( $user in $locked_users ) {
                    Unlock-ADAccount -Identity $user.SamAccountName
                }
            } elseif ($locked_user_choice -ieq "exit") {
                Write-Host "return..." -ForegroundColor "Yellow"
                Start-Sleep -Seconds 1
                Clear-Host
                break
            }else {
                Write-Host "Unknown command" -ForegroundColor "Red"
            }
        }











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











    } elseif ($choix_utilisateur -ieq "export_users") {

        $export_path = Read-Host -Prompt "Path to export "

        if ( $export_path.EndsWith(".csv" )) {
            Write-Host "Exporting users to $export_path"
        } elseif ($export_path -ieq ""){
            Write-Host "No path selected... Exporting to .export.csv"
            $export_path = "export.csv"
        } else {
            $export_path += ".csv"
            Write-Host "Exporting users to $export_path"
        }

        Get-ADUser -Filter * -Properties * | Select-Object DisplayName, GivenName, Surname, SamAccountName, Mail, Telephonenumber, Office, Department, Title, Description | export-csv -encoding UTF8 -path $export_path -NoTypeInformation -Delimiter ";"

        Write-Host "OK" -ForegroundColor "Green"
        Start-Sleep -Seconds 1.5
        Clear-Host
        help_adst











    } elseif ( $choix_utilisateur -ieq "export_user" ) {

        $user = Read-Host -Prompt "User to export (SamAccountName) "

        $path = Read-Host -Prompt "Path to export "

        if ( $path.EndsWith(".csv" )) {
            Write-Host "Exporting users to $path"
        } elseif ($path -ieq ""){
            Write-Host "No path selected... Exporting to .export.csv"
            $path = "export.csv"
        } else {
            $path += ".csv"
            Write-Host "Exporting users to $path"
        }

        Get-ADUser -Identity $user -Properties * | export-csv -encoding UTF8 -path $path -NoTypeInformation -Delimiter ";"








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




    # CI-DESSOUS LES COMMANDES AAD :
    } elseif ($choix_utilisateur -ieq "sync") {

        if ( $use_AAD -eq $true ) {

            Clear-Host
            Write-Host "`nPushing on $AAD_Server..." -ForegroundColor "Yellow"
            sync | Format-Table

        } else {
            Write-Host "Please configure an AAD server in config file to use this command." -ForegroundColor "Red"
        }

    










    } else {

        Write-Host -ForegroundColor Red "`nUnknown command"
        Write-Host -ForegroundColor Yellow "help"
        help_adst

    }
}
