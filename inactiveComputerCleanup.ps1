#Remove 100 oldest inactive computer objects from the domain 
#Metric for inactivity is lastLogonTimeStamp
#LaForge
#
import-module activedirectory  
$domain = "admnet.oakland.edu"  
$DaysInactive = 365
$time = (Get-Date).Adddays(-($DaysInactive)) 
$AdminEmails = "njlaforg@oakland.edu" , "ejsteven@oakland.edu" , "mmangold@oakland.edu"
$ErrorActionPreference = "Stop"


#Prepare logs
get-date > C:\Users\utiladmin\Desktop\successLog.txt
"The following objects were deleted" >> C:\Users\utiladmin\Desktop\successLog.txt

Get-Date > C:\Users\utiladmin\Desktop\log.txt
"The following objects FAILED on attempted removal" >> C:\Users\utiladmin\Desktop\log.txt

#Complile list of COs inactive for GE $daysInactive
#Sort by descending inactive date 
$OLDComputers = (Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp, DistinguishedName  |
    select-object samAccountName,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | sort Stamp)
 
 
 #Partition list of oldest 100 objects
 #Grab assoicated object and store in $choppingBlock
 $choppingBlock = $OLDComputers | select samaccountname -First 100 | %{$_.samaccountname} | Get-ADComputer 


 #Remove objects in $choppingBlock
 #rudamentary logging 
$choppingBlock | forEach ($_){
try{
Remove-ADObject $_ -Confirm:$false 
"$_ REMOVED" >>  C:\Users\utiladmin\Desktop\successLog.txt
}
 catch{
 "The following errors occured on target object" >>  C:\Users\utiladmin\Desktop\log.txt
 $_ >> C:\Users\utiladmin\Desktop\log.txt
 }
 
 } 
 #send reports 
 Send-MailMessage -Attachments C:\Users\utiladmin\Desktop\successLog.txt, C:\Users\utiladmin\Desktop\log.txt -From njlaforg.utiladmin@oakland.edu -To $AdminEmails -SmtpServer lsmtp.oakland.edu -Subject "Computer Removal Report"